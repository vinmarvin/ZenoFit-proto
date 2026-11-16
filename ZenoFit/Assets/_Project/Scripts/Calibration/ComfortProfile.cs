using System;
using System.Collections.Generic;
using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Calibration
{
    [Serializable]
    public class HandCalibrationData
    {
        public bool enabled = true;
        public float reachForwardM = 0.55f;
        public float armLengthM = 0.60f;
    }

    [Serializable]
    public struct ObstaclePoint
    {
        public float x;
        public float y;
        public float z;

        public ObstaclePoint(float x, float y, float z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
        }

        public ObstaclePoint(Vector3 v)
        {
            x = v.x;
            y = v.y;
            z = v.z;
        }

        public Vector3 ToVector3() => new Vector3(x, y, z);
    }

    /// <summary>
    /// Calibrated comfort envelope and obstacle profile (01-body-frame-and-calibration.md §4.3–§4.6).
    /// Matches exact JSON schema in §4.6 GP-CAL-08.
    /// </summary>
    [Serializable]
    public class ComfortProfile
    {
        public const float HardMaxReachFactor = 0.85f;
        public const float DefaultExclusionRadiusM = 0.12f;

        public int version = 1;
        public string createdUtc = "2026-11-12T00:00:00Z";
        public float shoulderWidthM = 0.40f;
        public HandCalibrationData leftHand = new HandCalibrationData { enabled = true, reachForwardM = 0.55f, armLengthM = 0.60f };
        public HandCalibrationData rightHand = new HandCalibrationData { enabled = true, reachForwardM = 0.55f, armLengthM = 0.60f };
        public float[] chestOffsetFromHeadM = new float[] { 0.0f, -0.25f, 0.08f };
        public float[] lapPointFromChestM = new float[] { 0.0f, -0.45f, 0.20f };
        public List<ObstaclePoint> obstacles = new List<ObstaclePoint>();

        public Vector3 GetChestOffsetFromHead()
        {
            if (chestOffsetFromHeadM != null && chestOffsetFromHeadM.Length >= 3)
                return new Vector3(chestOffsetFromHeadM[0], chestOffsetFromHeadM[1], chestOffsetFromHeadM[2]);
            return new Vector3(0f, -0.25f, 0.08f);
        }

        public void SetChestOffsetFromHead(Vector3 offset)
        {
            chestOffsetFromHeadM = new float[] { offset.x, offset.y, offset.z };
        }

        public Vector3 GetLapPointLocal()
        {
            if (lapPointFromChestM != null && lapPointFromChestM.Length >= 3)
                return new Vector3(lapPointFromChestM[0], lapPointFromChestM[1], lapPointFromChestM[2]);
            return new Vector3(0f, -0.45f, 0.20f);
        }

        public void SetLapPointLocal(Vector3 lapLocal)
        {
            lapPointFromChestM = new float[] { lapLocal.x, lapLocal.y, lapLocal.z };
        }

        public HandCalibrationData GetHandData(Hand hand)
        {
            return hand == Hand.Left ? leftHand : rightHand;
        }

        public bool IsHandEnabled(Hand hand)
        {
            return GetHandData(hand).enabled;
        }

        /// <summary>
        /// Computes forward target depth R_target(hand) = k * R_f,hand in BodyFrame metres (§4.3, AT-01).
        /// GP-ENV-01: Never places a target beyond 0.85 * R_f of the hand that must touch it.
        /// </summary>
        public float GetTargetForwardDistance(Hand hand, float reachFactorK)
        {
            float clampedK = Mathf.Clamp(reachFactorK, 0.05f, HardMaxReachFactor);
            float reach = Mathf.Max(0.15f, GetHandData(hand).reachForwardM);
            return clampedK * reach;
        }

        /// <summary>
        /// For two-hand shared targets (e.g. Forward Press §6.5), uses the smaller R_f of enabled hands
        /// so neither hand is asked to reach beyond its comfort envelope.
        /// </summary>
        public float GetSharedForwardDistance(float reachFactorK, HandMode handMode)
        {
            float clampedK = Mathf.Clamp(reachFactorK, 0.05f, HardMaxReachFactor);
            bool useLeft = leftHand.enabled && handMode != HandMode.RightOnly;
            bool useRight = rightHand.enabled && handMode != HandMode.LeftOnly;

            if (useLeft && useRight)
            {
                float minReach = Mathf.Min(Mathf.Max(0.15f, leftHand.reachForwardM), Mathf.Max(0.15f, rightHand.reachForwardM));
                return clampedK * minReach;
            }
            if (useLeft)
                return GetTargetForwardDistance(Hand.Left, clampedK);
            if (useRight)
                return GetTargetForwardDistance(Hand.Right, clampedK);

            return clampedK * 0.50f;
        }

        /// <summary>
        /// Clamps alternating reach target spacing w = clamp(W, 0.35, 0.50) m (§6.2).
        /// </summary>
        public float GetClampedShoulderSpacing()
        {
            return Mathf.Clamp(shoulderWidthM, 0.35f, 0.50f);
        }

        /// <summary>
        /// Shoulder position in BodyFrame local coordinates.
        /// </summary>
        public Vector3 GetShoulderLocalPosition(Hand hand)
        {
            float halfW = Mathf.Max(0.10f, shoulderWidthM) * 0.5f;
            float x = hand == Hand.Right ? halfW : -halfW;
            return new Vector3(x, 0f, 0f);
        }

        /// <summary>
        /// Checks whether candidate position T (in BodyFrame) violates any obstacle exclusion sphere (§4.5, AT-04).
        /// </summary>
        public bool IsViolatingObstacleZone(Vector3 candidateLocal, float targetRadiusM, float exclusionRadiusM = DefaultExclusionRadiusM)
        {
            if (obstacles == null || obstacles.Count == 0)
                return false;

            float minAllowedDist = Mathf.Max(0f, exclusionRadiusM) + Mathf.Max(0f, targetRadiusM);
            float minAllowedSqr = minAllowedDist * minAllowedDist;

            for (int i = 0; i < obstacles.Count; i++)
            {
                Vector3 obs = obstacles[i].ToVector3();
                if ((candidateLocal - obs).sqrMagnitude < minAllowedSqr)
                    return true;
            }
            return false;
        }

        public bool IsValid()
        {
            return (leftHand != null && leftHand.enabled && leftHand.reachForwardM > 0.1f)
                || (rightHand != null && rightHand.enabled && rightHand.reachForwardM > 0.1f);
        }

        public static ComfortProfile CreateDefault()
        {
            return new ComfortProfile
            {
                version = 1,
                createdUtc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"),
                shoulderWidthM = 0.40f,
                leftHand = new HandCalibrationData { enabled = true, reachForwardM = 0.55f, armLengthM = 0.60f },
                rightHand = new HandCalibrationData { enabled = true, reachForwardM = 0.55f, armLengthM = 0.60f },
                chestOffsetFromHeadM = new float[] { 0.0f, -0.25f, 0.08f },
                lapPointFromChestM = new float[] { 0.0f, -0.45f, 0.20f },
                obstacles = new List<ObstaclePoint>()
            };
        }
    }
}

