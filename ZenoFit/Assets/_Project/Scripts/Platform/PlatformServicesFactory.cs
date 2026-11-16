using System;

namespace ZenoFit.Platform
{
    /// <summary>
    /// Selects and provides the active IPlatformServices implementation (01-techstack.md §3.2).
    /// </summary>
    public static class PlatformServicesFactory
    {
        private static Func<IPlatformServices> _deviceFactory;
        private static IPlatformServices _current;

        public static IPlatformServices Current
        {
            get
            {
                if (_current == null)
                {
                    _current = Create();
                    _current.Initialize();
                }
                return _current;
            }
            set => _current = value;
        }

        public static void RegisterDeviceFactory(Func<IPlatformServices> factory)
        {
            _deviceFactory = factory;
        }

        public static IPlatformServices Create()
        {
#if PLATFORM_QUEST && !UNITY_EDITOR
            if (_deviceFactory != null)
            {
                return _deviceFactory.Invoke();
            }
#endif
            return new EditorSimPlatform();
        }
    }
}

