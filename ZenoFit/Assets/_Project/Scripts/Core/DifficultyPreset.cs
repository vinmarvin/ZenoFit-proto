using UnityEngine;

namespace ZenoFit.Core
{
    /// <summary>
    /// Difficulty preset ScriptableObject (00-gameplay-overview.md §5.1, §5.3).
    /// GP-DIFF-01: Difficulty is adjustable via target distance (k), target size, and tempo only.
    /// GP-ENV-01: Reach factor k is hard-capped at 0.85.
    /// </summary>
    [CreateAssetMenu(fileName = "DifficultyPreset", menuName = "ZenoFit/Difficulty Preset", order = 1)]
    public class DifficultyPreset : ScriptableObject
    {
        public const float HardMaxReachFactor = 0.85f;

        [Header("Identity")]
        [SerializeField] private DifficultyTier _tier = DifficultyTier.Standard;

        [Header("Comfort & Reach (GP-DIFF-01, GP-ENV-01)")]
        [Tooltip("Fraction of calibrated forward/arm reach. Never exceeds 0.85 [S].")]
        [Range(0.30f, HardMaxReachFactor)]
        [SerializeField] private float _reachFactorK = 0.75f;

        [Header("Target Geometry (GP-DIFF-01)")]
        [Tooltip("Target sphere radius in metres [P].")]
        [Range(0.04f, 0.25f)]
        [SerializeField] private float _targetRadiusM = 0.10f;

        [Header("Tempo & Lifetime (GP-DIFF-01)")]
        [Tooltip("Starting tempo in beats per minute [S: 60 BPM Standard].")]
        [Range(40f, 120f)]
        [SerializeField] private float _startTempoBpm = 60f;

        [Tooltip("Maximum tempo in beats per minute [P].")]
        [Range(40f, 120f)]
        [SerializeField] private float _maxTempoBpm = 80f;

        [Tooltip("Target lifetime in beats before expiring as a miss [P].")]
        [Range(1, 6)]
        [SerializeField] private int _targetLifetimeBeats = 2;

        [Header("Session Structure (§5.1 [P])")]
        [Range(1, 100)]
        [SerializeField] private int _targetsPerRound = 20;

        [Range(1, 10)]
        [SerializeField] private int _roundsPerSession = 3;

        [Range(5f, 120f)]
        [SerializeField] private float _restBetweenRoundsSeconds = 30f;

        public DifficultyTier Tier => _tier;
        public float ReachFactorK => Mathf.Clamp(_reachFactorK, 0.10f, HardMaxReachFactor);
        public float TargetRadiusM => Mathf.Max(0.02f, _targetRadiusM);
        public float StartTempoBpm => Mathf.Max(40f, _startTempoBpm);
        public float MaxTempoBpm => Mathf.Max(_startTempoBpm, _maxTempoBpm);
        public int TargetLifetimeBeats => Mathf.Max(1, _targetLifetimeBeats);
        public int TargetsPerRound => Mathf.Max(1, _targetsPerRound);
        public int RoundsPerSession => Mathf.Max(1, _roundsPerSession);
        public float RestBetweenRoundsSeconds => Mathf.Max(0f, _restBetweenRoundsSeconds);

        public void Configure(
            DifficultyTier tier,
            float reachFactorK,
            float targetRadiusM,
            float startTempoBpm,
            float maxTempoBpm,
            int targetLifetimeBeats,
            int targetsPerRound = 20,
            int roundsPerSession = 3,
            float restBetweenRoundsSeconds = 30f)
        {
            _tier = tier;
            _reachFactorK = Mathf.Clamp(reachFactorK, 0.10f, HardMaxReachFactor);
            _targetRadiusM = Mathf.Max(0.02f, targetRadiusM);
            _startTempoBpm = Mathf.Max(40f, startTempoBpm);
            _maxTempoBpm = Mathf.Max(_startTempoBpm, maxTempoBpm);
            _targetLifetimeBeats = Mathf.Max(1, targetLifetimeBeats);
            _targetsPerRound = Mathf.Max(1, targetsPerRound);
            _roundsPerSession = Mathf.Max(1, roundsPerSession);
            _restBetweenRoundsSeconds = Mathf.Max(0f, restBetweenRoundsSeconds);
        }

        /// <summary>
        /// Creates a runtime instance initialized to the spec table values (§5.3).
        /// </summary>
        public static DifficultyPreset CreateRuntimePreset(DifficultyTier tier)
        {
            var preset = CreateInstance<DifficultyPreset>();
            ApplySpecDefaults(preset, tier);
            return preset;
        }

        public static void ApplySpecDefaults(DifficultyPreset preset, DifficultyTier tier)
        {
            switch (tier)
            {
                case DifficultyTier.Gentle:
                    preset.Configure(DifficultyTier.Gentle, 0.60f, 0.12f, 50f, 70f, 3);
                    break;
                case DifficultyTier.Active:
                    preset.Configure(DifficultyTier.Active, 0.85f, 0.08f, 70f, 90f, 2);
                    break;
                case DifficultyTier.Standard:
                default:
                    preset.Configure(DifficultyTier.Standard, 0.75f, 0.10f, 60f, 80f, 2);
                    break;
            }
        }
    }
}

