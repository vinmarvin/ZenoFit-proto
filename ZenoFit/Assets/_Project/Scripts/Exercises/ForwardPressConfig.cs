using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Tunables for Forward Press (06-ex-forward-press.md §6.5).
    /// </summary>
    [CreateAssetMenu(fileName = "ForwardPressConfig", menuName = "ZenoFit/Exercises/Forward Press Config")]
    public class ForwardPressConfig : ExerciseConfig
    {
        public const float DefaultPressTravelDepthM = 0.03f;
        public const float ClickHapticDurationSeconds = 0.050f; // 50 ms [S]

        [Header("Forward Press Tunables (§6.5 [S] / [P])")]
        [Tooltip("Elastic button press travel depth d_p along +Z [P: 0.03 m].")]
        [Range(0.01f, 0.08f)]
        [SerializeField] private float _pressTravelDepthM = DefaultPressTravelDepthM;

        [Tooltip("Require the hand to release back behind the button surface before the next press [P: true].")]
        [SerializeField] private bool _requireReleaseBeforeNextPress = true;

        public float PressTravelDepthM => Mathf.Max(0.01f, _pressTravelDepthM);
        public bool RequireReleaseBeforeNextPress => _requireReleaseBeforeNextPress;

        private void Reset()
        {
            InitMetadata(
                ExerciseType.ForwardPress,
                "Forward Press",
                "Push a virtual elastic button forward past its 3 cm travel depth on the beat.",
                adaptiveTempo: false);
        }
    }
}

