using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Feedback;
using ZenoFit.Scoring;
using ZenoFit.Targets;

namespace ZenoFit.Exercises
{
    public readonly struct TargetSpawnSpec
    {
        public readonly TargetHand RequiredHand;
        public readonly Vector3 LocalPosition;
        public readonly bool IsElasticPress;
        public readonly float PressTravelDepthM;

        public TargetSpawnSpec(
            TargetHand requiredHand,
            Vector3 localPosition,
            bool isElasticPress = false,
            float pressTravelDepthM = 0.03f)
        {
            RequiredHand = requiredHand;
            LocalPosition = localPosition;
            IsElasticPress = isElasticPress;
            PressTravelDepthM = pressTravelDepthM;
        }
    }

    /// <summary>
    /// Independent base class for each seated exercise (00-README.md §5 Rule 11).
    /// Handles beat clock, target lifetime, hit/miss evaluation, and hand mode rules.
    /// </summary>
    public abstract class ExerciseBase
    {
        protected ComfortProfile Profile { get; private set; }
        protected DifficultyPreset Preset { get; private set; }
        protected AppSettings Settings { get; private set; }
        protected HandMode EffectiveHandMode { get; private set; }
        protected AdaptiveTempo Tempo { get; private set; }
        protected AccuracyTracker Tracker { get; private set; }
        protected HapticFeedbackController Haptics { get; private set; }

        public abstract ExerciseType Type { get; }
        public int SpawnedInCurrentRound { get; protected set; }

        public virtual void Initialize(
            ComfortProfile profile,
            DifficultyPreset preset,
            AppSettings settings,
            AdaptiveTempo tempo,
            AccuracyTracker tracker,
            HapticFeedbackController haptics)
        {
            Profile = profile ?? ComfortProfile.CreateDefault();
            Preset = preset ?? DifficultyPreset.CreateRuntimePreset(DifficultyTier.Standard);
            Settings = settings ?? new AppSettings();
            EffectiveHandMode = Settings.GetEffectiveHandMode(Profile.leftHand.enabled, Profile.rightHand.enabled);
            Tempo = tempo;
            Tracker = tracker;
            Haptics = haptics;
            SpawnedInCurrentRound = 0;
        }

        public virtual void ResetRound()
        {
            SpawnedInCurrentRound = 0;
        }

        /// <summary>
        /// Computes the next target spawn specification in BodyFrame local coordinates.
        /// </summary>
        public abstract bool TryGetNextTargetSpawn(int targetIndex, out TargetSpawnSpec spawnSpec);

        /// <summary>
        /// Evaluates whether a hand tip hit the active target this frame.
        /// Returns true if the target was hit and consumed.
        /// </summary>
        public virtual bool EvaluateTargetHit(
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
            bool hit = HitDetector.TryCheckValidHandHit(
                candidateHand,
                isHandEnabled,
                EffectiveHandMode,
                activeTarget.RequiredHand,
                activeTarget.transform.position,
                activeTarget.RadiusM,
                prevHandWorld,
                currHandWorld,
                handTipRadiusM);

            if (hit)
            {
                Haptics?.PlayReachHit(candidateHand);
            }
            return hit;
        }

        protected Hand SelectHandForTarget(int targetIndex, bool alternateHands)
        {
            if (EffectiveHandMode == HandMode.LeftOnly || !Profile.rightHand.enabled)
                return Hand.Left;
            if (EffectiveHandMode == HandMode.RightOnly || !Profile.leftHand.enabled)
                return Hand.Right;

            if (alternateHands)
                return (targetIndex % 2 == 0) ? Hand.Left : Hand.Right;

            return (Random.value < 0.5f) ? Hand.Left : Hand.Right;
        }
    }
}

