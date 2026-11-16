using System;
using System.Collections.Generic;
using System.Text;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.XR.Interaction.Toolkit.UI;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Exercises;

namespace ZenoFit.UI
{
    /// <summary>
    /// Accessible World-Space VR UI for ZenoFit (10-feedback-and-ui.md §9.3, §9.4).
    /// Positioned at ~1.1 m ahead, slightly below eye level, with high-contrast calm styling
    /// and large ray-interactor buttons (>= 10 cm x 5 cm at 1 m).
    /// </summary>
    public class ZenoFitWorldUI : MonoBehaviour
    {
        [SerializeField] private GameFlow _gameFlow;
        [SerializeField] private CalibrationFlow _calibrationFlow;
        [SerializeField] private GameplaySessionController _gameplayController;
        [SerializeField] private Canvas _worldCanvas;

        // Panels
        private GameObject _mainMenuPanel;
        private GameObject _calibrationPanel;
        private GameObject _exerciseSelectPanel;
        private GameObject _gameplayHudPanel;
        private GameObject _pauseOverlayPanel;
        private GameObject _resultsPanel;
        private GameObject _settingsOverlayPanel;

        // Dynamic Text elements
        private TMP_Text _headerStateText;
        private TMP_Text _mainMenuHistoryText;
        private TMP_Text _calibrationStepText;
        private Button _calibrationSkipButton;
        private TMP_Text _exerciseSelectionSummaryText;
        private TMP_Text _gameplayStatsText;
        private TMP_Text _betweenRoundRestText;
        private Button _endRestEarlyButton;
        private TMP_Text _pauseReasonText;
        private TMP_Text _resultsSummaryText;
        private TMP_Text _settingsSummaryText;

        private ExerciseType _pendingExercise = ExerciseType.ForwardArmReach;
        private DifficultyTier _pendingDifficulty = DifficultyTier.Standard;
        private HandMode _pendingHandMode = HandMode.BothHands;

        private void Start()
        {
            if (_gameFlow == null)
                _gameFlow = GameFlow.Instance != null ? GameFlow.Instance : FindFirstObjectByType<GameFlow>();
            if (_calibrationFlow == null && _gameFlow != null)
                _calibrationFlow = _gameFlow.GetComponentInChildren<CalibrationFlow>(true);
            if (_gameplayController == null && _gameFlow != null)
                _gameplayController = _gameFlow.GetComponentInChildren<GameplaySessionController>(true);

            if (_gameFlow != null && _gameFlow.Settings != null)
            {
                _pendingDifficulty = _gameFlow.Settings.difficulty;
                _pendingHandMode = _gameFlow.Settings.handMode;
            }

            BuildAccessibleWorldSpaceUI();

            EventBus.StateChanged += OnStateChanged;
            EventBus.CalibrationStepChanged += OnCalibrationStepChanged;
            EventBus.SessionPaused += OnSessionPaused;
            EventBus.ResumeCountdownTick += OnResumeCountdownTick;

            RefreshActivePanels(_gameFlow != null ? _gameFlow.StateMachine.CurrentState : AppState.MainMenu);
        }

        private void OnDestroy()
        {
            EventBus.StateChanged -= OnStateChanged;
            EventBus.CalibrationStepChanged -= OnCalibrationStepChanged;
            EventBus.SessionPaused -= OnSessionPaused;
            EventBus.ResumeCountdownTick -= OnResumeCountdownTick;
        }

        private void Update()
        {
            if (_gameFlow == null || _gameFlow.StateMachine == null)
                return;

            AppState state = _gameFlow.StateMachine.CurrentState;
            if (state == AppState.Gameplay)
            {
                UpdateGameplayHud();
            }
            else if (state == AppState.Calibration)
            {
                UpdateCalibrationButtons();
            }
        }

        private void OnStateChanged(AppState previous, AppState next)
        {
            RefreshActivePanels(next);
        }

