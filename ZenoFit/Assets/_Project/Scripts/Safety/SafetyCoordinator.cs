using UnityEngine;
using UnityEngine.InputSystem;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Platform;
using ZenoFit.Targets;

namespace ZenoFit.Safety
{
    /// <summary>
    /// Scene glue MonoBehaviour coordinating all safety checks during Gameplay (09-safety.md §8):
    /// - §8.1 Auto-pause when hands rest in lap (2.0 s -> passthrough or fallback calm pause scene)
    /// - §8.2 Manual pause via controller Menu button (within 1 frame, AT-14)
    /// - §8.3 Rest reminder (every 8 min)
    /// - §8.4 Lateral lean / wheelchair balance monitor (|Δx| > 0.20 m for 0.5 s)
    /// - §4.4 Headset recenter handling (GP-CAL-06, AT-16)
    /// </summary>
    public class SafetyCoordinator : MonoBehaviour
    {
        [SerializeField] private SafetyConfig _config;
        [SerializeField] private Transform _headTransform;
        [SerializeField] private HandTipTracker _leftHandTip;
        [SerializeField] private HandTipTracker _rightHandTip;
        [SerializeField] private InputActionProperty _menuPauseAction;

        private AutoPauseMonitor _autoPauseMonitor;
        private LeanMonitor _leanMonitor;
        private RestReminderMonitor _restReminderMonitor;

        private GameFlowStateMachine _stateMachine;
        private ComfortProfile _comfortProfile;
        private BodyFrame _bodyFrame;
        private Vector3 _seatAnchorLocal;
        private IPlatformServices _platform;
        private bool _isBound;

        public void Initialize(
            GameFlowStateMachine stateMachine,
            ComfortProfile profile,
            BodyFrame bodyFrame,
            Vector3 seatAnchorLocal,
            IPlatformServices platform,
            float restReminderMinutes = 8.0f)
        {
            _stateMachine = stateMachine;
            _comfortProfile = profile;
            _bodyFrame = bodyFrame;
            _seatAnchorLocal = seatAnchorLocal;
            _platform = platform ?? PlatformServicesFactory.Current;

            float lapDist = _config != null ? _config.LapRestDistanceM : AutoPauseMonitor.DefaultLapDistanceThresholdM;
            float lapHold = _config != null ? _config.LapRestHoldSeconds : AutoPauseMonitor.DefaultHoldDurationSeconds;
            float leanThresh = _config != null ? _config.LateralLeanThresholdM : LeanMonitor.DefaultLeanThresholdM;
            float leanHold = _config != null ? _config.LateralLeanHoldSeconds : LeanMonitor.DefaultHoldSeconds;
            float restMins = _config != null ? _config.RestReminderIntervalMinutes : restReminderMinutes;

            _autoPauseMonitor = new AutoPauseMonitor(lapDist, lapHold);
            _leanMonitor = new LeanMonitor(leanThresh, leanHold);
            _restReminderMonitor = new RestReminderMonitor(restMins);

            if (_platform != null && !_isBound)
            {
                _platform.TrackingOriginRecentered += HandleTrackingOriginRecentered;
                _isBound = true;
            }
        }

        public void UpdateCalibrationReference(ComfortProfile profile, BodyFrame bodyFrame, Vector3 seatAnchorLocal)
        {
            _comfortProfile = profile;
            _bodyFrame = bodyFrame;
            _seatAnchorLocal = seatAnchorLocal;
            ResetMonitors();
        }

        public void ResetMonitors()
        {
            _autoPauseMonitor?.Reset();
            _leanMonitor?.Reset();
        }

        private void OnEnable()
        {
            if (_menuPauseAction.action != null)
            {
                _menuPauseAction.action.Enable();
            }
        }

        private void OnDestroy()
        {
            if (_platform != null && _isBound)
            {
                _platform.TrackingOriginRecentered -= HandleTrackingOriginRecentered;
                _isBound = false;
            }
        }

