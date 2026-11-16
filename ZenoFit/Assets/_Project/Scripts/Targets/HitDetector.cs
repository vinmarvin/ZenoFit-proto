using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Targets
{
    /// <summary>
    /// Pure C# segment-to-sphere anti-tunnelling hit detection (02-targets-and-hit-detection.md §6.7 GP-HIT-01, AT-13).
    /// At 72 Hz a fast hand can move several centimetres per frame; this checks the line segment P0 → P1
    /// against the target sphere (targetRadius + handTipRadius).
    /// </summary>
    public static class HitDetector
    {
        public const float DefaultHandTipRadiusM = 0.04f;

        /// <summary>
        /// Computes the shortest Euclidean distance from a point T to the line segment [segStart, segEnd].
        /// </summary>
        public static float DistancePointToSegment(Vector3 point, Vector3 segStart, Vector3 segEnd)
        {
            Vector3 ab = segEnd - segStart;
            float abLenSqr = ab.sqrMagnitude;
            if (abLenSqr < 1e-8f)
            {
                return Vector3.Distance(point, segStart);
            }

            float t = Vector3.Dot(point - segStart, ab) / abLenSqr;
            t = Mathf.Clamp01(t);
            Vector3 closest = segStart + t * ab;
            return Vector3.Distance(point, closest);
        }

        /// <summary>
        /// Checks whether a hand tip moving from prevPos to currPos intersects the target sphere.
        /// </summary>
        public static bool IsSegmentHit(
            Vector3 targetCenter,
            float targetRadiusM,
            Vector3 prevHandTipPos,
            Vector3 currHandTipPos,
            float handTipRadiusM = DefaultHandTipRadiusM)
        {
            float combinedRadius = Mathf.Max(0f, targetRadiusM) + Mathf.Max(0f, handTipRadiusM);
            float dist = DistancePointToSegment(targetCenter, prevHandTipPos, currHandTipPos);
            return dist <= combinedRadius;
        }

        /// <summary>
        /// Evaluates a candidate hand interaction against hand-mode, calibration enabled flags,
        /// and target hand assignment (GP-HAND-01, GP-SCORE-03, AT-11).
        /// Wrong-hand touches and disabled hands are ignored (return false, no penalty).
        /// </summary>
        public static bool TryCheckValidHandHit(
            Hand candidateHand,
            bool isCandidateHandEnabled,
            HandMode activeHandMode,
            TargetHand targetRequiredHand,
            Vector3 targetCenter,
            float targetRadiusM,
            Vector3 prevHandTipPos,
            Vector3 currHandTipPos,
            float handTipRadiusM = DefaultHandTipRadiusM)
        {
            if (!isCandidateHandEnabled)
                return false;

            if (activeHandMode == HandMode.LeftOnly && candidateHand != Hand.Left)
                return false;
            if (activeHandMode == HandMode.RightOnly && candidateHand != Hand.Right)
                return false;

            if (targetRequiredHand == TargetHand.Left && candidateHand != Hand.Left)
                return false;
            if (targetRequiredHand == TargetHand.Right && candidateHand != Hand.Right)
                return false;

            return IsSegmentHit(targetCenter, targetRadiusM, prevHandTipPos, currHandTipPos, handTipRadiusM);
        }
    }
}

