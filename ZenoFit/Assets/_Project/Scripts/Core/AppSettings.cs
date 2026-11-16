using System;
using UnityEngine;

namespace ZenoFit.Core
{
    /// <summary>
    /// User-configurable settings (10-feedback-and-ui.md §9.4 GP-SET-01).
    /// Persisted locally as JSON.
    /// </summary>
    [Serializable]
    public class AppSettings
    {
        public HandMode handMode = HandMode.BothHands;
        public DifficultyTier difficulty = DifficultyTier.Standard;
        public float targetSizeMultiplier = 1.0f;
        public float tempoCapBpm = 90f;
        public bool hapticsEnabled = true;
        public float hapticStrength01 = 1.0f;
        public float audioVolume01 = 0.8f;
        public float restReminderMinutes = 8.0f;
        public bool boxingTouchMode = false;
        public bool safetyNoticeAccepted = false;

        public void ClampToSafeRanges()
        {
            targetSizeMultiplier = Mathf.Clamp(targetSizeMultiplier, 0.75f, 1.50f);
            tempoCapBpm = Mathf.Clamp(tempoCapBpm, 40f, 120f);
            hapticStrength01 = Mathf.Clamp01(hapticStrength01);
            audioVolume01 = Mathf.Clamp01(audioVolume01);
            // §5.1 & §8.3: Rest reminder interval 7–10 minutes (default 8 min)
            restReminderMinutes = Mathf.Clamp(restReminderMinutes, 7.0f, 10.0f);
        }

        /// <summary>
        /// Enforces GP-CAL-03 / GP-HAND-01: if one hand is disabled in calibration,
        /// forces one-hand mode for the enabled hand.
        /// </summary>
        public HandMode GetEffectiveHandMode(bool leftHandEnabled, bool rightHandEnabled)
        {
            if (leftHandEnabled && !rightHandEnabled)
                return HandMode.LeftOnly;
            if (!leftHandEnabled && rightHandEnabled)
                return HandMode.RightOnly;
            return handMode;
        }
    }
}

