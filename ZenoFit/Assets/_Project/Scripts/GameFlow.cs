using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Exercises;
using ZenoFit.Feedback;
using ZenoFit.Persistence;
using ZenoFit.Platform;
using ZenoFit.Safety;
using ZenoFit.Targets;

namespace ZenoFit
{
    /// <summary>
    /// Persistent root coordinator in 00_Boot (00-gameplay-overview.md §2 GP-FLOW-01, GP-FLOW-02).
    /// Manages:
    /// - GameFlowStateMachine transitions
    /// - Additive scene loading over 00_Boot (when additive scenes are present in Build Settings)
    /// - 3-second Resume countdown (GP-FLOW-02)
    /// - Recenter seat re-confirmation (GP-CAL-06, AT-16)
    /// - Local JSON persistence of CalibrationProfile, SessionHistory, and AppSettings
    /// </summary>
    public class GameFlow : MonoBehaviour
    {
        public static GameFlow Instance { get; private set; }

        [Header("Core References")]
        [SerializeField] private Transform _headTransform;
        [SerializeField] private HandTipTracker _leftHandTip;
        [SerializeField] private HandTipTracker _rightHandTip;
        [SerializeField] private CalibrationFlow _calibrationFlow;
        [SerializeField] private GameplaySessionController _gameplayController;
        [SerializeField] private SafetyCoordinator _safetyCoordinator;
        [SerializeField] private TargetSpawner _targetSpawner;
        [SerializeField] private AudioFeedbackController _audioFeedback;

        [Header("Presets & Configs")]
        [SerializeField] private DifficultyPreset _gentlePreset;
        [SerializeField] private DifficultyPreset _standardPreset;
        [SerializeField] private DifficultyPreset _activePreset;
        [SerializeField] private float _resumeCountdownSeconds = 3.0f;

        [Header("Additive Scene Names (§3)")]
        [SerializeField] private bool _useAdditiveScenes = true;
        [SerializeField] private string _mainMenuScene = "01_MainMenu";
        [SerializeField] private string _calibrationScene = "02_Calibration";
        [SerializeField] private string _exerciseSelectScene = "03_ExerciseSelect";
        [SerializeField] private string _gameplayScene = "04_Gameplay";
        [SerializeField] private string _resultsScene = "05_Results";

        private string _currentlyLoadedSubScene;
        private Coroutine _resumeCountdownCoroutine;

        public GameFlowStateMachine StateMachine { get; private set; }
        public JsonPersistenceService Persistence { get; private set; }
        public IPlatformServices Platform { get; private set; }
        public AppSettings Settings { get; private set; }
        public ComfortProfile CurrentProfile { get; private set; }
        public bool HasValidCalibration { get; private set; }
        public BodyFrame CurrentBodyFrame { get; private set; }
        public Vector3 SeatAnchorLocal { get; private set; }
        public ActiveSessionData ActiveSession { get; private set; } = new ActiveSessionData();
        public bool IsResumeCountingDown { get; private set; }
        public float ResumeCountdownRemaining { get; private set; }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;

            InitializeCoreServices();
        }

        private void Start()
        {
            // Boot → MainMenu transition (§2)
            StateMachine.OnBootComplete();
        }

#if UNITY_EDITOR
        private float _editorLeftDepthOffset = 0.45f;
        private float _editorRightDepthOffset = 0.45f;

