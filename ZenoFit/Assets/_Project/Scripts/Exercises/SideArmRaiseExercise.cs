using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// §6.3 Side Arm Raise implementation (05-ex-side-arm-raise.md, GP-SIDE-01, AT-02, AT-03).
    /// Formulas:
    ///   θ        = abduction angle from body vertical axis (0° = hanging down, 90° = horizontal)
    ///   r        = k * L_arm
    ///   x_offset = ± r * sin(θ)   (+ for right, - for left, relative to that shoulder)
    ///   y_offset = - r * cos(θ)   (negative = below shoulder level)
    ///   θ <= θ_max (default 60°, hard cap 70° [S])
    /// </summary>
    public class SideArmRaiseExercise : ExerciseBase
    {
        private readonly SideArmRaiseConfig _config;

        public override ExerciseType Type => ExerciseType.SideArmRaise;

        public SideArmRaiseExercise(SideArmRaiseConfig config = null)
        {
            _config = config;
        }

        /// <summary>
        /// Clamps requested abduction angle θ so it never exceeds θ_max or the 70° hard cap (AT-03).
        /// </summary>
        public static float ClampAbductionAngle(
            float requestedAngleDeg,
            float configuredMaxAngleDeg = SideArmRaiseConfig.DefaultMaxAbductionAngleDeg,
            float minAngleDeg = SideArmRaiseConfig.DefaultMinAbductionAngleDeg)
        {
            float safeMax = Mathf.Min(configuredMaxAngleDeg, SideArmRaiseConfig.HardCapAbductionAngleDeg);
            float safeMin = Mathf.Min(minAngleDeg, safeMax);
            return Mathf.Clamp(requestedAngleDeg, safeMin, safeMax);
        }

        /// <summary>
        /// Pure maths helper for computing (x_offset, y_offset) relative to the shoulder (AT-02).
        /// </summary>
        public static Vector2 ComputeShoulderOffset(
            float armLengthM,
            float reachFactorK,
            float requestedThetaDeg,
            Hand hand,
            float configuredMaxThetaDeg = SideArmRaiseConfig.DefaultMaxAbductionAngleDeg,
            float minThetaDeg = SideArmRaiseConfig.DefaultMinAbductionAngleDeg)
        {
            float clampedK = Mathf.Clamp(reachFactorK, 0.05f, ComfortProfile.HardMaxReachFactor);
            float clampedThetaDeg = ClampAbductionAngle(requestedThetaDeg, configuredMaxThetaDeg, minThetaDeg);
            float thetaRad = clampedThetaDeg * Mathf.Deg2Rad;

            float r = clampedK * Mathf.Max(0.20f, armLengthM);
            float sign = (hand == Hand.Right) ? 1f : -1f;
            float xOffset = sign * r * Mathf.Sin(thetaRad);
            float yOffset = -r * Mathf.Cos(thetaRad);

            return new Vector2(xOffset, yOffset);
        }

        /// <summary>
        /// Computes full BodyFrame target position and steps down θ if an obstacle exclusion sphere is hit (§6.3 Case Study, GP-SIDE-01).
        /// </summary>
        public static bool TryComputeSafeLocalPosition(
            ComfortProfile profile,
            Hand hand,
            float reachFactorK,
            float requestedThetaDeg,
            float targetRadiusM,
            out Vector3 safeLocalPosition,
            float configuredMaxThetaDeg = SideArmRaiseConfig.DefaultMaxAbductionAngleDeg,
            float minThetaDeg = SideArmRaiseConfig.DefaultMinAbductionAngleDeg,
            float exclusionRadiusM = ComfortProfile.DefaultExclusionRadiusM)
        {
            Vector3 shoulderLocal = profile.GetShoulderLocalPosition(hand);
            float armLen = profile.GetHandData(hand).armLengthM;
            float currentTheta = ClampAbductionAngle(requestedThetaDeg, configuredMaxThetaDeg, minThetaDeg);

            while (currentTheta >= minThetaDeg - 0.01f)
            {
                Vector2 offset = ComputeShoulderOffset(armLen, reachFactorK, currentTheta, hand, configuredMaxThetaDeg, minThetaDeg);
                // Place slightly in front of shoulder coronal plane (+0.12 m Z) for comfortable seated visibility
                Vector3 candidate = new Vector3(shoulderLocal.x + offset.x, shoulderLocal.y + offset.y, shoulderLocal.z + 0.12f);

                if (!profile.IsViolatingObstacleZone(candidate, targetRadiusM, exclusionRadiusM))
                {
                    safeLocalPosition = candidate;
                    return true;
                }

                currentTheta -= 5f;
            }

            safeLocalPosition = Vector3.zero;
            return false;
        }

        public override bool TryGetNextTargetSpawn(int targetIndex, out TargetSpawnSpec spawnSpec)
        {
            Hand hand = SelectHandForTarget(targetIndex, alternateHands: true);
            TargetHand requiredHand = hand == Hand.Left ? TargetHand.Left : TargetHand.Right;

            float minDeg = _config != null ? _config.MinAbductionAngleDeg : SideArmRaiseConfig.DefaultMinAbductionAngleDeg;
            float maxDeg = _config != null ? _config.MaxAbductionAngleDeg : SideArmRaiseConfig.DefaultMaxAbductionAngleDeg;
            float exclRad = _config != null ? _config.ExclusionRadiusM : ComfortProfile.DefaultExclusionRadiusM;

            // Vary angle smoothly between minDeg and maxDeg
            float t = (targetIndex % 5) / 4f;
            float desiredTheta = Mathf.Lerp(minDeg + 10f, maxDeg, t);

            if (!TryComputeSafeLocalPosition(
                Profile,
                hand,
                Preset.ReachFactorK,
                desiredTheta,
                Preset.TargetRadiusM,
                out Vector3 safePos,
                maxDeg,
                minDeg,
                exclRad))
            {
                spawnSpec = default;
                return false;
            }

            SpawnedInCurrentRound++;
            spawnSpec = new TargetSpawnSpec(requiredHand, safePos);
            return true;
        }
    }
}

