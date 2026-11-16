using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Scoring
{
    /// <summary>
    /// Pure C# adaptive tempo controller (02-targets-and-hit-detection.md §6.4, GP-DIFF-02, AT-05, AT-06).
    /// Formula:
    ///   interval_s = 60 / BPM
    ///   window     = last 8 targets
    ///   accuracy   = hits / targets_in_window
    ///   if accuracy >= 0.85 -> BPM += 5 (never above preset max)
    ///   if accuracy <  0.60 -> BPM -= 5 (never below 40)
    ///   otherwise           -> hold
    /// </summary>
    public class AdaptiveTempo
    {
        public const int DefaultWindowSize = 8;
        public const float DefaultIncreaseThreshold = 0.85f;
        public const float DefaultDecreaseThreshold = 0.60f;
        public const float DefaultStepBpm = 5f;
        public const float DefaultMinBpm = 40f;

        private readonly int _windowSize;
        private readonly float _increaseThreshold;
        private readonly float _decreaseThreshold;
        private readonly float _stepBpm;
        private readonly float _minBpm;
        private float _maxBpm;

        private int _targetsInCurrentWindow;
        private int _hitsInCurrentWindow;

        public float CurrentBpm { get; private set; }
        public float MaxBpmReached { get; private set; }
        public float BeatIntervalSeconds => GetBeatIntervalSeconds(CurrentBpm);

        public AdaptiveTempo(
            float startBpm = 60f,
            float maxBpm = 80f,
            int windowSize = DefaultWindowSize,
            float increaseThreshold = DefaultIncreaseThreshold,
            float decreaseThreshold = DefaultDecreaseThreshold,
            float stepBpm = DefaultStepBpm,
            float minBpm = DefaultMinBpm)
        {
            _windowSize = Mathf.Max(1, windowSize);
            _increaseThreshold = Mathf.Clamp01(increaseThreshold);
            _decreaseThreshold = Mathf.Clamp01(decreaseThreshold);
            _stepBpm = Mathf.Max(1f, stepBpm);
            _minBpm = Mathf.Max(10f, minBpm);
            _maxBpm = Mathf.Max(startBpm, maxBpm);

            CurrentBpm = Mathf.Clamp(startBpm, _minBpm, _maxBpm);
            MaxBpmReached = CurrentBpm;
        }

        public static float GetBeatIntervalSeconds(float bpm)
        {
            return 60f / Mathf.Max(1f, bpm);
        }

        public void SetMaxBpmCap(float maxBpm)
        {
            _maxBpm = Mathf.Max(_minBpm, maxBpm);
            CurrentBpm = Mathf.Min(CurrentBpm, _maxBpm);
        }

        public bool RecordTargetOutcome(bool isHit)
        {
            _targetsInCurrentWindow++;
            if (isHit)
                _hitsInCurrentWindow++;

            if (_targetsInCurrentWindow >= _windowSize)
            {
                float oldBpm = CurrentBpm;
                EvaluateWindow(_hitsInCurrentWindow, _targetsInCurrentWindow);
                _targetsInCurrentWindow = 0;
                _hitsInCurrentWindow = 0;
                return !Mathf.Approximately(oldBpm, CurrentBpm);
            }

            return false;
        }

        /// <summary>
        /// Evaluates a completed window of targets and adjusts BPM according to §6.4 (AT-06).
        /// </summary>
        public float EvaluateWindow(int hits, int targetsInWindow)
        {
            if (targetsInWindow <= 0)
                return CurrentBpm;

            float accuracy = (float)hits / targetsInWindow;
            float previousBpm = CurrentBpm;

            if (accuracy >= _increaseThreshold)
            {
                CurrentBpm = Mathf.Min(_maxBpm, CurrentBpm + _stepBpm);
            }
            else if (accuracy < _decreaseThreshold)
            {
                CurrentBpm = Mathf.Max(_minBpm, CurrentBpm - _stepBpm);
            }

            if (CurrentBpm > MaxBpmReached)
            {
                MaxBpmReached = CurrentBpm;
            }

            if (!Mathf.Approximately(previousBpm, CurrentBpm))
            {
                EventBus.PublishTempoChanged(CurrentBpm);
            }

            return CurrentBpm;
        }
    }
}