        private void Update()
        {
            if (Keyboard.current == null)
                return;

            // Editor shortcut: Hold Q (Left Hand) or E (Right Hand) + move mouse in Game View to move hands without VR headset
            if (Mouse.current != null && Camera.main != null)
            {
                float scrollDelta = Mouse.current.scroll.ReadValue().y * 0.001f;
                Vector2 mousePos = Mouse.current.position.ReadValue();

                if (Keyboard.current.qKey.isPressed && _leftHandTip != null)
                {
                    _editorLeftDepthOffset = Mathf.Clamp(_editorLeftDepthOffset + scrollDelta, 0.15f, 0.85f);
                    Vector3 worldPos = Camera.main.ScreenToWorldPoint(new Vector3(mousePos.x, mousePos.y, _editorLeftDepthOffset));
                    Transform moveTransform = _leftHandTip.transform.parent != null ? _leftHandTip.transform.parent : _leftHandTip.transform;
                    moveTransform.position = worldPos;
                }

                if (Keyboard.current.eKey.isPressed && _rightHandTip != null)
                {
                    _editorRightDepthOffset = Mathf.Clamp(_editorRightDepthOffset + scrollDelta, 0.15f, 0.85f);
                    Vector3 worldPos = Camera.main.ScreenToWorldPoint(new Vector3(mousePos.x, mousePos.y, _editorRightDepthOffset));
                    Transform moveTransform = _rightHandTip.transform.parent != null ? _rightHandTip.transform.parent : _rightHandTip.transform;
                    moveTransform.position = worldPos;
                }
            }

            if (StateMachine != null && StateMachine.CurrentState == AppState.Gameplay)
            {
                // Editor shortcut: Press Tab to auto-reach/hit the first active target
                if (Keyboard.current.tabKey.wasPressedThisFrame && _targetSpawner != null && _targetSpawner.ActiveTargets.Count > 0)
                {
                    Target target = _targetSpawner.ActiveTargets[0];
                    if (target != null)
                    {
                        bool useLeft = target.RequiredHand == TargetHand.Left ||
                                       (target.RequiredHand == TargetHand.Either && Settings.handMode == HandMode.LeftOnly);
                        HandTipTracker hand = useLeft ? _leftHandTip : _rightHandTip;
                        if (hand != null)
                        {
                            StartCoroutine(EditorAutoHitTargetRoutine(hand, target));
                        }
                    }
                }

                // Editor shortcut: Press L to rest both hands in lap (tests S-2 Auto-Pause after 2 seconds)
                if (Keyboard.current.lKey.wasPressedThisFrame && CurrentProfile != null)
                {
                    Vector3 lapWorld = CurrentBodyFrame.ToWorld(CurrentProfile.GetLapPointLocal());
                    if (_leftHandTip != null)
                        _leftHandTip.transform.position = lapWorld;
                    if (_rightHandTip != null)
                        _rightHandTip.transform.position = lapWorld;
                }

                // Editor shortcut: Press R to simulate a headset recenter event (tests S-5 Recenter Pause)
                if (Keyboard.current.rKey.wasPressedThisFrame && Platform is EditorSimPlatform editorSim)
                {
                    editorSim.SimulateRecenter();
                }
            }
        }

        private IEnumerator EditorAutoHitTargetRoutine(HandTipTracker hand, Target target)
        {
            if (hand == null || target == null)
                yield break;

            Transform moveTransform = hand.transform.parent != null ? hand.transform.parent : hand.transform;
            Vector3 fwd = CurrentBodyFrame.Yaw * Vector3.forward;
            Vector3 targetPos = target.BaseWorldPosition;
            Vector3 startPos = targetPos - fwd * 0.20f;
            Vector3 endPos = targetPos + fwd * 0.05f;

            // Move rapidly across target over 3 frames (> 0.30 m/s for Seated Boxing & >= 0.03 m depth for Forward Press)
            moveTransform.position = startPos;
            hand.transform.localPosition = Vector3.zero;
            yield return null;

            moveTransform.position = Vector3.Lerp(startPos, endPos, 0.5f);
            yield return null;

            moveTransform.position = endPos;
            yield return new WaitForSeconds(0.08f);

            // Return behind release threshold
            moveTransform.position = startPos;
        }
#endif

        private void InitializeCoreServices()
        {
            Platform = PlatformServicesFactory.Current;
            Platform.Initialize();

            Persistence = new JsonPersistenceService();
            Settings = Persistence.LoadSettings();

            if (Persistence.TryLoadCalibrationProfile(out ComfortProfile savedProfile))
            {
                CurrentProfile = savedProfile;
                HasValidCalibration = true;
            }
            else
            {
                CurrentProfile = ComfortProfile.CreateDefault();
                HasValidCalibration = false;
            }

            EnsureComponentReferences();
            RebuildBodyFrameFromCurrentPose();

            StateMachine = new GameFlowStateMachine();
            StateMachine.OnStateTransition += HandleStateTransition;

            if (_gameplayController != null)
            {
                _gameplayController.OnSessionAllRoundsCompleted += HandleAllRoundsCompleted;
            }

            if (_safetyCoordinator != null)
            {
                _safetyCoordinator.Initialize(
                    StateMachine,
                    CurrentProfile,
                    CurrentBodyFrame,
                    SeatAnchorLocal,
                    Platform,
                    Settings.restReminderMinutes);
            }
        }

