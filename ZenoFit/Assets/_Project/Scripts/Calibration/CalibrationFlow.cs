using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR;
using ZenoFit.Core;
using ZenoFit.Targets;
using Hand = ZenoFit.Core.Hand;

namespace ZenoFit.Calibration
{
    /// <summary>
    /// MonoBehaviour bridging VR head/controller transforms and trigger input to CalibrationStateMachine (§4.2).
    /// </summary>
    public class CalibrationFlow : MonoBehaviour
    {
        [SerializeField] private CalibrationConfig _config;
        [SerializeField] private Transform _headTransform;
        [SerializeField] private HandTipTracker _leftHandTip;
        [SerializeField] private HandTipTracker _rightHandTip;
        [SerializeField] private InputActionProperty _confirmTriggerAction;

        private CalibrationStateMachine _stateMachine;
        private bool _wasRightTriggerPressed;
        private bool _wasLeftTriggerPressed;

        public CalibrationStateMachine StateMachine => _stateMachine;

        public void Initialize(
            ComfortProfile existingProfile,
            Transform headTransform,
            HandTipTracker leftHandTip,
            HandTipTracker rightHandTip)
        {
            if (headTransform != null)
                _headTransform = headTransform;
            if (leftHandTip != null)
                _leftHandTip = leftHandTip;
            if (rightHandTip != null)
                _rightHandTip = rightHandTip;

            float chestBelow = _config != null ? _config.DefaultChestOffsetBelowHeadM : 0.25f;
            float shoulderW = _config != null ? _config.DefaultShoulderWidthM : 0.40f;

            _stateMachine = new CalibrationStateMachine(existingProfile, chestBelow, shoulderW);
        }

        public void BeginFullCalibration()
        {
            EnsureStateMachine();
            _stateMachine.StartFullCalibration();
        }

        public void BeginQuickRecenter()
        {
            EnsureStateMachine();
            _stateMachine.StartQuickRecenter();
        }

        private void OnEnable()
        {
            if (_confirmTriggerAction.action != null)
                _confirmTriggerAction.action.Enable();
        }

        private void Update()
        {
            if (_stateMachine == null || _stateMachine.CurrentStep == CalibrationStepId.Completed)
                return;

            if (WasConfirmInputPressedThisFrame(out Hand triggeringHand))
            {
                ConfirmCurrentStep(triggeringHand);
            }
        }

        private int _shoulderTouchCount;

        public void ConfirmCurrentStep(Hand preferredHand = Hand.Right)
        {
            EnsureStateMachine();

            bool hasXrController = InputDevices.GetDeviceAtXRNode(XRNode.RightHand).isValid ||
                                   InputDevices.GetDeviceAtXRNode(XRNode.LeftHand).isValid;

            Vector3 headPos = _headTransform != null ? _headTransform.position : new Vector3(0f, 1.20f, 0f);
            Vector3 headFwd = _headTransform != null && _headTransform.forward.sqrMagnitude > 0.01f
                ? _headTransform.forward
                : Vector3.forward;
            Vector3 leftPos = _leftHandTip != null ? _leftHandTip.CurrentWorldPosition : headPos + new Vector3(-0.20f, -0.25f, 0.45f);
            Vector3 rightPos = _rightHandTip != null ? _rightHandTip.CurrentWorldPosition : headPos + new Vector3(0.20f, -0.25f, 0.45f);
            Vector3 activeHandPos = preferredHand == Hand.Left ? leftPos : rightPos;

            switch (_stateMachine.CurrentStep)
            {
                case CalibrationStepId.Step1_SitAndLookForward:
                    _shoulderTouchCount = 0;
                    _stateMachine.ConfirmStep1_SitAndLookForward(headPos, headFwd);
                    break;
                case CalibrationStepId.Step2_TouchChest:
                    if (!hasXrController)
                        activeHandPos = headPos + new Vector3(0f, -0.25f, 0f);
                    _stateMachine.ConfirmStep2_TouchChest(activeHandPos);
                    break;
                case CalibrationStepId.Step3_TouchShoulders:
                    if (!hasXrController)
                    {
                        float side = (_shoulderTouchCount % 2 == 0) ? -0.20f : 0.20f;
                        activeHandPos = _stateMachine.CurrentBodyFrame.ToWorld(new Vector3(side, 0f, 0f));
                    }
                    _shoulderTouchCount++;
                    _stateMachine.ConfirmStep3_TouchShoulder(activeHandPos);
                    break;
                case CalibrationStepId.Step4_ReachForwardLeft:
                    if (!hasXrController && Vector3.Distance(leftPos, _stateMachine.CurrentBodyFrame.Origin) < 0.45f)
                        leftPos = _stateMachine.CurrentBodyFrame.ToWorld(new Vector3(-0.20f, 0f, 0.60f));
                    _stateMachine.ConfirmStep4_LeftReach(leftPos);
                    break;
                case CalibrationStepId.Step5_ReachForwardRight:
                    if (!hasXrController && Vector3.Distance(rightPos, _stateMachine.CurrentBodyFrame.Origin) < 0.45f)
                        rightPos = _stateMachine.CurrentBodyFrame.ToWorld(new Vector3(0.20f, 0f, 0.60f));
                    _stateMachine.ConfirmStep5_RightReach(rightPos);
                    break;
                case CalibrationStepId.Step6_RestHandsInLap:
                    if (!hasXrController && leftPos.y > _stateMachine.CurrentBodyFrame.Origin.y - 0.15f)
                    {
                        leftPos = _stateMachine.CurrentBodyFrame.ToWorld(new Vector3(-0.15f, -0.25f, 0.20f));
                        rightPos = _stateMachine.CurrentBodyFrame.ToWorld(new Vector3(0.15f, -0.25f, 0.20f));
                    }
                    _stateMachine.ConfirmStep6_LapRest(leftPos, rightPos);
                    break;
                case CalibrationStepId.Step7_MarkObstacles:
                    _stateMachine.MarkObstaclePoint(activeHandPos);
                    break;
            }
        }

