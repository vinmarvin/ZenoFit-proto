using UnityEngine;

namespace ZenoFit.Targets
{
    /// <summary>
    /// Pure C# 3-frame smoothed velocity tracker for Seated Boxing (07-ex-seated-boxing.md §6.6, AT-12).
    /// Formula: v = |hand_pos(t) - hand_pos(t - dt)| / dt, smoothed over the last 3 frames.
    /// Zero allocations in Update.
    /// </summary>
    public class HandVelocityTracker
    {
        private readonly float[] _speedRingBuffer = new float[3];
        private int _sampleCount;
        private int _writeIndex;
        private Vector3 _previousPosition;
        private bool _hasPreviousPosition;

        public float CurrentSmoothedSpeedMps { get; private set; }
        public Vector3 PreviousPosition => _previousPosition;
        public Vector3 CurrentPosition { get; private set; }

        public void Reset(Vector3 initialPosition)
        {
            _previousPosition = initialPosition;
            CurrentPosition = initialPosition;
            _hasPreviousPosition = true;
            _sampleCount = 0;
            _writeIndex = 0;
            CurrentSmoothedSpeedMps = 0f;
            for (int i = 0; i < _speedRingBuffer.Length; i++)
                _speedRingBuffer[i] = 0f;
        }

        public float RecordFrame(Vector3 currentPosition, float deltaTime)
        {
            if (!_hasPreviousPosition)
            {
                Reset(currentPosition);
                return 0f;
            }

            float instantaneousSpeed = 0f;
            if (deltaTime > 1e-5f)
            {
                instantaneousSpeed = Vector3.Distance(currentPosition, _previousPosition) / deltaTime;
            }

            _previousPosition = CurrentPosition;
            CurrentPosition = currentPosition;

            _speedRingBuffer[_writeIndex] = instantaneousSpeed;
            _writeIndex = (_writeIndex + 1) % _speedRingBuffer.Length;
            if (_sampleCount < _speedRingBuffer.Length)
                _sampleCount++;

            float sum = 0f;
            for (int i = 0; i < _sampleCount; i++)
                sum += _speedRingBuffer[i];

            CurrentSmoothedSpeedMps = _sampleCount > 0 ? sum / _sampleCount : 0f;
            return CurrentSmoothedSpeedMps;
        }
    }
}