        private void EnsureComponentReferences()
        {
            if (_headTransform == null && Camera.main != null)
                _headTransform = Camera.main.transform;

            if (_targetSpawner == null)
                _targetSpawner = GetComponentInChildren<TargetSpawner>(true);
            if (_targetSpawner == null)
            {
                var spawnerGo = new GameObject("TargetSpawner");
                spawnerGo.transform.SetParent(transform, false);
                _targetSpawner = spawnerGo.AddComponent<TargetSpawner>();
            }

            if (_audioFeedback == null)
                _audioFeedback = GetComponentInChildren<AudioFeedbackController>(true);
            if (_audioFeedback == null)
            {
                var audioGo = new GameObject("AudioFeedback");
                audioGo.transform.SetParent(transform, false);
                _audioFeedback = audioGo.AddComponent<AudioSource>() != null
                    ? audioGo.AddComponent<AudioFeedbackController>()
                    : null;
            }

            if (_calibrationFlow == null)
                _calibrationFlow = GetComponentInChildren<CalibrationFlow>(true);
            if (_calibrationFlow == null)
            {
                var calGo = new GameObject("CalibrationFlow");
                calGo.transform.SetParent(transform, false);
                _calibrationFlow = calGo.AddComponent<CalibrationFlow>();
            }

            if (_gameplayController == null)
                _gameplayController = GetComponentInChildren<GameplaySessionController>(true);
            if (_gameplayController == null)
            {
                var gpGo = new GameObject("GameplaySessionController");
                gpGo.transform.SetParent(transform, false);
                _gameplayController = gpGo.AddComponent<GameplaySessionController>();
            }

            if (_safetyCoordinator == null)
                _safetyCoordinator = GetComponentInChildren<SafetyCoordinator>(true);
            if (_safetyCoordinator == null)
            {
                var safeGo = new GameObject("SafetyCoordinator");
                safeGo.transform.SetParent(transform, false);
                _safetyCoordinator = safeGo.AddComponent<SafetyCoordinator>();
            }

            _gameplayController.ConfigureReferences(_targetSpawner, _leftHandTip, _rightHandTip, _audioFeedback);
            _calibrationFlow.Initialize(CurrentProfile, _headTransform, _leftHandTip, _rightHandTip);
        }

        public void RebuildBodyFrameFromCurrentPose()
        {
            Vector3 headPos = _headTransform != null ? _headTransform.position : new Vector3(0f, 1.20f, 0f);
            Vector3 headFwd = _headTransform != null ? _headTransform.forward : Vector3.forward;

            CurrentBodyFrame = BodyFrame.RebuildFromHeadAndSavedOffset(
                headPos,
                headFwd,
                CurrentProfile.GetChestOffsetFromHead());
            SeatAnchorLocal = CurrentBodyFrame.ToLocal(headPos);

            _gameplayController?.UpdateBodyFrame(CurrentBodyFrame);
            _safetyCoordinator?.UpdateCalibrationReference(CurrentProfile, CurrentBodyFrame, SeatAnchorLocal);
        }

        public DifficultyPreset GetPreset(DifficultyTier tier)
        {
            switch (tier)
            {
                case DifficultyTier.Gentle:
                    if (_gentlePreset == null)
                        _gentlePreset = DifficultyPreset.CreateRuntimePreset(DifficultyTier.Gentle);
                    return _gentlePreset;
                case DifficultyTier.Active:
                    if (_activePreset == null)
                        _activePreset = DifficultyPreset.CreateRuntimePreset(DifficultyTier.Active);
                    return _activePreset;
                case DifficultyTier.Standard:
                default:
                    if (_standardPreset == null)
                        _standardPreset = DifficultyPreset.CreateRuntimePreset(DifficultyTier.Standard);
                    return _standardPreset;
            }
        }

