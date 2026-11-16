using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Targets;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// §6.5 Forward Press implementation (06-ex-forward-press.md).
    /// - Button plane at z = k * R_f (uses smaller R_f if both hands enabled), centered x ≈ 0, y ≈ 0.
    /// - Travel depth d_p = 0.03 m [P]. Registers press when a hand tip pushes it past d_p along +Z.
    /// - Hysteresis: user must release before the next press registers.
    /// - Feedback: soft click audio + 50 ms haptic [S].
    /// </summary>
    public class ForwardPressExercise : ExerciseBase
    {
        private readonly ForwardPressConfig _config;
        private bool _leftHandRequiresRelease;
        private bool _rightHandRequiresRelease;

        public override ExerciseType Type => ExerciseType.ForwardPress;

        public ForwardPressExercise(ForwardPressConfig config = null)
        {
            _config = config;
        }

        public override void ResetRound()
        {
            base.ResetRound();
            _leftHandRequiresRelease = false;
            _rightHandRequiresRelease = false;
        }

        public static Vector3 ComputeButtonPosition(ComfortProfile profile, float reachFactorK, HandMode handMode)
        {
            float z = profile.GetSharedForwardDistance(reachFactorK, handMode);
            return new Vector3(0f, 0f, z);
        }

        /// <summary>
        /// Pure C# evaluation of elastic button press with travel depth d_p and release hysteresis (§6.5).
        /// </summary>
        public static bool EvaluateElasticPress(
            Vector3 buttonLocalPos,
            float buttonRadiusM,
            float travelDepthM,
            Vector3 handLocalPos,
            float handTipRadiusM,
            ref bool handRequiresRelease,
            out float currentDepressionM)
        {
            currentDepressionM = 0f;

            // Check if hand is released behind the front face of the button
            float frontSurfaceZ = buttonLocalPos.z - buttonRadiusM * 0.25f;
            if (handLocalPos.z <= frontSurfaceZ)
            {
                handRequiresRelease = false;
            }

            Vector2 lateralDelta = new Vector2(handLocalPos.x - buttonLocalPos.x, handLocalPos.y - buttonLocalPos.y);
            if (lateralDelta.magnitude > buttonRadiusM + handTipRadiusM)
                return false;

            float pushPastPlane = handLocalPos.z - buttonLocalPos.z;
            if (pushPastPlane > 0f)
            {
                currentDepressionM = pushPastPlane;
            }

            if (handRequiresRelease)
                return false;

            if (pushPastPlane >= travelDepthM - 1e-4f)
            {
                handRequiresRelease = true;
                return true;
            }

            return false;
        }

        public override bool TryGetNextTargetSpawn(int targetIndex, out TargetSpawnSpec spawnSpec)
        {
            float travelDepth = _config != null ? _config.PressTravelDepthM : ForwardPressConfig.DefaultPressTravelDepthM;
            Vector3 localPos = ComputeButtonPosition(Profile, Preset.ReachFactorK, EffectiveHandMode);

            TargetHand targetHand = TargetHand.Either;
            if (EffectiveHandMode == HandMode.LeftOnly)
                targetHand = TargetHand.Left;
            else if (EffectiveHandMode == HandMode.RightOnly)
                targetHand = TargetHand.Right;

            SpawnedInCurrentRound++;
            spawnSpec = new TargetSpawnSpec(targetHand, localPos, isElasticPress: true, pressTravelDepthM: travelDepth);
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

            if (!Profile.IsHandEnabled(candidateHand))
                return false;
            if (EffectiveHandMode == HandMode.LeftOnly && candidateHand != Hand.Left)
                return false;
            if (EffectiveHandMode == HandMode.RightOnly && candidateHand != Hand.Right)
                return false;

            Vector3 handLocal = bodyFrame.ToLocal(currHandWorld);
            float travelDepth = _config != null ? _config.PressTravelDepthM : ForwardPressConfig.DefaultPressTravelDepthM;

            bool requiresRelease = candidateHand == Hand.Left ? _leftHandRequiresRelease : _rightHandRequiresRelease;
            bool pressed = EvaluateElasticPress(
                activeTarget.BaseLocalPosition,
                activeTarget.RadiusM,
                travelDepth,
                handLocal,
                handTipRadiusM,
                ref requiresRelease,
                out float depressionM);

            if (_config == null || _config.RequireReleaseBeforeNextPress)
            {
                if (candidateHand == Hand.Left)
                    _leftHandRequiresRelease = requiresRelease;
                else
                    _rightHandRequiresRelease = requiresRelease;
            }

            activeTarget.SetElasticDepression(depressionM, bodyFrame.DirectionToWorld(Vector3.forward));

            if (pressed)
            {
                Haptics?.PlayForwardPressClick(candidateHand);
                return true;
            }

            return false;
        }
    }
}

