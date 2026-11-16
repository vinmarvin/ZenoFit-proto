using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Tunables for Alternating Arm Reach (04-ex-alternating-arm-reach.md §6.2).
    /// </summary>
    [CreateAssetMenu(fileName = "AlternatingArmReachConfig", menuName = "ZenoFit/Exercises/Alternating Arm Reach Config")]
    public class AlternatingArmReachConfig : ExerciseConfig
    {
        [Header("Alternating Arm Reach Tunables (§6.2 [S] / [P])")]
        [Tooltip("Minimum target horizontal spacing w [S: 0.35 m].")]
        [Range(0.25f, 0.45f)]
        [SerializeField] private float _minSpacingM = 0.35f;

        [Tooltip("Maximum target horizontal spacing w [S: 0.50 m].")]
        [Range(0.35f, 0.60f)]
        [SerializeField] private float _maxSpacingM = 0.50f;

        public float MinSpacingM => _minSpacingM;
        public float MaxSpacingM => Mathf.Max(_minSpacingM, _maxSpacingM);

        private void Reset()
        {
            InitMetadata(
                ExerciseType.AlternatingArmReach,
                "Alternating Arm Reach",
                "Alternate left and right reaches in rhythm within your shoulder width.",
                adaptiveTempo: true);
        }
    }
}

