using UnityEngine;

namespace ZenoFit.Safety
{
    /// <summary>
    /// Pure C# evaluator for auto-pausing when hands rest in the lap (09-safety.md §8.1, AT-09).
    /// Formula:
    ///   lapDistance(hand) = |handTip - LapPoint|
    ///   if both hands have lapDistance <= 0.15 m for >= 2.0 s -> Pause + passthrough
    /// </summary>
    public class AutoPauseMonitor
    {
        public const float DefaultLapDistanceThresholdM = 0.15f;
        public const float DefaultHoldDurationSeconds = 2.0f;

        private readonly float _lapDistanceThresholdM;
        private readonly float _holdDurationSeconds;
        private float _accumulatedLapSeconds;

        public float AccumulatedLapSeconds => _accumulatedLapSeconds;

        public AutoPauseMonitor(
            float lapDistanceThresholdM = DefaultLapDistanceThresholdM,
            float holdDurationSeconds = DefaultHoldDurationSeconds)
        {
            _lapDistanceThresholdM = Mathf.Max(0.01f, lapDistanceThresholdM);
            _holdDurationSeconds = Mathf.Max(0.1f, holdDurationSeconds);
        }

        public void Reset()
        {
            _accumulatedLapSeconds = 0f;
        }

        /// <summary>
        /// Evaluates whether the active hand(s) are resting within the lap sphere for >= holdDurationSeconds (AT-09).
        /// Positions must be in the same coordinate frame (e.g. BodyFrame).
        /// </summary>
        public bool Evaluate(
            Vector3 leftHandLocal,
            Vector3 rightHandLocal,
            Vector3 lapPointLocal,
            float deltaTime,
            bool leftEnabled = true,
            bool rightEnabled = true)
        {
            bool leftInLap = !leftEnabled || Vector3.Distance(leftHandLocal, lapPointLocal) <= _lapDistanceThresholdM;
            bool rightInLap = !rightEnabled || Vector3.Distance(rightHandLocal, lapPointLocal) <= _lapDistanceThresholdM;

            if (leftInLap && rightInLap && (leftEnabled || rightEnabled))
            {
                _accumulatedLapSeconds += Mathf.Max(0f, deltaTime);
                if (_accumulatedLapSeconds >= _holdDurationSeconds - 1e-5f)
                {
                    return true;
                }
            }
            else
            {
                _accumulatedLapSeconds = 0f;
            }

            return false;
        }
    }
}

