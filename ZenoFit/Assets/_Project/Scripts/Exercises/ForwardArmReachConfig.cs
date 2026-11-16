using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Tunables for Forward Arm Reach (03-ex-forward-arm-reach.md §6.1).
    /// </summary>
    [CreateAssetMenu(fileName = "ForwardArmReachConfig", menuName = "ZenoFit/Exercises/Forward Arm Reach Config")]
    public class ForwardArmReachConfig : ExerciseConfig
    {
        [Header("Forward Arm Reach Tunables (§6.1 [P])")]
        [Tooltip("Maximum horizontal jitter (±x) in metres [P: 0.10 m].")]
        [Range(0f, 0.25f)]
        [SerializeField] private float _horizontalJitterM = 0.10f;

        [Tooltip("Maximum vertical jitter (±y around chest level y=0) in metres [P: 0.05 m].")]
        [Range(0f, 0.15f)]
        [SerializeField] private float _verticalJitterM = 0.05f;

        public float HorizontalJitterM => Mathf.Clamp(_horizontalJitterM, 0f, 0.25f);
        public float VerticalJitterM => Mathf.Clamp(_verticalJitterM, 0f, 0.15f);

        private void Reset()
        {
            InitMetadata(
                ExerciseType.ForwardArmReach,
                "Forward Arm Reach",
                "Reach forward to chest-level targets within your comfortable reach envelope.",
                adaptiveTempo: true);
        }
    }
}

