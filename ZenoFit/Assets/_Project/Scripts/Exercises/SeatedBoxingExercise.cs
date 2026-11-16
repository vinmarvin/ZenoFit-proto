using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Targets;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// §6.6 Seated Boxing implementation (07-ex-seated-boxing.md, AT-12).
    /// - Target pads at x = ±w/2, y ≈ 0, z = k * R_f,hand.
    /// - A hit counts on contact. No penalty for slow motion and no maximum speed [S].
    /// - Speed v >= v_solid (default 0.30 m/s [P], or 0 in Touch Mode) -> "solid" hit (+25 bonus, stronger haptic).
    /// - Speed v < v_solid -> "light" hit (very soft haptic, still scores base + timeliness points).
    /// </summary>
    public class SeatedBoxingExercise : ExerciseBase
    {
        private readonly SeatedBoxingConfig _config;

        public override ExerciseType Type => ExerciseType.SeatedBoxing;

        public SeatedBoxingExercise(SeatedBoxingConfig config = null)
        {
            _config = config;
        }

        /// <summary>
        /// Pure C# evaluation of whether a boxing contact qualifies as a solid hit or light hit (AT-12).
        /// Both solid and light hits score points!
        /// </summary>
        public static bool IsSolidHit(
            float handSmoothedSpeedMps,
            float solidSpeedThresholdMps = SeatedBoxingConfig.DefaultSolidHitSpeedMps,
            bool touchMode = false)
        {
            if (touchMode)
                return true;

            return handSmoothedSpeedMps >= solidSpeedThresholdMps - 1e-5f;
        }

        public override bool TryGetNextTargetSpawn(int targetIndex, out TargetSpawnSpec spawnSpec)
        {
            bool isRightSlot = (targetIndex % 2) == 1;
            Hand hand = SelectHandForTarget(targetIndex, alternateHands: true);
            TargetHand requiredHand = hand == Hand.Left ? TargetHand.Left : TargetHand.Right;

            float w = Profile.GetClampedShoulderSpacing();
            float x = isRightSlot ? (w * 0.5f) : (-w * 0.5f);
            float z = Profile.GetTargetForwardDistance(hand, Preset.ReachFactorK);

            SpawnedInCurrentRound++;
            spawnSpec = new TargetSpawnSpec(requiredHand, new Vector3(x, 0f, z));
            return true;
        }

        public override bool EvaluateTargetHit(
            Target activeTarget,
            BodyFrame bodyFrame,
            Hand candidateHand,
            Vector3 prevHandWorld,
            Vector3 currHandWorld,
            float handTipRadiusM,
            float handSmoothedSpeedMps,
            out bool isSolidHit)
        {
            isSolidHit = false;
            if (activeTarget == null || !activeTarget.IsActiveTarget)
                return false;

            bool isHandEnabled = Profile.IsHandEnabled(candidateHand);
            bool contact = HitDetector.TryCheckValidHandHit(
                candidateHand,
                isHandEnabled,
                EffectiveHandMode,
                activeTarget.RequiredHand,
                activeTarget.transform.position,
                activeTarget.RadiusM,
                prevHandWorld,
                currHandWorld,
                handTipRadiusM);

            if (!contact)
                return false;

            float threshold = _config != null ? _config.SolidHitSpeedMps : SeatedBoxingConfig.DefaultSolidHitSpeedMps;
            bool touchMode = (Settings != null && Settings.boxingTouchMode) || (_config != null && _config.TouchModeDefault);

            isSolidHit = IsSolidHit(handSmoothedSpeedMps, threshold, touchMode);
            Haptics?.PlayBoxingHit(candidateHand, isSolidHit);
            return true;
        }
    }
}

