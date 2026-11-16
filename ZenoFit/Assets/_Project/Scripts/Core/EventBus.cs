using System;

namespace ZenoFit.Core
{
    public readonly struct TargetHitEvent
    {
        public readonly Hand HandUsed;
        public readonly int PointsAwarded;
        public readonly float ReactionTimeSeconds;
        public readonly bool IsSolidHit;
        public readonly int TotalScore;
        public readonly float CurrentAccuracyPercent;

        public TargetHitEvent(
            Hand handUsed,
            int pointsAwarded,
            float reactionTimeSeconds,
            bool isSolidHit,
            int totalScore,
            float currentAccuracyPercent)
        {
            HandUsed = handUsed;
            PointsAwarded = pointsAwarded;
            ReactionTimeSeconds = reactionTimeSeconds;
            IsSolidHit = isSolidHit;
            TotalScore = totalScore;
            CurrentAccuracyPercent = currentAccuracyPercent;
        }
    }

    public readonly struct TargetMissedEvent
    {
        public readonly TargetHand ExpectedHand;
        public readonly int TotalMisses;
        public readonly float CurrentAccuracyPercent;

        public TargetMissedEvent(TargetHand expectedHand, int totalMisses, float currentAccuracyPercent)
        {
            ExpectedHand = expectedHand;
            TotalMisses = totalMisses;
            CurrentAccuracyPercent = currentAccuracyPercent;
        }
    }

    public readonly struct SessionPausedEvent
    {
        public readonly PauseReason Reason;
        public readonly string Message;
        public readonly bool RequestPassthrough;

        public SessionPausedEvent(PauseReason reason, string message, bool requestPassthrough)
        {
            Reason = reason;
            Message = message;
            RequestPassthrough = requestPassthrough;
        }
    }

    /// <summary>
    /// Lightweight, allocation-free C# event bus (01-techstack.md §4).
    /// </summary>
    public static class EventBus
    {
        public static event Action<AppState, AppState> StateChanged;
        public static event Action<TargetHitEvent> TargetHit;
        public static event Action<TargetMissedEvent> TargetMissed;
        public static event Action<SessionPausedEvent> SessionPaused;
        public static event Action SessionResumed;
        public static event Action<float> ResumeCountdownTick;
        public static event Action RestDue;
        public static event Action<float> TempoChanged;
        public static event Action<int, string> CalibrationStepChanged;

        public static void PublishStateChanged(AppState previous, AppState next) => StateChanged?.Invoke(previous, next);
        public static void PublishTargetHit(TargetHitEvent evt) => TargetHit?.Invoke(evt);
        public static void PublishTargetMissed(TargetMissedEvent evt) => TargetMissed?.Invoke(evt);
        public static void PublishSessionPaused(SessionPausedEvent evt) => SessionPaused?.Invoke(evt);
        public static void PublishSessionResumed() => SessionResumed?.Invoke();
        public static void PublishResumeCountdownTick(float remainingSeconds) => ResumeCountdownTick?.Invoke(remainingSeconds);
        public static void PublishRestDue() => RestDue?.Invoke();
        public static void PublishTempoChanged(float newBpm) => TempoChanged?.Invoke(newBpm);
        public static void PublishCalibrationStepChanged(int stepIndex, string instruction) => CalibrationStepChanged?.Invoke(stepIndex, instruction);

        public static void ClearAllSubscribers()
        {
            StateChanged = null;
            TargetHit = null;
            TargetMissed = null;
            SessionPaused = null;
            SessionResumed = null;
            ResumeCountdownTick = null;
            RestDue = null;
            TempoChanged = null;
            CalibrationStepChanged = null;
        }
    }
}

