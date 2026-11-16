using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;
using ZenoFit.Core;
using Hand = ZenoFit.Core.Hand;

namespace ZenoFit.Platform.Quest
{
    /// <summary>
    /// Meta Quest standalone device implementation of IPlatformServices (Quest 2, 3, 3S).
    /// Compiled only when PLATFORM_QUEST is defined (01-techstack.md §3.1, §3.2).
    /// </summary>
    public class QuestPlatform : IPlatformServices
    {
        private readonly List<XRInputSubsystem> _inputSubsystems = new List<XRInputSubsystem>();
        private Camera _mainCamera;
        private Color _savedCameraClearColor;
        private CameraClearFlags _savedClearFlags;
        private bool _hasSavedCameraState;
        private bool _passthroughEnabled;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void RegisterWithFactory()
        {
            PlatformServicesFactory.RegisterDeviceFactory(() => new QuestPlatform());
        }

        public string DeviceName => string.IsNullOrEmpty(SystemInfo.deviceModel) ? "Meta Quest" : SystemInfo.deviceModel;

        public bool SupportsPassthrough
        {
            get
            {
#if HAS_ARFOUNDATION && HAS_META_OPENXR
                return true;
#else
                return false;
#endif
            }
        }

        public event Action TrackingOriginRecentered;

        public void Initialize()
        {
            _inputSubsystems.Clear();
            SubsystemManager.GetSubsystems(_inputSubsystems);
            for (int i = 0; i < _inputSubsystems.Count; i++)
            {
                // Enforce Device (seated / eye-level) tracking origin mode (D-05, 02-quest-config.md §2 Step 9)
                _inputSubsystems[i].TrySetTrackingOriginMode(TrackingOriginModeFlags.Device);
                _inputSubsystems[i].trackingOriginUpdated -= OnTrackingOriginUpdated;
                _inputSubsystems[i].trackingOriginUpdated += OnTrackingOriginUpdated;
            }
        }

        public void SetPassthrough(bool enabled)
        {
            if (!SupportsPassthrough)
                return;

            if (_passthroughEnabled == enabled)
                return;

            _passthroughEnabled = enabled;

            if (_mainCamera == null)
                _mainCamera = Camera.main;

            if (_mainCamera != null)
            {
                if (enabled)
                {
                    if (!_hasSavedCameraState)
                    {
                        _savedClearFlags = _mainCamera.clearFlags;
                        _savedCameraClearColor = _mainCamera.backgroundColor;
                        _hasSavedCameraState = true;
                    }
                    // OpenXR Meta Passthrough requires transparent background (alpha = 0)
                    _mainCamera.clearFlags = CameraClearFlags.SolidColor;
                    _mainCamera.backgroundColor = new Color(0f, 0f, 0f, 0f);
                }
                else if (_hasSavedCameraState)
                {
                    _mainCamera.clearFlags = _savedClearFlags;
                    _mainCamera.backgroundColor = _savedCameraClearColor;
                }
            }

            // Toggle ARCameraManager if present in scene (Unity OpenXR: Meta passthrough via AR Foundation)
            ToggleArCameraManager(enabled);
        }

        public void PlayHaptic(Hand hand, float amplitude01, float durationSeconds)
        {
            float clampedAmp = Mathf.Clamp01(amplitude01);
            float clampedDur = Mathf.Max(0f, durationSeconds);
            if (clampedAmp <= 0f || clampedDur <= 0f)
                return;

            XRNode node = hand == Hand.Left ? XRNode.LeftHand : XRNode.RightHand;
            InputDevice device = InputDevices.GetDeviceAtXRNode(node);
            if (device.isValid && device.TryGetHapticCapabilities(out HapticCapabilities caps) && caps.supportsImpulse)
            {
                device.SendHapticImpulse(0u, clampedAmp, clampedDur);
            }
        }

        private void OnTrackingOriginUpdated(XRInputSubsystem subsystem)
        {
            TrackingOriginRecentered?.Invoke();
        }

        private static void ToggleArCameraManager(bool enabled)
        {
            // Uses component type name lookup if ARCameraManager component is attached to Main Camera
            if (Camera.main == null)
                return;

            Component arCam = Camera.main.GetComponent("ARCameraManager");
            if (arCam is Behaviour behaviour)
            {
                behaviour.enabled = enabled;
            }
        }
    }
}

