using UnityEngine;

namespace ZenoFit.Calibration
{
    /// <summary>
    /// Tunable parameters for Calibration and Comfort Envelope (01-body-frame-and-calibration.md Tunables).
    /// </summary>
    [CreateAssetMenu(fileName = "CalibrationConfig", menuName = "ZenoFit/Calibration Config", order = 2)]
    public class CalibrationConfig : ScriptableObject
    {
        [Header("Comfort Envelope Limits [S] / [P]")]
        [Tooltip("Maximum reach factor k [S: <= 0.85].")]
        [Range(0.50f, 0.85f)]
        [SerializeField] private float _maxReachFactorK = 0.85f;

        [Tooltip("Default chest offset below head if Step 2 is skipped [P: 0.25 m].")]
        [Range(0.10f, 0.45f)]
        [SerializeField] private float _defaultChestOffsetBelowHeadM = 0.25f;

        [Tooltip("Default shoulder width W if Step 3 is skipped [P: 0.40 m].")]
        [Range(0.25f, 0.60f)]
        [SerializeField] private float _defaultShoulderWidthM = 0.40f;

        [Tooltip("Default forward reach if needed as a fallback [P: 0.55 m].")]
        [Range(0.25f, 0.85f)]
        [SerializeField] private float _defaultForwardReachM = 0.55f;

        [Tooltip("Default arm length if needed as a fallback [P: 0.60 m].")]
        [Range(0.30f, 0.90f)]
        [SerializeField] private float _defaultArmLengthM = 0.60f;

        [Header("Obstacles (§4.5 GP-CAL-07)")]
        [Tooltip("Obstacle exclusion sphere radius r_ex [P: 0.12 m].")]
        [Range(0.05f, 0.30f)]
        [SerializeField] private float _obstacleExclusionRadiusM = 0.12f;

        [Tooltip("Maximum placement retries before widening angle or skipping spawn [P].")]
        [Range(4, 32)]
        [SerializeField] private int _maxPlacementAttempts = 12;

        public float MaxReachFactorK => Mathf.Clamp(_maxReachFactorK, 0.50f, ComfortProfile.HardMaxReachFactor);
        public float DefaultChestOffsetBelowHeadM => Mathf.Max(0.10f, _defaultChestOffsetBelowHeadM);
        public float DefaultShoulderWidthM => Mathf.Clamp(_defaultShoulderWidthM, 0.25f, 0.60f);
        public float DefaultForwardReachM => Mathf.Clamp(_defaultForwardReachM, 0.20f, 0.85f);
        public float DefaultArmLengthM => Mathf.Clamp(_defaultArmLengthM, 0.25f, 0.90f);
        public float ObstacleExclusionRadiusM => Mathf.Max(0.05f, _obstacleExclusionRadiusM);
        public int MaxPlacementAttempts => Mathf.Max(1, _maxPlacementAttempts);
    }
}

