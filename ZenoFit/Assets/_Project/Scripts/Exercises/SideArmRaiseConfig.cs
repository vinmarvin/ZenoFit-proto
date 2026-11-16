using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Tunables for Side Arm Raise (05-ex-side-arm-raise.md §6.3, AT-02, AT-03).
    /// </summary>
    [CreateAssetMenu(fileName = "SideArmRaiseConfig", menuName = "ZenoFit/Exercises/Side Arm Raise Config")]
    public class SideArmRaiseConfig : ExerciseConfig
    {
        public const float HardCapAbductionAngleDeg = 70f;
        public const float DefaultMaxAbductionAngleDeg = 60f;
        public const float DefaultMinAbductionAngleDeg = 20f;

        [Header("Side Arm Raise Tunables (§6.3 [S] / [P])")]
        [Tooltip("Minimum abduction angle θ from body vertical axis [P: 20°].")]
        [Range(10f, 45f)]
        [SerializeField] private float _minAbductionAngleDeg = DefaultMinAbductionAngleDeg;

        [Tooltip("Maximum abduction angle θ_max [S: default 60°, hard cap 70°].")]
        [Range(30f, HardCapAbductionAngleDeg)]
        [SerializeField] private float _maxAbductionAngleDeg = DefaultMaxAbductionAngleDeg;

        [Tooltip("Maximum tempo cap for Side Arm Raise to protect shoulder loading [P: 60 BPM].")]
        [Range(40f, 60f)]
        [SerializeField] private float _tempoCapBpm = 60f;

        [Tooltip("Obstacle exclusion radius r_ex [P: 0.12 m].")]
        [Range(0.05f, 0.30f)]
        [SerializeField] private float _exclusionRadiusM = 0.12f;

        public float MinAbductionAngleDeg => Mathf.Clamp(_minAbductionAngleDeg, 10f, 50f);
        public float MaxAbductionAngleDeg => Mathf.Clamp(_maxAbductionAngleDeg, MinAbductionAngleDeg, HardCapAbductionAngleDeg);
        public float TempoCapBpm => Mathf.Clamp(_tempoCapBpm, 40f, 60f);
        public float ExclusionRadiusM => Mathf.Max(0.05f, _exclusionRadiusM);

        private void Reset()
        {
            InitMetadata(
                ExerciseType.SideArmRaise,
                "Side Arm Raise",
                "Gentle lateral arm raises around the shoulder, capped safely at 60° abduction.",
                adaptiveTempo: false);
        }
    }
}