        // --- UI / Flow Commands ---

        public void ClickStartFromMainMenu()
        {
            StateMachine.OnStartFromMainMenu(HasValidCalibration);
        }

        public void ClickRecalibrate()
        {
            if (StateMachine.CurrentState == AppState.MainMenu ||
                StateMachine.CurrentState == AppState.ExerciseSelect ||
                StateMachine.CurrentState == AppState.Paused)
            {
                _gameplayController?.StopSessionCleanly();
                Platform?.SetPassthrough(false);
                StateMachine.OnRecalibrateRequested();
            }
        }

        public void CompleteCalibrationAndSave()
        {
            if (_calibrationFlow != null && _calibrationFlow.StateMachine != null)
            {
                CurrentProfile = _calibrationFlow.StateMachine.WorkingProfile;
                CurrentBodyFrame = _calibrationFlow.StateMachine.CurrentBodyFrame;
                SeatAnchorLocal = _calibrationFlow.StateMachine.SeatAnchorLocal;
            }

            // GP-CAL-03: Enforce one-hand mode if a hand was skipped/disabled
            Settings.handMode = Settings.GetEffectiveHandMode(CurrentProfile.leftHand.enabled, CurrentProfile.rightHand.enabled);
            Persistence.SaveCalibrationProfile(CurrentProfile);
            Persistence.SaveSettings(Settings);
            HasValidCalibration = true;

            _safetyCoordinator?.UpdateCalibrationReference(CurrentProfile, CurrentBodyFrame, SeatAnchorLocal);
            StateMachine.OnCalibrationCompleted();
        }

        public void SelectExerciseAndPlay(ExerciseType exercise, DifficultyTier difficulty, HandMode handMode)
        {
            Settings.difficulty = difficulty;
            Settings.handMode = Settings.GetEffectiveHandMode(CurrentProfile.leftHand.enabled, CurrentProfile.rightHand.enabled);
            if (CurrentProfile.leftHand.enabled && CurrentProfile.rightHand.enabled)
            {
                Settings.handMode = handMode;
            }
            Persistence.SaveSettings(Settings);

            ActiveSession.SelectedExercise = exercise;
            ActiveSession.SelectedDifficulty = difficulty;
            ActiveSession.SelectedHandMode = Settings.handMode;

            if (StateMachine.CurrentState == AppState.Results)
            {
                StateMachine.TryTransitionTo(AppState.Gameplay);
            }
            else
            {
                StateMachine.OnPlayExercise();
            }
        }

        public void RequestPauseManual()
        {
            _safetyCoordinator?.TriggerManualPause();
        }

        /// <summary>
        /// GP-FLOW-02: Resume includes a short countdown (3 s) so the user can get back into position.
        /// </summary>
        public void RequestResumeWithCountdown()
        {
            if (StateMachine.CurrentState != AppState.Paused || IsResumeCountingDown)
                return;

            // If paused due to headset recenter (GP-CAL-06), re-derive BodyFrame from current seated pose first
            if (StateMachine.CurrentPauseReason == PauseReason.RecenterRequired)
            {
                RebuildBodyFrameFromCurrentPose();
            }

            Platform?.SetPassthrough(false);

            if (_resumeCountdownCoroutine != null)
                StopCoroutine(_resumeCountdownCoroutine);
            _resumeCountdownCoroutine = StartCoroutine(ResumeCountdownRoutine());
        }

        private IEnumerator ResumeCountdownRoutine()
        {
            IsResumeCountingDown = true;
            ResumeCountdownRemaining = Mathf.Max(0.5f, _resumeCountdownSeconds);

            while (ResumeCountdownRemaining > 0f && StateMachine.CurrentState == AppState.Paused)
            {
                EventBus.PublishResumeCountdownTick(ResumeCountdownRemaining);
                yield return null;
                ResumeCountdownRemaining -= Time.unscaledDeltaTime;
            }

            IsResumeCountingDown = false;
            ResumeCountdownRemaining = 0f;

            if (StateMachine.CurrentState == AppState.Paused)
            {
                _safetyCoordinator?.ResetMonitors();
                StateMachine.ResumeGameplay();
            }
        }

