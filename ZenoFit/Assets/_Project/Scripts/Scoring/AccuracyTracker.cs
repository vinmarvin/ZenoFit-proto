using ZenoFit.Core;

namespace ZenoFit.Scoring
{
    /// <summary>
    /// Tracks hits, misses, score, and accuracy for a round or session (08-scoring-and-results.md §7.1–§7.2).
    /// </summary>
    public class AccuracyTracker
    {
        private readonly int _basePoints;
        private readonly int _maxTimelinessBonus;
        private readonly int _boxingSolidBonus;

        public int Hits { get; private set; }
        public int Misses { get; private set; }
        public int TotalScore { get; private set; }
        public int TotalTargets => Hits + Misses;
        public float AccuracyPercent => ScoreCalculator.ComputeAccuracyPercent(Hits, TotalTargets);

        public AccuracyTracker(
            int basePoints = ScoreCalculator.DefaultBasePoints,
            int maxTimelinessBonus = ScoreCalculator.DefaultMaxTimelinessBonus,
            int boxingSolidBonus = ScoreCalculator.DefaultBoxingSolidBonus)
        {
            _basePoints = basePoints;
            _maxTimelinessBonus = maxTimelinessBonus;
            _boxingSolidBonus = boxingSolidBonus;
        }

        public void Reset()
        {
            Hits = 0;
            Misses = 0;
            TotalScore = 0;
        }

        public int RecordHit(Hand hand, float hitTimeSeconds, float lifetimeSeconds, bool isSolidBoxingHit = false)
        {
            int points = ScoreCalculator.ComputeHitPoints(
                hitTimeSeconds,
                lifetimeSeconds,
                isSolidBoxingHit,
                _basePoints,
                _maxTimelinessBonus,
                _boxingSolidBonus);

            Hits++;
            TotalScore += points;

            EventBus.PublishTargetHit(new TargetHitEvent(
                hand,
                points,
                hitTimeSeconds,
                isSolidBoxingHit,
                TotalScore,
                AccuracyPercent));

            return points;
        }

        public void RecordMiss(TargetHand expectedHand = TargetHand.Either)
        {
            // GP-SCORE-02: Missed targets give 0 points and never subtract points
            Misses++;
            EventBus.PublishTargetMissed(new TargetMissedEvent(
                expectedHand,
                Misses,
                AccuracyPercent));
        }
    }
}