        private void Update()
        {
            if (_stateMachine == null || _stateMachine.CurrentState != AppState.Gameplay)
                return;

            // §8.2 Manual pause via controller Menu button or Escape key in Editor Simulator (AT-14: within 1 frame)
            if (IsManualPausePressedThisFrame())
            {
                TriggerManualPause();
                return;
            }

            float dt = Time.deltaTime;

            // §8.3 Rest reminder
            if (_restReminderMonitor != null && _restReminderMonitor.Tick(dt))
            {
                _stateMachine.PauseGameplay(PauseReason.RestReminder, RestReminderMonitor.RestReminderMessage, false);
                return;
            }

            if (_comfortProfile == null)
                return;

            // §8.4 Lateral lean monitor
            if (_headTransform != null && _leanMonitor != null)
            {
                Vector3 headLocal = _bodyFrame.ToLocal(_headTransform.position);
                if (_leanMonitor.Evaluate(headLocal.x, _seatAnchorLocal.x, dt))
                {
                    _leanMonitor.Reset();
                    _stateMachine.PauseGameplay(PauseReason.LeanWarning, LeanMonitor.LeanWarningMessage, false);
                    return;
                }
            }

            // §8.1 Auto-pause when hands rest in lap
            if (_autoPauseMonitor != null && (_leftHandTip != null || _rightHandTip != null))
            {
                Vector3 leftLocal = _leftHandTip != null
                    ? _bodyFrame.ToLocal(_leftHandTip.CurrentWorldPosition)
                    : Vector3.zero;
                Vector3 rightLocal = _rightHandTip != null
                    ? _bodyFrame.ToLocal(_rightHandTip.CurrentWorldPosition)
                    : Vector3.zero;

                bool leftEnabled = _comfortProfile.leftHand.enabled && _leftHandTip != null;
                bool rightEnabled = _comfortProfile.rightHand.enabled && _rightHandTip != null;

                if (_autoPauseMonitor.Evaluate(
                    leftLocal,
                    rightLocal,
                    _comfortProfile.GetLapPointLocal(),
                    dt,
                    leftEnabled,
                    rightEnabled))
                {
                    _autoPauseMonitor.Reset();
                    _platform?.SetPassthrough(true);
                    _stateMachine.PauseGameplay(
                        PauseReason.AutoPauseLap,
                        "Hands resting in lap — session paused.",
                        requestPassthrough: true);
                }
            }
        }

        public void TriggerManualPause()
        {
            if (_stateMachine == null || _stateMachine.CurrentState != AppState.Gameplay)
                return;

            _autoPauseMonitor?.Reset();
            _leanMonitor?.Reset();
            _stateMachine.PauseGameplay(PauseReason.Manual, "Game Paused", false);
        }

        public void HandleTrackingOriginRecentered()
        {
            if (_stateMachine == null)
                return;

            // GP-CAL-06 / AT-16: Pause immediately on recenter and request seat re-confirmation
            if (_stateMachine.CurrentState == AppState.Gameplay)
            {
                _stateMachine.PauseGameplay(
                    PauseReason.RecenterRequired,
                    "Headset recentered. Sit comfortably and confirm your seat position.",
                    false);
            }
        }

        private bool IsManualPausePressedThisFrame()
        {
            if (_menuPauseAction.action != null && _menuPauseAction.action.WasPressedThisFrame())
                return true;

            if (Keyboard.current != null &&
                (Keyboard.current.escapeKey.wasPressedThisFrame || Keyboard.current.pKey.wasPressedThisFrame))
                return true;

            // Also check XR left controller menu button directly via InputDevices
            UnityEngine.XR.InputDevice leftDev = UnityEngine.XR.InputDevices.GetDeviceAtXRNode(UnityEngine.XR.XRNode.LeftHand);
            if (leftDev.isValid &&
                leftDev.TryGetFeatureValue(UnityEngine.XR.CommonUsages.menuButton, out bool menuPressed) &&
                menuPressed)
            {
                return true;
            }

            return false;
        }
    }
}

