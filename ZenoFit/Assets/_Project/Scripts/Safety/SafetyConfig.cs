using UnityEngine;

namespace ZenoFit.Safety
{
    /// <summary>
    /// Tunable parameters for the Safety System (09-safety.md Tunables).
    /// </summary>
    [CreateAssetMenu(fileName = "SafetyConfig", menuName = "ZenoFit/Safety Config", order = 3)]
    public class SafetyConfig : ScriptableObject
    {
        [Header("Auto-Pause Hands in Lap (§8.1)")]
        [Tooltip("Maximum distance from calibrated LapPoint to count as resting in lap [P: 0.15 m].")]
        [Range(0.05f, 0.35f)]
        [SerializeField] private float _lapRestDistanceM = 0.15f;

        [Tooltip("Continuous hold duration in lap before auto-pause triggers [S: 2.0 s].")]
        [Range(0.5f, 5.0f)]
        [SerializeField] private float _lapRestHoldSeconds = 2.0f;

        [Header("Rest Reminder (§8.3)")]
        [Tooltip("Rest reminder interval in minutes [P: 8 min; S range: 7–10 min].")]
        [Range(7.0f, 10.0f)]
        [SerializeField] private float _restReminderIntervalMinutes = 8.0f;

        [Header("Lateral Lean / Balance Warning (§8.4 GP-SAFE-LEAN-01)")]
        [Tooltip("Maximum lateral head displacement |Δx| from SeatAnchor before warning [P: 0.20 m].")]
        [Range(0.08f, 0.45f)]
        [SerializeField] private float _lateralLeanThresholdM = 0.20f;

        [Tooltip("Hold duration beyond lateral lean threshold before soft pause [P: 0.5 s].")]
        [Range(0.1f, 2.0f)]
        [SerializeField] private float _lateralLeanHoldSeconds = 0.5f;

        [Header("Resume Countdown (§2 GP-FLOW-02)")]
        [Tooltip("Countdown duration before resuming gameplay [P: 3.0 s].")]
        [Range(1.0f, 5.0f)]
        [SerializeField] private float _resumeCountdownSeconds = 3.0f;

        public float LapRestDistanceM => Mathf.Max(0.05f, _lapRestDistanceM);
        public float LapRestHoldSeconds => Mathf.Max(0.25f, _lapRestHoldSeconds);
        public float RestReminderIntervalMinutes => Mathf.Clamp(_restReminderIntervalMinutes, 7.0f, 10.0f);
        public float LateralLeanThresholdM => Mathf.Max(0.05f, _lateralLeanThresholdM);
        public float LateralLeanHoldSeconds => Mathf.Max(0.1f, _lateralLeanHoldSeconds);
        public float ResumeCountdownSeconds => Mathf.Max(0.5f, _resumeCountdownSeconds);
    }
}

