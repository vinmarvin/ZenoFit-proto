using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// §6.1 Forward Arm Reach implementation (03-ex-forward-arm-reach.md, AT-01).
    /// Position in BodyFrame:
    ///   x in [-0.10, +0.10] m
    ///   y in [-0.05, +0.05] m (chest level y ≈ 0)
    ///   z = k * R_f,hand (with k <= 0.85)
    /// </summary>
    public class ForwardArmReachExercise : ExerciseBase
    {
        private readonly ForwardArmReachConfig _config;

        public override ExerciseType Type => ExerciseType.ForwardArmReach;

        public ForwardArmReachExercise(ForwardArmReachConfig config = null)
        {
            _config = config;
        }

        /// <summary>
        /// Pure maths helper for computing Forward Arm Reach target position in BodyFrame (AT-01).
        /// </summary>
        public static Vector3 ComputeLocalPosition(
            ComfortProfile profile,
            Hand hand,
            float reachFactorK,
            float jitterX = 0f,
            float jitterY = 0f,
            float maxJitterX = 0.10f,
            float maxJitterY = 0.05f)
        {
            float z = profile.GetTargetForwardDistance(hand, reachFactorK);
            float x = Mathf.Clamp(jitterX, -maxJitterX, maxJitterX);
            float y = Mathf.Clamp(jitterY, -maxJitterY, maxJitterY);
            return new Vector3(x, y, z);
        }

        public override bool TryGetNextTargetSpawn(int targetIndex, out TargetSpawnSpec spawnSpec)
        {
            Hand hand = SelectHandForTarget(targetIndex, alternateHands: false);
            TargetHand targetHand = hand == Hand.Left ? TargetHand.Left : TargetHand.Right;

            float maxX = _config != null ? _config.HorizontalJitterM : 0.10f;
            float maxY = _config != null ? _config.VerticalJitterM : 0.05f;
            float jitterX = Random.Range(-maxX, maxX);
            float jitterY = Random.Range(-maxY, maxY);

            Vector3 localPos = ComputeLocalPosition(
                Profile,
                hand,
                Preset.ReachFactorK,
                jitterX,
                jitterY,
                maxX,
                maxY);

            SpawnedInCurrentRound++;
            spawnSpec = new TargetSpawnSpec(targetHand, localPos);
            return true;
        }
    }
}

