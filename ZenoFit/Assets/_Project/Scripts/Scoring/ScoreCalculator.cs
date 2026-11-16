using UnityEngine;

namespace ZenoFit.Scoring
{
    /// <summary>
    /// Pure C# scoring formulas (08-scoring-and-results.md §7.1, AT-07, AT-08).
    /// Formulas:
    ///   accuracy_% = 100 * hits / total_targets
    ///   timeliness = max(0, 1 - t_hit / lifetime_s)
    ///   points_hit = 100 + floor(50 * timeliness)  (+25 bonus for solid boxing hit)
    ///   lifetime_s = L_beats * (60 / BPM)
    /// GP-SCORE-01: Depends only on hand/arm interactions. Never penalizes posture or lower body.
    /// GP-SCORE-02: Misses award 0 points and never subtract points.
    /// </summary>
    public static class ScoreCalculator
    {
        public const int DefaultBasePoints = 100;
        public const int DefaultMaxTimelinessBonus = 50;
        public const int DefaultBoxingSolidBonus = 25;

        public static float ComputeLifetimeSeconds(int lifetimeBeats, float bpm)
        {
            return Mathf.Max(1, lifetimeBeats) * (60f / Mathf.Max(1f, bpm));
        }

        public static float ComputeTimeliness(float hitTimeSeconds, float lifetimeSeconds)
        {
            if (lifetimeSeconds <= 0f)
                return 0f;

            float clampedHitTime = Mathf.Max(0f, hitTimeSeconds);
            return Mathf.Max(0f, 1f - (clampedHitTime / lifetimeSeconds));
        }

        public static int ComputeHitPoints(
            float hitTimeSeconds,
            float lifetimeSeconds,
            bool isSolidBoxingHit = false,
            int basePoints = DefaultBasePoints,
            int maxTimelinessBonus = DefaultMaxTimelinessBonus,
            int boxingSolidBonus = DefaultBoxingSolidBonus)
        {
            float timeliness = ComputeTimeliness(hitTimeSeconds, lifetimeSeconds);
            // Add a tiny epsilon (1e-5f) before FloorToInt to avoid IEEE-754 float precision issues (e.g., 50 * 0.80 = 39.999996)
            int rhythmBonus = Mathf.FloorToInt((maxTimelinessBonus * timeliness) + 1e-5f);
            int solidBonus = isSolidBoxingHit ? boxingSolidBonus : 0;
            return basePoints + rhythmBonus + solidBonus;
        }

        public static float ComputeAccuracyPercent(int hits, int totalTargets)
        {
            if (totalTargets <= 0)
                return 0f;

            return (100f * Mathf.Max(0, hits)) / totalTargets;
        }
    }
}

