using System;
using ZenoFit.Core;

namespace ZenoFit.Platform
{
    /// <summary>
    /// Platform abstraction isolating Quest-specific features (passthrough, haptics, recenter)
    /// from gameplay, calibration, UI, and safety code (01-techstack.md §3.2, D-06).
    /// </summary>
    public interface IPlatformServices
    {
        string DeviceName { get; }
        bool SupportsPassthrough { get; }

        void Initialize();
        void SetPassthrough(bool enabled);              // no-op if unsupported
        void PlayHaptic(Hand hand, float amplitude01, float durationSeconds);
        event Action TrackingOriginRecentered;          // fires when the user recenters the headset
    }
}