        private void RefreshActivePanels(AppState state)
        {
            if (_mainMenuPanel == null)
                return;

            _mainMenuPanel.SetActive(state == AppState.MainMenu);
            _calibrationPanel.SetActive(state == AppState.Calibration);
            _exerciseSelectPanel.SetActive(state == AppState.ExerciseSelect);
            _gameplayHudPanel.SetActive(state == AppState.Gameplay || state == AppState.Paused);
            _pauseOverlayPanel.SetActive(state == AppState.Paused);
            _resultsPanel.SetActive(state == AppState.Results);

            if (_headerStateText != null)
            {
                _headerStateText.text = $"ZenoFit Seated VR Fitness  ·  {state}";
            }

            if (state == AppState.MainMenu)
                RefreshMainMenuHistory();
            else if (state == AppState.Calibration && _calibrationFlow?.StateMachine != null)
                OnCalibrationStepChanged((int)_calibrationFlow.StateMachine.CurrentStep, _calibrationFlow.StateMachine.GetCurrentStepInstruction());
            else if (state == AppState.ExerciseSelect)
                RefreshExerciseSelectSummary();
            else if (state == AppState.Results)
                RefreshResultsSummary();
        }

        private void OnCalibrationStepChanged(int stepIndex, string instruction)
        {
            if (_calibrationStepText != null)
            {
                _calibrationStepText.text = $"{instruction}\n\n<color=#FFD97D>{CalibrationStateMachine.PainReminderMessage}</color>";
            }
            UpdateCalibrationButtons();
        }

        private void UpdateCalibrationButtons()
        {
            if (_calibrationFlow?.StateMachine == null)
                return;

            if (_calibrationSkipButton != null)
            {
                _calibrationSkipButton.interactable = _calibrationFlow.StateMachine.CanSkipCurrentStep();
            }

            if (_calibrationFlow.StateMachine.CurrentStep == CalibrationStepId.Completed &&
                _gameFlow != null &&
                _gameFlow.StateMachine.CurrentState == AppState.Calibration)
            {
                _gameFlow.CompleteCalibrationAndSave();
            }
        }

        private void OnSessionPaused(SessionPausedEvent evt)
        {
            if (_pauseReasonText != null)
            {
                string passthroughNote = evt.RequestPassthrough
                    ? (_gameFlow.Platform.SupportsPassthrough ? "\n[Passthrough Active]" : "\n[Calm Fallback Pause View]")
                    : string.Empty;
                _pauseReasonText.text = $"<b>PAUSED ({evt.Reason})</b>\n{evt.Message}{passthroughNote}";
            }
        }

        private void OnResumeCountdownTick(float remainingSeconds)
        {
            if (_pauseReasonText != null)
            {
                _pauseReasonText.text = $"<b>Get Ready in Seated Position...</b>\nResuming in <b>{Mathf.CeilToInt(remainingSeconds)}</b>...";
            }
        }

        private void UpdateGameplayHud()
        {
            if (_gameplayStatsText == null || _gameFlow == null)
                return;

            ActiveSessionData s = _gameFlow.ActiveSession;
            _gameplayStatsText.text =
                $"<b>{s.SelectedExercise}</b> ({s.SelectedDifficulty} · {s.SelectedHandMode})\n" +
                $"Round: <b>{s.CurrentRound}/{s.TotalRounds}</b>   |   Score: <b>{s.TotalScore}</b>   |   " +
                $"Accuracy: <b>{s.AccuracyPercent:F0}%</b> ({s.Hits} hits / {s.Misses} misses)   |   " +
                $"Tempo: <b>{s.CurrentTempoBpm:F0} BPM</b>";

            bool inRest = _gameplayController != null && _gameplayController.IsInBetweenRoundRest;
            if (_betweenRoundRestText != null)
            {
                _betweenRoundRestText.gameObject.SetActive(inRest);
                if (inRest)
                {
                    _betweenRoundRestText.text =
                        $"<b>Rest Between Rounds</b>\nRelax your arms and shoulders. Next round in {_gameplayController.BetweenRoundRestRemainingSeconds:F0} s";
                }
            }
            if (_endRestEarlyButton != null)
            {
                _endRestEarlyButton.gameObject.SetActive(inRest);
            }
        }

