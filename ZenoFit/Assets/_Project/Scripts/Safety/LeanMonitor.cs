using UnityEngine;

namespace ZenoFit.Safety
{
    /// <summary>
    /// Pure C# evaluator for lateral lean / wheelchair balance warning (09-safety.md §8.4 GP-SAFE-LEAN-01, AT-10).
    /// Formula:
    ///   Δx = x_head - x_SeatAnchor (in BodyFrame)
    ///   if |Δx| > 0.20 m for >= 0.5 s -> soft pause + "Please sit back in a stable position."
    /// </summary>
    public class LeanMonitor
    {
        public const float DefaultLeanThresholdM = 0.20f;
        public const float DefaultHoldSeconds = 0.5f;
        public const string LeanWarningMessage = "Please sit back in a stable position.";

        private readonly float _leanThresholdM;
        private readonly float _holdSeconds;
        private float _accumulatedLeanSeconds;

        public float AccumulatedLeanSeconds => _accumulatedLeanSeconds;

        public LeanMonitor(
            float leanThresholdM = DefaultLeanThresholdM,
            float holdSeconds = DefaultHoldSeconds)
        {
            _leanThresholdM = Mathf.Max(0.05f, leanThresholdM);
            _holdSeconds = Mathf.Max(0.05f, holdSeconds);
        }

        public void Reset()
        {
            _accumulatedLeanSeconds = 0f;
        }

        public bool Evaluate(float headLocalX, float seatAnchorLocalX, float deltaTime)
        {
            float deltaX = Mathf.Abs(headLocalX - seatAnchorLocalX);
            if (deltaX > _leanThresholdM)
            {
                _accumulatedLeanSeconds += Mathf.Max(0f, deltaTime);
                if (_accumulatedLeanSeconds >= _holdSeconds - 1e-5f)
                {
                    return true;
                }
            }
            else
            {
                _accumulatedLeanSeconds = 0f;
            }

            return false;
        }
    }
}

