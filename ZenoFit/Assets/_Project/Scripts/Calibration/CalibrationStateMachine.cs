using System;
using System.Collections.Generic;
using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Calibration
{
    public enum CalibrationStepId
    {
        Step1_SitAndLookForward = 1,
        Step2_TouchChest = 2,
        Step3_TouchShoulders = 3,
        Step4_ReachForwardLeft = 4,
        Step5_ReachForwardRight = 5,
        Step6_RestHandsInLap = 6,
        Step7_MarkObstacles = 7,
        Completed = 8
    }

    /// <summary>
    /// Pure C# logic for the 7-step seated calibration and 2-step quick recenter (01-body-frame-and-calibration.md §4.2, §4.4).
    /// Testable in EditMode without a headset.
    /// </summary>
    public class CalibrationStateMachine
    {
        public const string PainReminderMessage = "Stop if it hurts. Only reach as far as is comfortable.";

        public CalibrationStepId CurrentStep { get; private set; } = CalibrationStepId.Step1_SitAndLookForward;
        public bool IsQuickRecenterMode { get; private set; }

        public Vector3 CapturedHeadWorldPos { get; private set; }
        public Vector3 CapturedHeadWorldForward { get; private set; } = Vector3.forward;
        public BodyFrame CurrentBodyFrame { get; private set; }
        public Vector3 SeatAnchorLocal { get; private set; }

        private Vector3? _leftShoulderWorld;
        private Vector3? _rightShoulderWorld;
        private readonly float _defaultChestBelowHeadM;
        private readonly float _defaultShoulderWidthM;

        public ComfortProfile WorkingProfile { get; private set; }

        public CalibrationStateMachine(
            ComfortProfile existingProfile = null,
            float defaultChestBelowHeadM = 0.25f,
            float defaultShoulderWidthM = 0.40f)
        {
            _defaultChestBelowHeadM = defaultChestBelowHeadM;
            _defaultShoulderWidthM = defaultShoulderWidthM;
            WorkingProfile = existingProfile != null ? CloneProfile(existingProfile) : ComfortProfile.CreateDefault();
        }

        public void StartFullCalibration()
        {
            IsQuickRecenterMode = false;
            _leftShoulderWorld = null;
            _rightShoulderWorld = null;
            WorkingProfile.obstacles.Clear();
            WorkingProfile.leftHand.enabled = true;
            WorkingProfile.rightHand.enabled = true;
            SetStep(CalibrationStepId.Step1_SitAndLookForward);
        }

        /// <summary>
        /// GP-CAL-06: On recenter event, re-runs steps 1–2 only using saved reach/obstacle values.
        /// </summary>
        public void StartQuickRecenter()
        {
            IsQuickRecenterMode = true;
            SetStep(CalibrationStepId.Step1_SitAndLookForward);
        }

        /// <summary>
        /// GP-CAL-05: Allows the user to redo any single step.
        /// </summary>
        public void GoToStep(CalibrationStepId step)
        {
            if (step == CalibrationStepId.Step3_TouchShoulders)
            {
                _leftShoulderWorld = null;
                _rightShoulderWorld = null;
            }
            SetStep(step);
        }

        public bool CanSkipCurrentStep()
        {
            switch (CurrentStep)
            {
                case CalibrationStepId.Step1_SitAndLookForward:
                case CalibrationStepId.Step6_RestHandsInLap:
                    return false;
                case CalibrationStepId.Step2_TouchChest:
                case CalibrationStepId.Step3_TouchShoulders:
                case CalibrationStepId.Step4_ReachForwardLeft:
                case CalibrationStepId.Step5_ReachForwardRight:
                case CalibrationStepId.Step7_MarkObstacles:
                    return true;
                default:
                    return false;
            }
        }

        public string GetCurrentStepInstruction()
        {
            switch (CurrentStep)
            {
                case CalibrationStepId.Step1_SitAndLookForward:
                    return "Step 1/7: Sit comfortably and look straight ahead. Press Trigger to confirm.";
                case CalibrationStepId.Step2_TouchChest:
                    return "Step 2/7: Touch your chest (sternum) with a controller and press Trigger (or Skip for default).";
                case CalibrationStepId.Step3_TouchShoulders:
                    return _leftShoulderWorld == null
                        ? "Step 3/7 (a): Touch your LEFT shoulder and press Trigger (or Skip for default 0.40 m)."
                        : "Step 3/7 (b): Now touch your RIGHT shoulder and press Trigger.";
                case CalibrationStepId.Step4_ReachForwardLeft:
                    return $"Step 4/7: Reach forward with your LEFT hand as far as comfortable, no pain. Press Trigger (or Skip to disable left hand).\n{PainReminderMessage}";
                case CalibrationStepId.Step5_ReachForwardRight:
                    return $"Step 5/7: Reach forward with your RIGHT hand as far as comfortable, no pain. Press Trigger (or Skip to disable right hand).\n{PainReminderMessage}";
                case CalibrationStepId.Step6_RestHandsInLap:
                    return "Step 6/7: Rest your hand(s) comfortably in your lap and press Trigger.";
                case CalibrationStepId.Step7_MarkObstacles:
                    return $"Step 7/7: Touch any armrests or wheelchair rims to mark obstacle zones ({WorkingProfile.obstacles.Count} marked), or press Finish.";
                case CalibrationStepId.Completed:
                    return "Calibration Complete!";
                default:
                    return string.Empty;
            }
        }

        public void ConfirmStep1_SitAndLookForward(Vector3 headWorldPos, Vector3 headWorldForward)
        {
            if (CurrentStep != CalibrationStepId.Step1_SitAndLookForward)
                return;

            CapturedHeadWorldPos = headWorldPos;
            CapturedHeadWorldForward = headWorldForward;
            CurrentBodyFrame = BodyFrame.FromHeadWithDefaultChest(headWorldPos, headWorldForward, _defaultChestBelowHeadM);
            SeatAnchorLocal = CurrentBodyFrame.ToLocal(headWorldPos);

            SetStep(CalibrationStepId.Step2_TouchChest);
        }

        public void ConfirmStep2_TouchChest(Vector3 controllerWorldPos)
        {
            if (CurrentStep != CalibrationStepId.Step2_TouchChest)
                return;

            CurrentBodyFrame = BodyFrame.FromHeadAndChest(CapturedHeadWorldPos, CapturedHeadWorldForward, controllerWorldPos);
            SeatAnchorLocal = CurrentBodyFrame.ToLocal(CapturedHeadWorldPos);

            Quaternion headYaw = BodyFrame.ComputeHorizontalYaw(CapturedHeadWorldForward);
            Vector3 chestOffsetFromHead = Quaternion.Inverse(headYaw) * (controllerWorldPos - CapturedHeadWorldPos);
            WorkingProfile.SetChestOffsetFromHead(chestOffsetFromHead);

            AdvanceFromStep2();
        }

        public void SkipStep2_UseDefaultChest()
        {
            if (CurrentStep != CalibrationStepId.Step2_TouchChest)
                return;

            CurrentBodyFrame = BodyFrame.FromHeadWithDefaultChest(CapturedHeadWorldPos, CapturedHeadWorldForward, _defaultChestBelowHeadM);
            SeatAnchorLocal = CurrentBodyFrame.ToLocal(CapturedHeadWorldPos);
            WorkingProfile.SetChestOffsetFromHead(new Vector3(0f, -_defaultChestBelowHeadM, 0.08f));

            AdvanceFromStep2();
        }

        private void AdvanceFromStep2()
        {
            if (IsQuickRecenterMode)
            {
                FinalizeProfile();
                SetStep(CalibrationStepId.Completed);
            }
            else
            {
                _leftShoulderWorld = null;
                _rightShoulderWorld = null;
                SetStep(CalibrationStepId.Step3_TouchShoulders);
            }
        }

        public void ConfirmStep3_TouchShoulder(Vector3 controllerWorldPos)
        {
            if (CurrentStep != CalibrationStepId.Step3_TouchShoulders)
                return;

            if (_leftShoulderWorld == null)
            {
                _leftShoulderWorld = controllerWorldPos;
                EventBus.PublishCalibrationStepChanged((int)CurrentStep, GetCurrentStepInstruction());
                return;
            }

            _rightShoulderWorld = controllerWorldPos;
            float width = Vector3.Distance(_leftShoulderWorld.Value, _rightShoulderWorld.Value);
            WorkingProfile.shoulderWidthM = Mathf.Clamp(width, 0.25f, 0.65f);
            SetStep(CalibrationStepId.Step4_ReachForwardLeft);
        }

        public void SkipStep3_UseDefaultShoulders()
        {
            if (CurrentStep != CalibrationStepId.Step3_TouchShoulders)
                return;

            WorkingProfile.shoulderWidthM = _defaultShoulderWidthM;
            SetStep(CalibrationStepId.Step4_ReachForwardLeft);
        }

        public void ConfirmStep4_LeftReach(Vector3 leftHandWorldPos)
        {
            if (CurrentStep != CalibrationStepId.Step4_ReachForwardLeft)
                return;

            Vector3 localReach = CurrentBodyFrame.ToLocal(leftHandWorldPos);
            float forwardDist = Mathf.Max(0.20f, localReach.z);
            Vector3 shoulderLocal = WorkingProfile.GetShoulderLocalPosition(Hand.Left);
            float armLength = _leftShoulderWorld.HasValue
                ? Vector3.Distance(leftHandWorldPos, _leftShoulderWorld.Value)
                : Vector3.Distance(localReach, shoulderLocal);

            WorkingProfile.leftHand.enabled = true;
            WorkingProfile.leftHand.reachForwardM = forwardDist;
            WorkingProfile.leftHand.armLengthM = Mathf.Max(0.25f, armLength);

            SetStep(CalibrationStepId.Step5_ReachForwardRight);
        }

        public void SkipStep4_DisableLeftHand()
        {
            if (CurrentStep != CalibrationStepId.Step4_ReachForwardLeft)
                return;

            WorkingProfile.leftHand.enabled = false;
            SetStep(CalibrationStepId.Step5_ReachForwardRight);
        }

        public void ConfirmStep5_RightReach(Vector3 rightHandWorldPos)
        {
            if (CurrentStep != CalibrationStepId.Step5_ReachForwardRight)
                return;

            Vector3 localReach = CurrentBodyFrame.ToLocal(rightHandWorldPos);
            float forwardDist = Mathf.Max(0.20f, localReach.z);
            Vector3 shoulderLocal = WorkingProfile.GetShoulderLocalPosition(Hand.Right);
            float armLength = _rightShoulderWorld.HasValue
                ? Vector3.Distance(rightHandWorldPos, _rightShoulderWorld.Value)
                : Vector3.Distance(localReach, shoulderLocal);

            WorkingProfile.rightHand.enabled = true;
            WorkingProfile.rightHand.reachForwardM = forwardDist;
            WorkingProfile.rightHand.armLengthM = Mathf.Max(0.25f, armLength);

            SetStep(CalibrationStepId.Step6_RestHandsInLap);
        }

        public void SkipStep5_DisableRightHand()
        {
            if (CurrentStep != CalibrationStepId.Step5_ReachForwardRight)
                return;

            // Ensure at least one hand stays enabled so gameplay is possible
            if (!WorkingProfile.leftHand.enabled)
            {
                WorkingProfile.leftHand.enabled = true;
            }
            WorkingProfile.rightHand.enabled = false;

            SetStep(CalibrationStepId.Step6_RestHandsInLap);
        }

        public void ConfirmStep6_LapRest(Vector3 leftHandWorldPos, Vector3 rightHandWorldPos)
        {
            if (CurrentStep != CalibrationStepId.Step6_RestHandsInLap)
                return;

            Vector3 lapWorld;
            if (WorkingProfile.leftHand.enabled && WorkingProfile.rightHand.enabled)
                lapWorld = (leftHandWorldPos + rightHandWorldPos) * 0.5f;
            else if (WorkingProfile.leftHand.enabled)
                lapWorld = leftHandWorldPos;
            else
                lapWorld = rightHandWorldPos;

            Vector3 lapLocal = CurrentBodyFrame.ToLocal(lapWorld);
            WorkingProfile.SetLapPointLocal(lapLocal);

            SetStep(CalibrationStepId.Step7_MarkObstacles);
        }

        public void MarkObstaclePoint(Vector3 controllerWorldPos)
        {
            if (CurrentStep != CalibrationStepId.Step7_MarkObstacles)
                return;

            Vector3 localObstacle = CurrentBodyFrame.ToLocal(controllerWorldPos);
            WorkingProfile.obstacles.Add(new ObstaclePoint(localObstacle));
            EventBus.PublishCalibrationStepChanged((int)CurrentStep, GetCurrentStepInstruction());
        }

        public void FinishStep7_CompleteCalibration()
        {
            if (CurrentStep != CalibrationStepId.Step7_MarkObstacles)
                return;

            FinalizeProfile();
            SetStep(CalibrationStepId.Completed);
        }

        private void FinalizeProfile()
        {
            WorkingProfile.version = 1;
            WorkingProfile.createdUtc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");
        }

        private void SetStep(CalibrationStepId next)
        {
            CurrentStep = next;
            EventBus.PublishCalibrationStepChanged((int)CurrentStep, GetCurrentStepInstruction());
        }

        private static ComfortProfile CloneProfile(ComfortProfile src)
        {
            var copy = new ComfortProfile
            {
                version = src.version,
                createdUtc = src.createdUtc,
                shoulderWidthM = src.shoulderWidthM,
                leftHand = new HandCalibrationData
                {
                    enabled = src.leftHand.enabled,
                    reachForwardM = src.leftHand.reachForwardM,
                    armLengthM = src.leftHand.armLengthM
                },
                rightHand = new HandCalibrationData
                {
                    enabled = src.rightHand.enabled,
                    reachForwardM = src.rightHand.reachForwardM,
                    armLengthM = src.rightHand.armLengthM
                },
                chestOffsetFromHeadM = (float[])src.chestOffsetFromHeadM?.Clone() ?? new float[] { 0f, -0.25f, 0.08f },
                lapPointFromChestM = (float[])src.lapPointFromChestM?.Clone() ?? new float[] { 0f, -0.45f, 0.20f },
                obstacles = new List<ObstaclePoint>(src.obstacles ?? new List<ObstaclePoint>())
            };
            return copy;
        }
    }
}

