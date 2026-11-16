using UnityEngine;
using ZenoFit.Core;
using ZenoFit.Platform;

namespace ZenoFit.Feedback
{
    /// <summary>
    /// Haptic impulse dispatcher via IPlatformServices (10-feedback-and-ui.md §9.1 GP-HAPTIC-01).
    /// Respects user haptics on/off and intensity settings.
    /// </summary>
    public class HapticFeedbackController
    {
        // §9.1 Haptic profile constants [P] / [S]
        public const float ReachHitAmplitude = 0.25f;
        public const float ReachHitDurationSeconds = 0.030f;

        public const float ForwardPressClickAmplitude = 0.40f;
        public const float ForwardPressClickDurationSeconds = 0.050f; // 50 ms [S]

        public const float SolidBoxingHitAmplitude = 0.70f;
        public const float SolidBoxingHitDurationSeconds = 0.080f;

        public const float LightBoxingHitAmplitude = 0.20f;
        public const float LightBoxingHitDurationSeconds = 0.030f;

        private readonly IPlatformServices _platform;
        private readonly AppSettings _settings;

        public HapticFeedbackController(IPlatformServices platform, AppSettings settings)
        {
            _platform = platform ?? PlatformServicesFactory.Current;
            _settings = settings ?? new AppSettings();
        }

        public void PlayReachHit(Hand hand)
        {
            Play(hand, ReachHitAmplitude, ReachHitDurationSeconds);
        }

        public void PlayForwardPressClick(Hand hand)
        {
            Play(hand, ForwardPressClickAmplitude, ForwardPressClickDurationSeconds);
        }

        public void PlayBoxingHit(Hand hand, bool isSolidHit)
        {
            if (isSolidHit)
                Play(hand, SolidBoxingHitAmplitude, SolidBoxingHitDurationSeconds);
            else
                Play(hand, LightBoxingHitAmplitude, LightBoxingHitDurationSeconds);
        }

        public void Play(Hand hand, float baseAmplitude01, float durationSeconds)
        {
            if (_platform == null || _settings == null || !_settings.hapticsEnabled)
                return;

            float scaledAmplitude = Mathf.Clamp01(baseAmplitude01 * _settings.hapticStrength01);
            if (scaledAmplitude <= 0.001f)
                return;

            _platform.PlayHaptic(hand, scaledAmplitude, durationSeconds);
        }
    }
}

