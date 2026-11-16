using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Safety
{
    /// <summary>
    /// Pure C# timer for periodic shoulder/neck rest reminders (09-safety.md §8.3).
    /// Default: every 8 minutes (range 7–10 minutes [S]).
    /// </summary>
    public class RestReminderMonitor
    {
        public const float DefaultIntervalMinutes = 8.0f;
        public const string RestReminderMessage = "Relax your shoulders and neck. Take a moment to rest before continuing.";

        private float _intervalSeconds;
        private float _elapsedActiveSeconds;

        public float ElapsedActiveSeconds => _elapsedActiveSeconds;
        public float IntervalSeconds => _intervalSeconds;

        public RestReminderMonitor(float intervalMinutes = DefaultIntervalMinutes)
        {
            SetIntervalMinutes(intervalMinutes);
        }

        public void SetIntervalMinutes(float intervalMinutes)
        {
            float clampedMinutes = Mathf.Clamp(intervalMinutes, 7.0f, 10.0f);
            _intervalSeconds = clampedMinutes * 60f;
        }

        public void Reset()
        {
            _elapsedActiveSeconds = 0f;
        }

        public bool Tick(float deltaTime)
        {
            _elapsedActiveSeconds += Mathf.Max(0f, deltaTime);
            if (_elapsedActiveSeconds >= _intervalSeconds)
            {
                _elapsedActiveSeconds = 0f;
                EventBus.PublishRestDue();
                return true;
            }
            return false;
        }
    }
}