        private void RefreshMainMenuHistory()
        {
            if (_mainMenuHistoryText == null || _gameFlow?.Persistence == null)
                return;

            List<SessionRecord> recent = _gameFlow.Persistence.LoadRecentSessions(5);
            var sb = new StringBuilder();
            sb.AppendLine("<b>Safety Notice:</b> ZenoFit is not a medical device. Stop immediately if you feel pain or discomfort.");
            sb.AppendLine();

            if (recent.Count == 0)
            {
                sb.AppendLine("<i>No recent sessions recorded yet. Press Start to calibrate and play!</i>");
            }
            else
            {
                sb.AppendLine("<b>Recent Sessions (Local JSON):</b>");
                for (int i = recent.Count - 1; i >= 0; i--)
                {
                    SessionRecord r = recent[i];
                    sb.AppendLine($"• {r.exercise} [{r.difficulty}] — Score: {r.score}, Acc: {r.accuracyPercent:F0}%, Peak: {r.maxTempoReachedBpm:F0} BPM");
                }
            }

            _mainMenuHistoryText.text = sb.ToString();
        }

        private void RefreshExerciseSelectSummary()
        {
            if (_exerciseSelectionSummaryText == null || _gameFlow == null)
                return;

            ComfortProfile p = _gameFlow.CurrentProfile;
            HandMode effectiveHand = _gameFlow.Settings.GetEffectiveHandMode(p.leftHand.enabled, p.rightHand.enabled);
            if (!p.leftHand.enabled || !p.rightHand.enabled)
                _pendingHandMode = effectiveHand;

            DifficultyPreset preset = _gameFlow.GetPreset(_pendingDifficulty);
            _exerciseSelectionSummaryText.text =
                $"Selected Exercise: <b>{_pendingExercise}</b>\n" +
                $"Difficulty: <b>{_pendingDifficulty}</b> (Reach k={preset.ReachFactorK:F2}, Radius={preset.TargetRadiusM:F2}m, Start={preset.StartTempoBpm:F0} BPM)\n" +
                $"Hand Mode: <b>{_pendingHandMode}</b> (Calibrated L={p.leftHand.reachForwardM:F2}m, R={p.rightHand.reachForwardM:F2}m)";
        }

        private void RefreshResultsSummary()
        {
            if (_resultsSummaryText == null || _gameFlow == null)
                return;

            ActiveSessionData s = _gameFlow.ActiveSession;
            _resultsSummaryText.text =
                $"<size=120%><b>Well done! Great seated session.</b></size>\n\n" +
                $"Exercise: <b>{s.SelectedExercise}</b>   |   Difficulty: <b>{s.SelectedDifficulty}</b> ({s.SelectedHandMode})\n" +
                $"Total Score: <b>{s.TotalScore}</b>\n" +
                $"Accuracy: <b>{s.AccuracyPercent:F1}%</b>  ({s.Hits} Hits / {s.Misses} Misses)\n" +
                $"Duration: <b>{s.ElapsedPlaySeconds:F1} s</b>   |   Peak Tempo: <b>{s.MaxTempoReachedBpm:F0} BPM</b>";
        }

        private void RefreshSettingsSummary()
        {
            if (_settingsSummaryText == null || _gameFlow?.Settings == null)
                return;

            AppSettings st = _gameFlow.Settings;
            _settingsSummaryText.text =
                $"<b>Settings (GP-SET-01)</b>\n" +
                $"• Haptics: {(st.hapticsEnabled ? $"ON ({st.hapticStrength01 * 100f:F0}%)" : "OFF")}\n" +
                $"• Audio Volume: {st.audioVolume01 * 100f:F0}%\n" +
                $"• Target Size Scale: {st.targetSizeMultiplier:F2}x\n" +
                $"• Rest Reminder Interval: {st.restReminderMinutes:F0} min\n" +
                $"• Boxing Touch Mode (v_solid = 0): {(st.boxingTouchMode ? "ON" : "OFF")}";
        }

