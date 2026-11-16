using System;
using UnityEngine;

namespace ZenoFit.Calibration
{
    /// <summary>
    /// Calibrated user coordinate system (01-body-frame-and-calibration.md §3).
    /// Origin = chest point C in tracking space.
    /// +Z = horizontal forward direction user faces at calibration.
    /// +Y = world up.
    /// +X = right = cross(up, forward).
    /// </summary>
    [Serializable]
    public struct BodyFrame
    {
        public Vector3 Origin;      // chest point C (in tracking space)
        public Quaternion Yaw;      // rotation about world-up so +Z = user forward

        public BodyFrame(Vector3 origin, Quaternion yaw)
        {
            Origin = origin;
            Yaw = yaw;
        }

        public Vector3 ToWorld(Vector3 local) => Origin + Yaw * local;

        public Vector3 ToLocal(Vector3 world) => Quaternion.Inverse(Yaw) * (world - Origin);

        public Vector3 DirectionToWorld(Vector3 localDirection) => Yaw * localDirection;

        public Vector3 DirectionToLocal(Vector3 worldDirection) => Quaternion.Inverse(Yaw) * worldDirection;

        public static Quaternion ComputeHorizontalYaw(Vector3 headForwardWorld)
        {
            Vector3 flatForward = new Vector3(headForwardWorld.x, 0f, headForwardWorld.z);
            if (flatForward.sqrMagnitude < 0.0001f)
            {
                flatForward = Vector3.forward;
            }
            else
            {
                flatForward.Normalize();
            }
            return Quaternion.LookRotation(flatForward, Vector3.up);
        }

        public static BodyFrame FromHeadAndChest(Vector3 headWorldPosition, Vector3 headWorldForward, Vector3 chestWorldPosition)
        {
            Quaternion yaw = ComputeHorizontalYaw(headWorldForward);
            return new BodyFrame(chestWorldPosition, yaw);
        }

        public static BodyFrame FromHeadWithDefaultChest(Vector3 headWorldPosition, Vector3 headWorldForward, float chestBelowHeadM = 0.25f)
        {
            Quaternion yaw = ComputeHorizontalYaw(headWorldForward);
            Vector3 defaultChestWorld = headWorldPosition - new Vector3(0f, Mathf.Abs(chestBelowHeadM), 0f);
            return new BodyFrame(defaultChestWorld, yaw);
        }

        /// <summary>
        /// Re-derives the BodyFrame after a headset recenter using the new head pose and saved chest offset (GP-CAL-06).
        /// </summary>
        public static BodyFrame RebuildFromHeadAndSavedOffset(Vector3 headWorldPosition, Vector3 headWorldForward, Vector3 chestOffsetFromHeadLocal)
        {
            Quaternion yaw = ComputeHorizontalYaw(headWorldForward);
            Vector3 chestWorld = headWorldPosition + yaw * chestOffsetFromHeadLocal;
            return new BodyFrame(chestWorld, yaw);
        }
    }
}

