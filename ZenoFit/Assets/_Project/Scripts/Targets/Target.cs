using System;
using TMPro;
using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Targets
{
    /// <summary>
    /// Pooled interactive target sphere in World/BodyFrame space (02-targets-and-hit-detection.md §6.0).
    /// Color + non-color label/ring indicator:
    /// - Left = Blue + "L"
    /// - Right = Orange + "R"
    /// - Either = White + "L/R"
    /// Supports both touch/reach spheres and elastic button travel depth (Forward Press §6.5).
    /// </summary>
    [RequireComponent(typeof(SphereCollider))]
    public class Target : MonoBehaviour
    {
        public static readonly Color LeftHandColor = new Color(0.20f, 0.62f, 0.98f, 1f);
        public static readonly Color RightHandColor = new Color(0.98f, 0.56f, 0.18f, 1f);
        public static readonly Color EitherHandColor = new Color(0.95f, 0.96f, 0.98f, 1f);

        [SerializeField] private MeshRenderer _meshRenderer;
        [SerializeField] private TMP_Text _handLabelText;
        [SerializeField] private Transform _ringIndicator;

        private SphereCollider _sphereCollider;
        private MaterialPropertyBlock _propBlock;

        public TargetHand RequiredHand { get; private set; }
        public Vector3 BaseLocalPosition { get; private set; }
        public Vector3 BaseWorldPosition { get; private set; }
        public float RadiusM { get; private set; }
        public float LifetimeSeconds { get; private set; }
        public float ElapsedSeconds { get; private set; }
        public bool IsActiveTarget { get; private set; }

        // Forward Press (§6.5) elastic button state
        public bool IsElasticPressTarget { get; private set; }
        public float PressTravelDepthM { get; private set; } = 0.03f;
        public float CurrentPressDepressionM { get; private set; }

        private void Awake()
        {
            _sphereCollider = GetComponent<SphereCollider>();
            _sphereCollider.isTrigger = true;
            _propBlock = new MaterialPropertyBlock();

            if (_meshRenderer == null)
                _meshRenderer = GetComponentInChildren<MeshRenderer>();
        }

        public void Activate(
            TargetHand requiredHand,
            Vector3 localPos,
            Vector3 worldPos,
            Quaternion worldRotation,
            float radiusM,
            float lifetimeSeconds,
            bool isElasticPress = false,
            float pressTravelDepthM = 0.03f)
        {
            RequiredHand = requiredHand;
            BaseLocalPosition = localPos;
            BaseWorldPosition = worldPos;
            RadiusM = Mathf.Max(0.02f, radiusM);
            LifetimeSeconds = Mathf.Max(0.1f, lifetimeSeconds);
            ElapsedSeconds = 0f;
            IsActiveTarget = true;
            IsElasticPressTarget = isElasticPress;
            PressTravelDepthM = Mathf.Max(0.01f, pressTravelDepthM);
            CurrentPressDepressionM = 0f;

            transform.SetPositionAndRotation(worldPos, worldRotation);
            float diameter = RadiusM * 2f;
            transform.localScale = new Vector3(diameter, diameter, isElasticPress ? diameter * 0.5f : diameter);

            if (_sphereCollider == null)
                _sphereCollider = GetComponent<SphereCollider>();
            _sphereCollider.radius = 0.5f; // Scaled by transform.localScale (diameter)

            ApplyVisualStyle(requiredHand);
            gameObject.SetActive(true);
        }

        public void UpdateElapsed(float deltaTime)
        {
            if (!IsActiveTarget)
                return;

            ElapsedSeconds += deltaTime;

            // Subtle lifetime progress ring scale (visual cue without relying on color alone)
            if (_ringIndicator != null && LifetimeSeconds > 0f)
            {
                float remainingRatio = Mathf.Clamp01(1f - (ElapsedSeconds / LifetimeSeconds));
                float ringScale = Mathf.Lerp(1.0f, 1.35f, remainingRatio);
                _ringIndicator.localScale = new Vector3(ringScale, ringScale, 1f);
            }
        }

        public void SetElasticDepression(float depressionM, Vector3 forwardWorldDir)
        {
            CurrentPressDepressionM = Mathf.Clamp(depressionM, 0f, PressTravelDepthM * 1.5f);
            transform.position = BaseWorldPosition + forwardWorldDir * CurrentPressDepressionM;
        }

        public void Deactivate()
        {
            IsActiveTarget = false;
            CurrentPressDepressionM = 0f;
            gameObject.SetActive(false);
        }

        private void ApplyVisualStyle(TargetHand hand)
        {
            Color targetColor;
            string handBadge;

            switch (hand)
            {
                case TargetHand.Left:
                    targetColor = LeftHandColor;
                    handBadge = "L";
                    break;
                case TargetHand.Right:
                    targetColor = RightHandColor;
                    handBadge = "R";
                    break;
                case TargetHand.Either:
                default:
                    targetColor = EitherHandColor;
                    handBadge = "L/R";
                    break;
            }

            if (_meshRenderer != null)
            {
                if (_propBlock == null)
                    _propBlock = new MaterialPropertyBlock();

                _meshRenderer.GetPropertyBlock(_propBlock);
                _propBlock.SetColor("_BaseColor", targetColor);
                _propBlock.SetColor("_Color", targetColor);
                _meshRenderer.SetPropertyBlock(_propBlock);
            }

            if (_handLabelText != null)
            {
                _handLabelText.text = handBadge;
            }
        }
    }
}