        // --- Procedural World-Space Canvas Builder (§9.3) ---

        private void BuildAccessibleWorldSpaceUI()
        {
            if (_worldCanvas == null)
            {
                var canvasGo = new GameObject("ZenoFit_WorldSpaceCanvas");
                canvasGo.transform.SetParent(transform, false);
                // Placed 1.15m forward, ~1.05m high (slightly below typical seated eye level)
                canvasGo.transform.localPosition = new Vector3(0f, 1.05f, 1.15f);
                canvasGo.transform.localRotation = Quaternion.identity;
                canvasGo.transform.localScale = Vector3.one * 0.001f; // 1000 px = 1.0 metre

                _worldCanvas = canvasGo.AddComponent<Canvas>();
                _worldCanvas.renderMode = RenderMode.WorldSpace;

                var rect = canvasGo.GetComponent<RectTransform>();
                rect.sizeDelta = new Vector2(1100f, 720f);

                var scaler = canvasGo.AddComponent<CanvasScaler>();
                scaler.dynamicPixelsPerUnit = 10f;

                // TrackedDeviceGraphicRaycaster for XRI 3.x ray pointer interaction
                canvasGo.AddComponent<TrackedDeviceGraphicRaycaster>();
                canvasGo.AddComponent<GraphicRaycaster>();
            }

            RectTransform root = _worldCanvas.GetComponent<RectTransform>();

            // Calm high-contrast background card
            GameObject bg = CreatePanel(root, "BackdropCard", new Vector2(1100f, 720f), new Color(0.08f, 0.12f, 0.18f, 0.94f));
            _headerStateText = CreateLabel(bg.transform, "HeaderLabel", "ZenoFit Seated VR Fitness", new Vector2(0f, 315f), new Vector2(1020f, 50f), 28, FontStyles.Bold);

            // 1. MainMenu Panel
            _mainMenuPanel = CreatePanel(bg.transform, "MainMenuPanel", new Vector2(1020f, 600f), new Color(0, 0, 0, 0));
            _mainMenuHistoryText = CreateLabel(_mainMenuPanel.transform, "HistoryText", "", new Vector2(0f, 120f), new Vector2(960f, 260f), 22);
            CreateButton(_mainMenuPanel.transform, "StartButton", "Start Session", new Vector2(-240f, -90f), new Vector2(220f, 68f), () => _gameFlow?.ClickStartFromMainMenu());
            CreateButton(_mainMenuPanel.transform, "RecalibrateBtn", "Recalibrate", new Vector2(0f, -90f), new Vector2(220f, 68f), () => _gameFlow?.ClickRecalibrate());
            CreateButton(_mainMenuPanel.transform, "SettingsBtn", "Settings", new Vector2(240f, -90f), new Vector2(220f, 68f), () => ToggleSettingsPanel(true));
            CreateButton(_mainMenuPanel.transform, "QuitBtn", "Quit App", new Vector2(0f, -185f), new Vector2(220f, 60f), () => Application.Quit());

            // 2. Calibration Panel
            _calibrationPanel = CreatePanel(bg.transform, "CalibrationPanel", new Vector2(1020f, 600f), new Color(0, 0, 0, 0));
            _calibrationStepText = CreateLabel(_calibrationPanel.transform, "CalStepText", "Initializing Calibration...", new Vector2(0f, 110f), new Vector2(940f, 260f), 25);
            CreateButton(_calibrationPanel.transform, "ConfirmStepBtn", "Confirm Step (Trigger)", new Vector2(-260f, -110f), new Vector2(250f, 70f), () => _calibrationFlow?.ConfirmCurrentStep());
            _calibrationSkipButton = CreateButton(_calibrationPanel.transform, "SkipStepBtn", "Skip / Use Default", new Vector2(10f, -110f), new Vector2(240f, 70f), () => _calibrationFlow?.SkipOrDefaultCurrentStep());
            CreateButton(_calibrationPanel.transform, "RedoStepBtn", "Redo Previous Step", new Vector2(270f, -110f), new Vector2(240f, 70f), () => _calibrationFlow?.RedoPreviousStep());
            CreateButton(_calibrationPanel.transform, "FinishCalBtn", "Save & Continue", new Vector2(0f, -205f), new Vector2(260f, 64f), () => _gameFlow?.CompleteCalibrationAndSave());

            // 3. ExerciseSelect Panel
            _exerciseSelectPanel = CreatePanel(bg.transform, "ExerciseSelectPanel", new Vector2(1020f, 600f), new Color(0, 0, 0, 0));
            _exerciseSelectionSummaryText = CreateLabel(_exerciseSelectPanel.transform, "ExSummaryText", "", new Vector2(0f, 185f), new Vector2(960f, 130f), 22);

            // 5 Exercise buttons
            CreateButton(_exerciseSelectPanel.transform, "Ex1", "1. Forward Reach", new Vector2(-340f, 65f), new Vector2(210f, 60f), () => { _pendingExercise = ExerciseType.ForwardArmReach; RefreshExerciseSelectSummary(); });
            CreateButton(_exerciseSelectPanel.transform, "Ex2", "2. Alternating Reach", new Vector2(-110f, 65f), new Vector2(210f, 60f), () => { _pendingExercise = ExerciseType.AlternatingArmReach; RefreshExerciseSelectSummary(); });
            CreateButton(_exerciseSelectPanel.transform, "Ex3", "3. Side Arm Raise", new Vector2(120f, 65f), new Vector2(210f, 60f), () => { _pendingExercise = ExerciseType.SideArmRaise; RefreshExerciseSelectSummary(); });
            CreateButton(_exerciseSelectPanel.transform, "Ex4", "4. Forward Press", new Vector2(350f, 65f), new Vector2(210f, 60f), () => { _pendingExercise = ExerciseType.ForwardPress; RefreshExerciseSelectSummary(); });
            CreateButton(_exerciseSelectPanel.transform, "Ex5", "5. Seated Boxing", new Vector2(-340f, -10f), new Vector2(210f, 60f), () => { _pendingExercise = ExerciseType.SeatedBoxing; RefreshExerciseSelectSummary(); });

            // Difficulty & HandMode cycling buttons
            CreateButton(_exerciseSelectPanel.transform, "CycleDiffBtn", "Cycle Difficulty", new Vector2(-50f, -10f), new Vector2(240f, 60f), () =>
            {
                _pendingDifficulty = (DifficultyTier)(((int)_pendingDifficulty + 1) % 3);
                RefreshExerciseSelectSummary();
            });
            CreateButton(_exerciseSelectPanel.transform, "CycleHandBtn", "Cycle Hand Mode", new Vector2(220f, -10f), new Vector2(240f, 60f), () =>
            {
                _pendingHandMode = (HandMode)(((int)_pendingHandMode + 1) % 3);
                RefreshExerciseSelectSummary();
            });

            CreateButton(_exerciseSelectPanel.transform, "PlayBtn", "PLAY EXERCISE", new Vector2(-140f, -140f), new Vector2(260f, 75f), () => _gameFlow?.SelectExerciseAndPlay(_pendingExercise, _pendingDifficulty, _pendingHandMode));
            CreateButton(_exerciseSelectPanel.transform, "BackMenuBtn", "Back to Menu", new Vector2(160f, -140f), new Vector2(220f, 75f), () => _gameFlow?.ReturnToMainMenu());

            // 4. Gameplay HUD Panel (Docked slightly higher/compact so center reach space is clear)
            _gameplayHudPanel = CreatePanel(bg.transform, "GameplayHudPanel", new Vector2(1020f, 600f), new Color(0, 0, 0, 0));
            _gameplayStatsText = CreateLabel(_gameplayHudPanel.transform, "HudStatsText", "", new Vector2(0f, 220f), new Vector2(980f, 95f), 22);
            _betweenRoundRestText = CreateLabel(_gameplayHudPanel.transform, "RestBannerText", "", new Vector2(0f, 80f), new Vector2(880f, 100f), 24);
            _endRestEarlyButton = CreateButton(_gameplayHudPanel.transform, "EndRestEarlyBtn", "End Rest Early", new Vector2(0f, -10f), new Vector2(240f, 64f), () => _gameplayController?.EndBetweenRoundRestEarly());
            CreateButton(_gameplayHudPanel.transform, "PauseBtn", "Pause", new Vector2(-380f, -230f), new Vector2(180f, 60f), () => _gameFlow?.RequestPauseManual());
            CreateButton(_gameplayHudPanel.transform, "StopBtnHud", "STOP SESSION", new Vector2(380f, -230f), new Vector2(210f, 60f), () => _gameFlow?.RequestStopSessionToResults());

            // 5. Pause Overlay Panel (§8.2 large always-reachable Resume / Stop)
            _pauseOverlayPanel = CreatePanel(bg.transform, "PauseOverlayPanel", new Vector2(920f, 440f), new Color(0.05f, 0.08f, 0.14f, 0.97f));
            _pauseReasonText = CreateLabel(_pauseOverlayPanel.transform, "PauseReasonText", "Game Paused", new Vector2(0f, 90f), new Vector2(840f, 150f), 25);
            CreateButton(_pauseOverlayPanel.transform, "ResumeBtn", "Resume (3s Countdown)", new Vector2(-240f, -95f), new Vector2(260f, 75f), () => _gameFlow?.RequestResumeWithCountdown());
            CreateButton(_pauseOverlayPanel.transform, "RecalFromPauseBtn", "Recalibrate Seat", new Vector2(30f, -95f), new Vector2(230f, 75f), () => _gameFlow?.ClickRecalibrate());
            CreateButton(_pauseOverlayPanel.transform, "StopFromPauseBtn", "STOP SESSION", new Vector2(290f, -95f), new Vector2(230f, 75f), () => _gameFlow?.RequestStopSessionToResults());

            // 6. Results Panel (§7.3 GP-RES-01)
            _resultsPanel = CreatePanel(bg.transform, "ResultsPanel", new Vector2(1020f, 600f), new Color(0, 0, 0, 0));
            _resultsSummaryText = CreateLabel(_resultsPanel.transform, "ResultsSummaryText", "", new Vector2(0f, 95f), new Vector2(940f, 240f), 25);
            CreateButton(_resultsPanel.transform, "PlayAgainBtn", "Play Again", new Vector2(-270f, -120f), new Vector2(230f, 70f), () => _gameFlow?.SelectExerciseAndPlay(_gameFlow.ActiveSession.SelectedExercise, _gameFlow.ActiveSession.SelectedDifficulty, _gameFlow.ActiveSession.SelectedHandMode));
            CreateButton(_resultsPanel.transform, "ChangeExBtn", "Change Exercise", new Vector2(0f, -120f), new Vector2(240f, 70f), () => _gameFlow?.ReturnToExerciseSelect());
            CreateButton(_resultsPanel.transform, "MenuFromResBtn", "Main Menu", new Vector2(270f, -120f), new Vector2(230f, 70f), () => _gameFlow?.ReturnToMainMenu());

            // 7. Settings Overlay Panel (§9.4 GP-SET-01)
            _settingsOverlayPanel = CreatePanel(bg.transform, "SettingsOverlayPanel", new Vector2(960f, 540f), new Color(0.06f, 0.10f, 0.16f, 0.98f));
            _settingsSummaryText = CreateLabel(_settingsOverlayPanel.transform, "SettingsSummaryText", "", new Vector2(0f, 115f), new Vector2(880f, 200f), 22);
            CreateButton(_settingsOverlayPanel.transform, "ToggleHapticsBtn", "Toggle Haptics", new Vector2(-280f, -45f), new Vector2(230f, 60f), () =>
            {
                if (_gameFlow?.Settings == null) return;
                _gameFlow.Settings.hapticsEnabled = !_gameFlow.Settings.hapticsEnabled;
                _gameFlow.Persistence?.SaveSettings(_gameFlow.Settings);
                RefreshSettingsSummary();
            });
            CreateButton(_settingsOverlayPanel.transform, "ToggleTouchModeBtn", "Toggle Boxing Touch Mode", new Vector2(0f, -45f), new Vector2(260f, 60f), () =>
            {
                if (_gameFlow?.Settings == null) return;
                _gameFlow.Settings.boxingTouchMode = !_gameFlow.Settings.boxingTouchMode;
                _gameFlow.Persistence?.SaveSettings(_gameFlow.Settings);
                RefreshSettingsSummary();
            });
            CreateButton(_settingsOverlayPanel.transform, "CycleRestMinBtn", "Rest Timer (7-10m)", new Vector2(280f, -45f), new Vector2(230f, 60f), () =>
            {
                if (_gameFlow?.Settings == null) return;
                float next = _gameFlow.Settings.restReminderMinutes + 1f;
                if (next > 10f) next = 7f;
                _gameFlow.Settings.restReminderMinutes = next;
                _gameFlow.Persistence?.SaveSettings(_gameFlow.Settings);
                RefreshSettingsSummary();
            });
            CreateButton(_settingsOverlayPanel.transform, "DeleteDataBtn", "Delete Saved Data", new Vector2(-160f, -145f), new Vector2(240f, 60f), () =>
            {
                _gameFlow?.DeleteAllSavedDataAndReset();
                RefreshSettingsSummary();
                RefreshMainMenuHistory();
            });
            CreateButton(_settingsOverlayPanel.transform, "CloseSettingsBtn", "Close Settings", new Vector2(160f, -145f), new Vector2(240f, 60f), () => ToggleSettingsPanel(false));

            _settingsOverlayPanel.SetActive(false);
        }

