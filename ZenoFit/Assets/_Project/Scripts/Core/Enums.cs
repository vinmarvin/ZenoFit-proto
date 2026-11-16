using System;

namespace ZenoFit.Core
{
    /// <summary>
    /// Controller hand identifier used by IPlatformServices and calibration.
    /// Matches 01-techstack.md §3.2.
    /// </summary>
    public enum Hand
    {
        Left = 0,
        Right = 1
    }

    /// <summary>
    /// Which hand is allowed to hit a spawned target (02-targets-and-hit-detection.md §6.0).
    /// </summary>
    public enum TargetHand
    {
        Left = 0,
        Right = 1,
        Either = 2
    }

    /// <summary>
    /// Session hand mode (00-gameplay-overview.md §5.2 GP-HAND-01).
    /// </summary>
    public enum HandMode
    {
        BothHands = 0,
        LeftOnly = 1,
        RightOnly = 2
    }

    /// <summary>
    /// Difficulty preset levels (00-gameplay-overview.md §5.3).
    /// </summary>
    public enum DifficultyTier
    {
        Gentle = 0,
        Standard = 1,
        Active = 2
    }

    /// <summary>
    /// The 5 prototype seated upper-body exercises (00-README.md §2).
    /// </summary>
    public enum ExerciseType
    {
        ForwardArmReach = 0,
        AlternatingArmReach = 1,
        SideArmRaise = 2,
        ForwardPress = 3,
        SeatedBoxing = 4
    }

    /// <summary>
    /// Application flow states (00-gameplay-overview.md §2).
    /// </summary>
    public enum AppState
    {
        Boot = 0,
        MainMenu = 1,
        Calibration = 2,
        ExerciseSelect = 3,
        Gameplay = 4,
        Paused = 5,
        Results = 6
    }

    /// <summary>
    /// Reason why Gameplay entered the Paused state (09-safety.md §8).
    /// </summary>
    public enum PauseReason
    {
        None = 0,
        Manual = 1,
        AutoPauseLap = 2,
        RestReminder = 3,
        LeanWarning = 4,
        RecenterRequired = 5
    }
}

