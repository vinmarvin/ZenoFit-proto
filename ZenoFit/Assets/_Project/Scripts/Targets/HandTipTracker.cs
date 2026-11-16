using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Targets
{
    /// <summary>
    /// Attached to each controller's HandTip sphere (radius = 0.04 m [P], 02-quest-config.md §2 Step 9).
    /// Tracks previous and current world positions per frame and smoothed speed for Seated Boxing.
    /// </summary>
    [RequireComponent(typeof(SphereCollider))]
    public class HandTipTracker : MonoBehaviour
    {
        [SerializeField] private Hand _hand = Hand.Left;
        [SerializeField] private float _tipRadiusM = HitDetector.DefaultHandTipRadiusM;

        private readonly HandVelocityTracker _velocityTracker = new HandVelocityTracker();
        private Vector3 _previousWorldPosition;
        private Vector3 _currentWorldPosition;
        private SphereCollider _sphereCollider;

        public Hand Hand => _hand;
        public float TipRadiusM => _tipRadiusM;
        public Vector3 PreviousWorldPosition => _previousWorldPosition;
        public Vector3 CurrentWorldPosition => _currentWorldPosition;
        public float SmoothedSpeedMps => _velocityTracker.CurrentSmoothedSpeedMps;

        public void Configure(Hand hand, float tipRadiusM = HitDetector.DefaultHandTipRadiusM)
        {
            _hand = hand;
            _tipRadiusM = Mathf.Max(0.01f, tipRadiusM);
            if (_sphereCollider == null)
                _sphereCollider = GetComponent<SphereCollider>();
            if (_sphereCollider != null)
            {
                _sphereCollider.isTrigger = true;
                _sphereCollider.radius = _tipRadiusM;
            }
        }

        private void Awake()
        {
            _sphereCollider = GetComponent<SphereCollider>();
            _sphereCollider.isTrigger = true;
            _sphereCollider.radius = _tipRadiusM;

            _currentWorldPosition = transform.position;
            _previousWorldPosition = _currentWorldPosition;
            _velocityTracker.Reset(_currentWorldPosition);
        }

        private void OnEnable()
        {
            _currentWorldPosition = transform.position;
            _previousWorldPosition = _currentWorldPosition;
            _velocityTracker.Reset(_currentWorldPosition);
        }

        private void Update()
        {
            _previousWorldPosition = _currentWorldPosition;
            _currentWorldPosition = transform.position;
            _velocityTracker.RecordFrame(_currentWorldPosition, Time.deltaTime);
        }
    }
}