        private void ToggleSettingsPanel(bool show)
        {
            if (_settingsOverlayPanel == null)
                return;
            if (show)
                RefreshSettingsSummary();
            _settingsOverlayPanel.SetActive(show);
        }

        private static GameObject CreatePanel(Transform parent, string name, Vector2 size, Color bgColor)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.sizeDelta = size;
            rt.anchoredPosition = Vector2.zero;
            var img = go.GetComponent<Image>();
            img.color = bgColor;
            return go;
        }

        private static TMP_Text CreateLabel(Transform parent, string name, string text, Vector2 anchoredPos, Vector2 size, float fontSize, FontStyles style = FontStyles.Normal)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(TextMeshProUGUI));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchoredPosition = anchoredPos;
            rt.sizeDelta = size;

            var tmp = go.GetComponent<TextMeshProUGUI>();
            tmp.text = text;
            tmp.fontSize = fontSize;
            tmp.fontStyle = style;
            tmp.color = new Color(0.95f, 0.97f, 1.0f, 1f);
            tmp.alignment = TextAlignmentOptions.Center;
            tmp.textWrappingMode = TextWrappingModes.Normal;
            return tmp;
        }

        private static Button CreateButton(Transform parent, string name, string label, Vector2 anchoredPos, Vector2 size, UnityEngine.Events.UnityAction onClick)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchoredPosition = anchoredPos;
            rt.sizeDelta = size;

            var img = go.GetComponent<Image>();
            img.color = new Color(0.16f, 0.44f, 0.72f, 1f);

            var btn = go.GetComponent<Button>();
            btn.targetGraphic = img;
            if (onClick != null)
                btn.onClick.AddListener(onClick);

            CreateLabel(go.transform, "Label", label, Vector2.zero, size - new Vector2(12f, 8f), 20, FontStyles.Bold);
            return btn;
        }
    }
}

