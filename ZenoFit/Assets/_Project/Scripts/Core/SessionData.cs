using System;
using System.Collections.Generic;

namespace ZenoFit.Core
{
    /// <summary>
    /// Serializable session record appended to sessions.json (08-scoring-and-results.md §7.4 GP-PROG-01).
    /// </summary>
    [Serializable]
    public class SessionRecord
    {
        public string dateUtc;
        public string exercise;
        public string difficulty;
        public string handMode;
        public float durationSeconds;
        public int hits;
        public int misses;
        public float accuracyPercent;
        public int score;
        public float maxTempoReachedBpm;
    }

    [Serializable]
    public class SessionHistoryFile
    {
        public int version = 1;
        public List<SessionRecord> sessions = new List<SessionRecord>();
    }

    /// <summary>
    /// Active runtime session configuration and results summary.
    /// </summary>
    [Serializable]
    public class ActiveSessionData
    {
        public ExerciseType SelectedExercise = ExerciseType.ForwardArmReach;
        public DifficultyTier SelectedDifficulty = DifficultyTier.Standard;
        public HandMode SelectedHandMode = HandMode.BothHands;

        public int CurrentRound = 1;
        public int TotalRounds = 3;
        public int Hits = 0;
        public int Misses = 0;
        public int TotalScore = 0;
        public float CurrentTempoBpm = 60f;
        public float MaxTempoReachedBpm = 60f;
        public float ElapsedPlaySeconds = 0f;

        public int TotalTargetsAttempted => Hits + Misses;
        public float AccuracyPercent => TotalTargetsAttempted > 0
            ? (100f * Hits) / TotalTargetsAttempted
            : 0f;

        public void ResetForNewSession(ExerciseType exercise, DifficultyTier difficulty, HandMode handMode, float startBpm, int totalRounds)
        {
            SelectedExercise = exercise;
            SelectedDifficulty = difficulty;
            SelectedHandMode = handMode;
            CurrentRound = 1;
            TotalRounds = Math.Max(1, totalRounds);
            Hits = 0;
            Misses = 0;
            TotalScore = 0;
            CurrentTempoBpm = startBpm;
            MaxTempoReachedBpm = startBpm;
            ElapsedPlaySeconds = 0f;
        }

        public SessionRecord ToRecord()
        {
            return new SessionRecord
            {
                dateUtc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"),
                exercise = SelectedExercise.ToString(),
                difficulty = SelectedDifficulty.ToString(),
                handMode = SelectedHandMode.ToString(),
                durationSeconds = ElapsedPlaySeconds,
                hits = Hits,
                misses = Misses,
                accuracyPercent = AccuracyPercent,
                score = TotalScore,
                maxTempoReachedBpm = MaxTempoReachedBpm
            };
        }
    }
}

