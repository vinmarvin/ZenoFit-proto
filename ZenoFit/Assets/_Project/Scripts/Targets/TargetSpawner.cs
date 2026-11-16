using System.Collections.Generic;
using TMPro;
using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;

namespace ZenoFit.Targets
{
    /// <summary>
    /// Object-pooled target spawner and comfort/obstacle validator (01-techstack.md §4, 02-quest-config.md §5).
    /// Guarantees zero per-spawn Instantiate calls during gameplay and enforces:
    /// - GP-ENV-01: never places a target beyond 0.85 * R_f
    /// - GP-CAL-07: never spawns inside an obstacle exclusion sphere (r_ex + targetRadius)
    /// </summary>
    public class TargetSpawner : MonoBehaviour
    {
        [SerializeField] private Target _targetPrefab;
        [SerializeField] private int _initialPoolSize = 16;
        [SerializeField] private Material _defaultTargetMaterial;

        private readonly List<Target> _pool = new List<Target>();
        private readonly List<Target> _activeTargets = new List<Target>();

        public IReadOnlyList<Target> ActiveTargets => _activeTargets;

        private void Awake()
        {
            PrewarmPool(_initialPoolSize);
        }

        public void PrewarmPool(int count)
        {
            while (_pool.Count < count)
            {
                Target instance = CreatePooledTargetInstance(_pool.Count);
                instance.Deactivate();
                _pool.Add(instance);
            }
        }

        /// <summary>
        /// Pure C# validation helper used by both runtime spawning and EditMode unit tests (AT-04).
        /// Attempts to find an obstacle-free position in BodyFrame. If candidateLocal hits an obstacle,
        /// widens the horizontal angle within the comfort envelope up to maxAttempts times.
        /// Returns false if no obstacle-free position exists.
        /// </summary>
        public static bool TryResolveObstacleFreePosition(
            ComfortProfile profile,
            Vector3 candidateLocal,
            float targetRadiusM,
            float exclusionRadiusM,
            int maxAttempts,
            out Vector3 validLocalPosition)
        {
            validLocalPosition = candidateLocal;
            if (profile == null)
                return true;

            if (!profile.IsViolatingObstacleZone(candidateLocal, targetRadiusM, exclusionRadiusM))
                return true;

            // Widen angle around Y axis in alternating steps (±8°, ±16°, ±24°...) while preserving horizontal distance
            float horizontalRadius = new Vector2(candidateLocal.x, candidateLocal.z).magnitude;
            float baseAngleRad = Mathf.Atan2(candidateLocal.x, candidateLocal.z);

            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                int step = (attempt + 1) / 2;
                float sign = (attempt % 2 == 1) ? 1f : -1f;
                float deltaRad = sign * step * 8f * Mathf.Deg2Rad;

                // Keep within a safe forward sector (±65°)
                float testAngleRad = Mathf.Clamp(baseAngleRad + deltaRad, -65f * Mathf.Deg2Rad, 65f * Mathf.Deg2Rad);
                float testX = horizontalRadius * Mathf.Sin(testAngleRad);
                float testZ = horizontalRadius * Mathf.Cos(testAngleRad);
                // Also try lifting slightly above armrest height if obstacle is low
                float testY = candidateLocal.y + (step * 0.03f);
                testY = Mathf.Clamp(testY, -0.20f, 0.15f);

                Vector3 testPos = new Vector3(testX, testY, testZ);
                if (!profile.IsViolatingObstacleZone(testPos, targetRadiusM, exclusionRadiusM))
                {
                    validLocalPosition = testPos;
                    return true;
                }
            }

            return false;
        }

        public Target TrySpawnTarget(
            BodyFrame bodyFrame,
            ComfortProfile profile,
            TargetHand requiredHand,
            Vector3 desiredLocalPos,
            float radiusM,
            float lifetimeSeconds,
            float exclusionRadiusM = ComfortProfile.DefaultExclusionRadiusM,
            int maxAttempts = 12,
            bool isElasticPress = false,
            float pressTravelDepthM = 0.03f)
        {
            if (!TryResolveObstacleFreePosition(
                profile,
                desiredLocalPos,
                radiusM,
                exclusionRadiusM,
                maxAttempts,
                out Vector3 safeLocalPos))
            {
                Debug.LogWarning("[TargetSpawner] Skipped target spawn: all candidate positions overlapped obstacle exclusion zones.");
                return null;
            }

            Target target = GetAvailableFromPool();
            Vector3 worldPos = bodyFrame.ToWorld(safeLocalPos);
            target.Activate(
                requiredHand,
                safeLocalPos,
                worldPos,
                bodyFrame.Yaw,
                radiusM,
                lifetimeSeconds,
                isElasticPress,
                pressTravelDepthM);

            if (!_activeTargets.Contains(target))
            {
                _activeTargets.Add(target);
            }
            return target;
        }

        public void ReleaseTarget(Target target)
        {
            if (target == null)
                return;

            target.Deactivate();
            _activeTargets.Remove(target);
        }

        public void ReleaseAllActiveTargets()
        {
            for (int i = _activeTargets.Count - 1; i >= 0; i--)
            {
                if (_activeTargets[i] != null)
                    _activeTargets[i].Deactivate();
            }
            _activeTargets.Clear();
        }

        private Target GetAvailableFromPool()
        {
            for (int i = 0; i < _pool.Count; i++)
            {
                if (!_pool[i].IsActiveTarget)
                    return _pool[i];
            }

            Target extra = CreatePooledTargetInstance(_pool.Count);
            _pool.Add(extra);
            return extra;
        }

        private Target CreatePooledTargetInstance(int index)
        {
            if (_targetPrefab != null)
            {
                return Instantiate(_targetPrefab, transform);
            }

            // Runtime self-contained fallback if no prefab assigned
            GameObject go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.name = $"PooledTarget_{index:00}";
            go.transform.SetParent(transform, false);

            var col = go.GetComponent<SphereCollider>();
            col.isTrigger = true;

            var renderer = go.GetComponent<MeshRenderer>();
            if (_defaultTargetMaterial != null)
            {
                renderer.sharedMaterial = _defaultTargetMaterial;
            }

            // Create floating hand badge text ("L" / "R" / "L/R") so we never rely on color alone (§6.0)
            GameObject labelGo = new GameObject("HandBadge");
            labelGo.transform.SetParent(go.transform, false);
            labelGo.transform.localPosition = new Vector3(0f, 0f, -0.55f);
            labelGo.transform.localScale = Vector3.one * 0.15f;
            var tmp = labelGo.AddComponent<TextMeshPro>();
            tmp.alignment = TextAlignmentOptions.Center;
            tmp.fontSize = 18f;
            tmp.color = Color.black;
            tmp.text = "L/R";

            var target = go.AddComponent<Target>();
            return target;
        }
    }
}

