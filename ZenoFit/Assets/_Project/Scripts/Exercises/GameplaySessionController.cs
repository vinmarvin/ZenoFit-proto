using System;
using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Exercises;
using ZenoFit.Feedback;
using ZenoFit.Platform;
using ZenoFit.Scoring;
using ZenoFit.Targets;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Runs the beat clock, round loop, between-round rest, target spawning, and hit/miss evaluation
    /// during the Gameplay state (00-gameplay-overview.md §5, 02-targets-and-hit-detection.md §6).
    /// Pausing immediately freezes the beat clock without drift (01-techstack.md §4, AT-14).
    /// </summary>
    public class GameplaySessionController : MonoBehaviour
    {
        [Header("Scene References")]
        [SerializeField] private TargetSpawner _targetSpawner;
        [SerializeField] private HandTipTracker _leftHandTip;
        [SerializeField] private HandTipTracker _rightHandTip;
        [SerializeField] private AudioFeedbackController _audioFeedback;

        [Header("Exercise Config Assets (Optional - falls back to defaults)")]
        [SerializeField] private ForwardArmReachConfig _forwardReachConfig;
        [SerializeField] private AlternatingArmReachConfig _alternatingReachConfig;
        [SerializeField] private SideArmRaiseConfig _sideArmRaiseConfig;
        [SerializeField] private ForwardPressConfig _forwardPressConfig;
        [SerializeField] private SeatedBoxingConfig _seatedBoxingConfig;

        private ExerciseBase _currentExercise;
        private AdaptiveTempo _adaptiveTempo;
        private AccuracyTracker _accuracyTracker;
        private HapticFeedbackController _hapticFeedback;

        private ComfortProfile _profile;
        private BodyFrame _bodyFrame;
        private DifficultyPreset _preset;
        private AppSettings _settings;
        private ActiveSessionData _sessionData;
        private GameFlowStateMachine _flowStateMachine;

        private Target _currentTarget;
        private float _beatTimerSeconds;
        private int _targetsSpawnedInRound;
        private int _targetsResolvedInRound;
        private bool _isInBetweenRoundRest;
        private float _betweenRoundRestRemainingSeconds;
        private bool _isSessionRunning;

        public bool IsInBetweenRoundRest => _isInBetweenRoundRest;
        public float BetweenRoundRestRemainingSeconds => _betweenRoundRestRemainingSeconds;
        public AdaptiveTempo AdaptiveTempo => _adaptiveTempo;
        public AccuracyTracker AccuracyTracker => _accuracyTracker;

        public event Action OnSessionAllRoundsCompleted;

        public void ConfigureReferences(
            TargetSpawner spawner,
            HandTipTracker leftHandTip,
            HandTipTracker rightHandTip,
            AudioFeedbackController audioFeedback)
        {
            if (spawner != null) _targetSpawner = spawner;
            if (leftHandTip != null) _leftHandTip = leftHandTip;
            if (rightHandTip != null) _rightHandTip = rightHandTip;
            if (audioFeedback != null) _audioFeedback = audioFeedback;
        }

        public void StartSession(
            GameFlowStateMachine flowStateMachine,
            ActiveSessionData sessionData,
            ComfortProfile profile,
            BodyFrame bodyFrame,
            DifficultyPreset preset,
            AppSettings settings,
            IPlatformServices platform)
        {
            _flowStateMachine = flowStateMachine;
            _sessionData = sessionData;
            _profile = profile ?? ComfortProfile.CreateDefault();
            _bodyFrame = bodyFrame;
            _preset = preset ?? DifficultyPreset.CreateRuntimePreset(DifficultyTier.Standard);
            _settings = settings ?? new AppSettings();

            float startBpm = _preset.StartTempoBpm;
            float maxBpm = Mathf.Min(_preset.MaxTempoBpm, _settings.tempoCapBpm);

            // Side Arm Raise (§6.3) caps tempo at <= 60 BPM to protect shoulder loading
            if (_sessionData.SelectedExercise == ExerciseType.SideArmRaise)
            {
                float sideCap = _sideArmRaiseConfig != null ? _sideArmRaiseConfig.TempoCapBpm : 60f;
                startBpm = Mathf.Min(startBpm, sideCap);
                maxBpm = Mathf.Min(maxBpm, sideCap);
            }

            _adaptiveTempo = new AdaptiveTempo(startBpm, maxBpm);
            _accuracyTracker = new AccuracyTracker();
            _hapticFeedback = new HapticFeedbackController(platform, _settings);
            _audioFeedback?.BindSettings(_settings);

            _currentExercise = CreateExerciseInstance(_sessionData.SelectedExercise);
            _currentExercise.Initialize(_profile, _preset, _settings, _adaptiveTempo, _accuracyTracker, _hapticFeedback);

            _sessionData.ResetForNewSession(
                _sessionData.SelectedExercise,
                _preset.Tier,
                _settings.GetEffectiveHandMode(_profile.leftHand.enabled, _profile.rightHand.enabled),
                startBpm,
                _preset.RoundsPerSession);

            BeginRound(1);
            _isSessionRunning = true;
        }

        public void StopSessionCleanly()
        {
            _isSessionRunning = false;
            _isInBetweenRoundRest = false;
            if (_targetSpawner != null)
            {
                _targetSpawner.ReleaseAllActiveTargets();
            }
            _currentTarget = null;
        }

        public void UpdateBodyFrame(BodyFrame newBodyFrame)
        {
            _bodyFrame = newBodyFrame;
        }

        /// <summary>
        /// Allows the user to end the 30 s between-round rest early (§5.1).
        /// </summary>
        public void EndBetweenRoundRestEarly()
        {
            if (!_isInBetweenRoundRest)
                return;

            _isInBetweenRoundRest = false;
            BeginRound(_sessionData.CurrentRound + 1);
        }

        private void BeginRound(int roundNumber)
        {
            _sessionData.CurrentRound = roundNumber;
            _targetsSpawnedInRound = 0;
            _targetsResolvedInRound = 0;
            _beatTimerSeconds = 0.25f; // Spawn first target shortly after round begins
            _isInBetweenRoundRest = false;
            _currentExercise?.ResetRound();
            _targetSpawner?.ReleaseAllActiveTargets();
            _currentTarget = null;
        }

        private void Update()
        {
            // Freeze beat clock and target lifetimes whenever not in active Gameplay state (AT-14)
            if (!_isSessionRunning || _flowStateMachine == null || _flowStateMachine.CurrentState != AppState.Gameplay)
                return;

            float dt = Time.deltaTime;
            _sessionData.ElapsedPlaySeconds += dt;

            if (_isInBetweenRoundRest)
            {
                _betweenRoundRestRemainingSeconds -= dt;
                if (_betweenRoundRestRemainingSeconds <= 0f)
                {
                    EndBetweenRoundRestEarly();
                }
                return;
            }

            // 1. Update active target if one is out
            if (_currentTarget != null && _currentTarget.IsActiveTarget)
            {
                _currentTarget.UpdateElapsed(dt);

                // Check hits from Left and Right hand tips
                if (TryEvaluateHandsOnTarget(_currentTarget))
                {
                    return;
                }

                // Check lifetime expiry (miss)
                if (_currentTarget.ElapsedSeconds >= _currentTarget.LifetimeSeconds)
                {
                    HandleTargetMissed(_currentTarget);
                }
                return;
            }

            // 2. Check if round is finished
            if (_targetsResolvedInRound >= _preset.TargetsPerRound)
            {
                if (_sessionData.CurrentRound < _sessionData.TotalRounds)
                {
                    _isInBetweenRoundRest = true;
                    _betweenRoundRestRemainingSeconds = _preset.RestBetweenRoundsSeconds;
                }
                else
                {
                    _isSessionRunning = false;
                    _audioFeedback?.PlayCompleteChime();
                    OnSessionAllRoundsCompleted?.Invoke();
                }
                return;
            }

            // 3. Beat clock countdown for next target spawn
            _beatTimerSeconds -= dt;
            if (_beatTimerSeconds <= 0f)
            {
                SpawnNextTarget();
                _beatTimerSeconds = _adaptiveTempo.BeatIntervalSeconds;
            }
        }

        private void SpawnNextTarget()
        {
            if (_currentExercise == null || _targetSpawner == null)
                return;

            if (!_currentExercise.TryGetNextTargetSpawn(_targetsSpawnedInRound, out TargetSpawnSpec spec))
            {
                // If an obstacle blocked all angles, advance target count gracefully without penalizing user
                _targetsSpawnedInRound++;
                _targetsResolvedInRound++;
                return;
            }

            float radius = _preset.TargetRadiusM * Mathf.Clamp(_settings.targetSizeMultiplier, 0.75f, 1.50f);
            float lifetimeSeconds = ScoreCalculator.ComputeLifetimeSeconds(_preset.TargetLifetimeBeats, _adaptiveTempo.CurrentBpm);

            _currentTarget = _targetSpawner.TrySpawnTarget(
                _bodyFrame,
                _profile,
                spec.RequiredHand,
                spec.LocalPosition,
                radius,
                lifetimeSeconds,
                ComfortProfile.DefaultExclusionRadiusM,
                maxAttempts: 12,
                spec.IsElasticPress,
                spec.PressTravelDepthM);

            _targetsSpawnedInRound++;
            if (_currentTarget == null)
            {
                // Obstacle exclusion zone skipped spawn (§4.5)
                _targetsResolvedInRound++;
            }
        }

        private bool TryEvaluateHandsOnTarget(Target target)
        {
            if (_leftHandTip != null && _currentExercise.EvaluateTargetHit(
                target,
                _bodyFrame,
                Hand.Left,
                _leftHandTip.PreviousWorldPosition,
                _leftHandTip.CurrentWorldPosition,
                _leftHandTip.TipRadiusM,
                _leftHandTip.SmoothedSpeedMps,
                out bool leftSolid))
            {
                HandleTargetHit(target, Hand.Left, leftSolid);
                return true;
            }

            if (_rightHandTip != null && _currentExercise.EvaluateTargetHit(
                target,
                _bodyFrame,
                Hand.Right,
                _rightHandTip.PreviousWorldPosition,
                _rightHandTip.CurrentWorldPosition,
                _rightHandTip.TipRadiusM,
                _rightHandTip.SmoothedSpeedMps,
                out bool rightSolid))
            {
                HandleTargetHit(target, Hand.Right, rightSolid);
                return true;
            }

            return false;
        }

        private void HandleTargetHit(Target target, Hand hand, bool isSolidHit)
        {
            float hitTime = target.ElapsedSeconds;
            float lifetime = target.LifetimeSeconds;

            _accuracyTracker.RecordHit(hand, hitTime, lifetime, isSolidHit);

            if (_currentExercise.Type == ExerciseType.ForwardPress)
                _audioFeedback?.PlayClick();
            else if (isSolidHit)
                _audioFeedback?.PlaySolidHit();
            else
                _audioFeedback?.PlaySoftPop();

            if (UsesAdaptiveTempo(_currentExercise.Type))
            {
                _adaptiveTempo.RecordTargetOutcome(isHit: true);
            }

            SyncSessionStats();

            _targetSpawner.ReleaseTarget(target);
            _currentTarget = null;
            _targetsResolvedInRound++;
            _beatTimerSeconds = _adaptiveTempo.BeatIntervalSeconds;
        }

        private void HandleTargetMissed(Target target)
        {
            TargetHand expectedHand = target.RequiredHand;
            _accuracyTracker.RecordMiss(expectedHand);

            if (UsesAdaptiveTempo(_currentExercise.Type))
            {
                _adaptiveTempo.RecordTargetOutcome(isHit: false);
            }

            SyncSessionStats();

            _targetSpawner.ReleaseTarget(target);
            _currentTarget = null;
            _targetsResolvedInRound++;
            _beatTimerSeconds = _adaptiveTempo.BeatIntervalSeconds;
        }

        private void SyncSessionStats()
        {
            if (_sessionData == null)
                return;

            _sessionData.Hits = _accuracyTracker.Hits;
            _sessionData.Misses = _accuracyTracker.Misses;
            _sessionData.TotalScore = _accuracyTracker.TotalScore;
            _sessionData.CurrentTempoBpm = _adaptiveTempo.CurrentBpm;
            _sessionData.MaxTempoReachedBpm = _adaptiveTempo.MaxBpmReached;
        }

        private static bool UsesAdaptiveTempo(ExerciseType type)
        {
            // §6.4: Adaptive tempo is used by 6.1 (Forward Reach), 6.2 (Alternating Reach), 6.6 (Seated Boxing)
            return type == ExerciseType.ForwardArmReach
                || type == ExerciseType.AlternatingArmReach
                || type == ExerciseType.SeatedBoxing;
        }

        private ExerciseBase CreateExerciseInstance(ExerciseType type)
        {
            switch (type)
            {
                case ExerciseType.ForwardArmReach:
                    return new ForwardArmReachExercise(_forwardReachConfig);
                case ExerciseType.AlternatingArmReach:
                    return new AlternatingArmReachExercise(_alternatingReachConfig);
                case ExerciseType.SideArmRaise:
                    return new SideArmRaiseExercise(_sideArmRaiseConfig);
                case ExerciseType.ForwardPress:
                    return new ForwardPressExercise(_forwardPressConfig);
                case ExerciseType.SeatedBoxing:
                    return new SeatedBoxingExercise(_seatedBoxingConfig);
                default:
                    return new ForwardArmReachExercise(_forwardReachConfig);
            }
        }
    }
}

