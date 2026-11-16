using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// §6.2 Alternating Arm Reach implementation (04-ex-alternating-arm-reach.md).
    /// Left target at x = -w/2, right at x = +w/2, with w = clamp(W, 0.35, 0.50) m [S].
    /// y ≈ 0, z = k * R_f,hand.
    /// In one-hand mode, all targets use that enabled hand with alternating x offsets.
    /// </summary>
    public class AlternatingArmReachExercise : ExerciseBase
    {
        private readonly AlternatingArmReachConfig _config;

        public override ExerciseType Type => ExerciseType.AlternatingArmReach;

        public AlternatingArmReachExercise(AlternatingArmReachConfig config = null)
        {
            _config = config;
        }

        public static Vector3 ComputeLocalPosition(
            ComfortProfile profile,
            Hand handForDepth,
            bool placeOnRightSide,
            float reachFactorK,
            float minSpacingM = 0.35f,
            float maxSpacingM = 0.50f)
        {
            float w = Mathf.Clamp(profile.shoulderWidthM, minSpacingM, maxSpacingM);
            float x = placeOnRightSide ? (w * 0.5f) : (-w * 0.5f);
            float z = profile.GetTargetForwardDistance(handForDepth, reachFactorK);
            return new Vector3(x, 0f, z);
        }

        public override bool TryGetNextTargetSpawn(int targetIndex, out TargetSpawnSpec spawnSpec)
        {
            bool isRightSlot = (targetIndex % 2) == 1;
            Hand hand = SelectHandForTarget(targetIndex, alternateHands: true);
            TargetHand requiredHand = hand == Hand.Left ? TargetHand.Left : TargetHand.Right;

            float minW = _config != null ? _config.MinSpacingM : 0.35f;
            float maxW = _config != null ? _config.MaxSpacingM : 0.50f;

            Vector3 localPos = ComputeLocalPosition(
                Profile,
                hand,
                isRightSlot,
                Preset.ReachFactorK,
                minW,
                maxW);

            SpawnedInCurrentRound++;
            spawnSpec = new TargetSpawnSpec(requiredHand, localPos);
            return true;
        }
    }
}