        public void SkipOrDefaultCurrentStep()
        {
            EnsureStateMachine();

            switch (_stateMachine.CurrentStep)
            {
                case CalibrationStepId.Step2_TouchChest:
                    _stateMachine.SkipStep2_UseDefaultChest();
                    break;
                case CalibrationStepId.Step3_TouchShoulders:
                    _stateMachine.SkipStep3_UseDefaultShoulders();
                    break;
                case CalibrationStepId.Step4_ReachForwardLeft:
                    _stateMachine.SkipStep4_DisableLeftHand();
                    break;
                case CalibrationStepId.Step5_ReachForwardRight:
                    _stateMachine.SkipStep5_DisableRightHand();
                    break;
                case CalibrationStepId.Step7_MarkObstacles:
                    _stateMachine.FinishStep7_CompleteCalibration();
                    break;
            }
        }

        public void RedoPreviousStep()
        {
            EnsureStateMachine();
            int current = (int)_stateMachine.CurrentStep;
            if (current > (int)CalibrationStepId.Step1_SitAndLookForward && current <= (int)CalibrationStepId.Step7_MarkObstacles)
            {
                _stateMachine.GoToStep((CalibrationStepId)(current - 1));
            }
        }

        private void EnsureStateMachine()
        {
            if (_stateMachine == null)
            {
                Initialize(null, _headTransform, _leftHandTip, _rightHandTip);
            }
        }

        private bool WasConfirmInputPressedThisFrame(out Hand triggeringHand)
        {
            triggeringHand = Hand.Right;

            if (_confirmTriggerAction.action != null && _confirmTriggerAction.action.WasPressedThisFrame())
                return true;

            if (Keyboard.current != null && Keyboard.current.spaceKey.wasPressedThisFrame)
                return true;

            // Poll XR controller trigger buttons directly with edge detection
            UnityEngine.XR.InputDevice rightDev = InputDevices.GetDeviceAtXRNode(XRNode.RightHand);
            bool rightPressed = rightDev.isValid &&
                                rightDev.TryGetFeatureValue(UnityEngine.XR.CommonUsages.triggerButton, out bool rVal) &&
                                rVal;
            if (rightPressed && !_wasRightTriggerPressed)
            {
                _wasRightTriggerPressed = true;
                triggeringHand = Hand.Right;
                return true;
            }
            _wasRightTriggerPressed = rightPressed;

            UnityEngine.XR.InputDevice leftDev = InputDevices.GetDeviceAtXRNode(XRNode.LeftHand);
            bool leftPressed = leftDev.isValid &&
                               leftDev.TryGetFeatureValue(UnityEngine.XR.CommonUsages.triggerButton, out bool lVal) &&
                               lVal;
            if (leftPressed && !_wasLeftTriggerPressed)
            {
                _wasLeftTriggerPressed = true;
                triggeringHand = Hand.Left;
                return true;
            }
            _wasLeftTriggerPressed = leftPressed;

            return false;
        }
    }
}