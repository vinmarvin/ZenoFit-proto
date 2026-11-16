using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;
using ZenoFit.Core;
using Hand = ZenoFit.Core.Hand;

namespace ZenoFit.Platform
{
    /// <summary>
    /// Always-compiled Editor & XR Interaction Simulator implementation of IPlatformServices (01-techstack.md §3.2).
    /// Also forwards haptics and recenter events from active XRSubsystems when testing via Quest Link.
    /// </summary>
    public class EditorSimPlatform : IPlatformServices
    {
        private readonly List<XRInputSubsystem> _inputSubsystems = new List<XRInputSubsystem>();
        private bool _initialized;

        public string DeviceName => "Editor / XR Simulator";
        public bool SupportsPassthrough => false;
        public bool IsPassthroughActive { get; private set; }

        public event Action TrackingOriginRecentered;

        public void Initialize()
        {
            if (_initialized)
                return;

            _initialized = true;
            HookTrackingOriginUpdated();
        }

        public void SetPassthrough(bool enabled)
        {
            // Fallback scene / overlay handles visual state when SupportsPassthrough == false (D-06, §8.1).
            IsPassthroughActive = enabled && SupportsPassthrough;
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

        /// <summary>
        /// Allows simulating a headset recenter event in the Editor or unit tests (S-5, AT-16).
        /// </summary>
        public void SimulateRecenter()
        {
            TrackingOriginRecentered?.Invoke();
        }

        private void HookTrackingOriginUpdated()
        {
            _inputSubsystems.Clear();
            SubsystemManager.GetSubsystems(_inputSubsystems);
            for (int i = 0; i < _inputSubsystems.Count; i++)
            {
                _inputSubsystems[i].trackingOriginUpdated -= OnSubsystemTrackingOriginUpdated;
                _inputSubsystems[i].trackingOriginUpdated += OnSubsystemTrackingOriginUpdated;
            }
        }

        private void OnSubsystemTrackingOriginUpdated(XRInputSubsystem subsystem)
        {
            TrackingOriginRecentered?.Invoke();
        }
    }
}