        public void RequestStopSessionToResults()
        {
            if (_resumeCountdownCoroutine != null)
            {
                StopCoroutine(_resumeCountdownCoroutine);
                _resumeCountdownCoroutine = null;
            }
            IsResumeCountingDown = false;

            Platform?.SetPassthrough(false);
            _gameplayController?.StopSessionCleanly();
            SaveCompletedSessionRecord();
            StateMachine.FinishOrStopGameplay();
        }

        public void ReturnToMainMenu()
        {
            Platform?.SetPassthrough(false);
            _gameplayController?.StopSessionCleanly();
            StateMachine.TryTransitionTo(AppState.MainMenu);
        }

        public void ReturnToExerciseSelect()
        {
            Platform?.SetPassthrough(false);
            _gameplayController?.StopSessionCleanly();
            StateMachine.TryTransitionTo(AppState.ExerciseSelect);
        }

        public void DeleteAllSavedDataAndReset()
        {
            Persistence.DeleteAllSavedData();
            Settings = new AppSettings();
            CurrentProfile = ComfortProfile.CreateDefault();
            HasValidCalibration = false;
        }

        private void HandleAllRoundsCompleted()
        {
            SaveCompletedSessionRecord();
            StateMachine.FinishOrStopGameplay();
        }

        private void SaveCompletedSessionRecord()
        {
            if (ActiveSession.TotalTargetsAttempted > 0 || ActiveSession.ElapsedPlaySeconds > 1f)
            {
                Persistence.AppendSessionRecord(ActiveSession.ToRecord(), maxHistoryCount: 50);
            }
        }

        private void HandleStateTransition(AppState previous, AppState next)
        {
            switch (next)
            {
                case AppState.MainMenu:
                    LoadAdditiveSubSceneIfAvailable(_mainMenuScene);
                    break;

                case AppState.Calibration:
                    LoadAdditiveSubSceneIfAvailable(_calibrationScene);
                    _calibrationFlow.Initialize(CurrentProfile, _headTransform, _leftHandTip, _rightHandTip);
                    _calibrationFlow.BeginFullCalibration();
                    break;

                case AppState.ExerciseSelect:
                    LoadAdditiveSubSceneIfAvailable(_exerciseSelectScene);
                    break;

                case AppState.Gameplay:
                    LoadAdditiveSubSceneIfAvailable(_gameplayScene);
                    if (previous != AppState.Paused)
                    {
                        RebuildBodyFrameFromCurrentPose();
                        DifficultyPreset preset = GetPreset(ActiveSession.SelectedDifficulty);
                        _gameplayController.StartSession(
                            StateMachine,
                            ActiveSession,
                            CurrentProfile,
                            CurrentBodyFrame,
                            preset,
                            Settings,
                            Platform);
                    }
                    break;

                case AppState.Paused:
                    break;

                case AppState.Results:
                    LoadAdditiveSubSceneIfAvailable(_resultsScene);
                    break;
            }
        }

        private void LoadAdditiveSubSceneIfAvailable(string targetSceneName)
        {
            if (!_useAdditiveScenes || string.IsNullOrEmpty(targetSceneName))
                return;

            if (_currentlyLoadedSubScene == targetSceneName)
                return;

            if (!Application.CanStreamedLevelBeLoaded(targetSceneName))
                return;

            if (!string.IsNullOrEmpty(_currentlyLoadedSubScene))
            {
                Scene oldScene = SceneManager.GetSceneByName(_currentlyLoadedSubScene);
                if (oldScene.IsValid() && oldScene.isLoaded)
                {
                    SceneManager.UnloadSceneAsync(oldScene);
                }
            }

            Scene newScene = SceneManager.GetSceneByName(targetSceneName);
            if (!newScene.IsValid() || !newScene.isLoaded)
            {
                SceneManager.LoadSceneAsync(targetSceneName, LoadSceneMode.Additive);
            }
            _currentlyLoadedSubScene = targetSceneName;
        }
    }
}

