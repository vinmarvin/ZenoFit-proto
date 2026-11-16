using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Tunables for Seated Boxing (07-ex-seated-boxing.md §6.6, AT-12).
    /// </summary>
    [CreateAssetMenu(fileName = "SeatedBoxingConfig", menuName = "ZenoFit/Exercises/Seated Boxing Config")]
    public class SeatedBoxingConfig : ExerciseConfig
    {
        public const float DefaultSolidHitSpeedMps = 0.30f;
        public const int DefaultSolidHitBonusPoints = 25;

        [Header("Seated Boxing Tunables (§6.6 [S] / [P])")]
        [Tooltip("Minimum smoothed hand speed for a 'solid' hit [P: 0.30 m/s]. Contact slower than this is a 'light' hit and still scores [S].")]
        [Range(0f, 1.5f)]
        [SerializeField] private float _solidHitSpeedMps = DefaultSolidHitSpeedMps;

        [Tooltip("Touch mode: v_solid = 0 so every contact counts as a solid hit [P].")]
        [SerializeField] private bool _touchModeDefault = false;

        [Tooltip("Bonus points awarded for a solid hit [P: +25].")]
        [Range(0, 100)]
        [SerializeField] private int _solidHitBonusPoints = DefaultSolidHitBonusPoints;

        public float SolidHitSpeedMps => Mathf.Max(0f, _solidHitSpeedMps);
        public bool TouchModeDefault => _touchModeDefault;
        public int SolidHitBonusPoints => Mathf.Max(0, _solidHitBonusPoints);

        private void Reset()
        {
            InitMetadata(
                ExerciseType.SeatedBoxing,
                "Seated Boxing",
                "Gentle rhythm punches at target pads. Every contact scores; solid speed adds a bonus.",
                adaptiveTempo: true);
        }
    }
}

