using System;

namespace ZenoFit.Core
{
    /// <summary>
    /// Pure C# state machine for the app flow (00-gameplay-overview.md §2 GP-FLOW-01).
    /// Boot → MainMenu → Calibration → ExerciseSelect → Gameplay ⇄ Paused → Results
    /// </summary>
    public class GameFlowStateMachine
    {
        public AppState CurrentState { get; private set; } = AppState.Boot;
        public PauseReason CurrentPauseReason { get; private set; } = PauseReason.None;

        public event Action<AppState, AppState> OnStateTransition;

        public bool CanTransitionTo(AppState next)
        {
            if (CurrentState == next)
                return false;

            switch (CurrentState)
            {
                case AppState.Boot:
                    return next == AppState.MainMenu;

                case AppState.MainMenu:
                    return next == AppState.Calibration || next == AppState.ExerciseSelect;

                case AppState.Calibration:
                    return next == AppState.ExerciseSelect || next == AppState.MainMenu;

                case AppState.ExerciseSelect:
                    return next == AppState.Gameplay || next == AppState.Calibration || next == AppState.MainMenu;

                case AppState.Gameplay:
                    return next == AppState.Paused || next == AppState.Results || next == AppState.Calibration;

                case AppState.Paused:
                    return next == AppState.Gameplay || next == AppState.Results || next == AppState.Calibration || next == AppState.MainMenu;

                case AppState.Results:
                    return next == AppState.Gameplay || next == AppState.ExerciseSelect || next == AppState.MainMenu;

                default:
                    return false;
            }
        }

        public bool TryTransitionTo(AppState next, PauseReason pauseReason = PauseReason.None)
        {
            if (!CanTransitionTo(next))
                return false;

            AppState prev = CurrentState;
            CurrentState = next;
            CurrentPauseReason = next == AppState.Paused ? pauseReason : PauseReason.None;

            OnStateTransition?.Invoke(prev, next);
            EventBus.PublishStateChanged(prev, next);
            return true;
        }

        public void OnBootComplete()
        {
            TryTransitionTo(AppState.MainMenu);
        }

        public void OnStartFromMainMenu(bool hasValidCalibrationProfile)
        {
            TryTransitionTo(hasValidCalibrationProfile ? AppState.ExerciseSelect : AppState.Calibration);
        }

        public void OnRecalibrateRequested()
        {
            TryTransitionTo(AppState.Calibration);
        }

        public void OnCalibrationCompleted()
        {
            TryTransitionTo(AppState.ExerciseSelect);
        }

        public void OnPlayExercise()
        {
            TryTransitionTo(AppState.Gameplay);
        }

        public bool PauseGameplay(PauseReason reason, string message = "", bool requestPassthrough = false)
        {
            if (CurrentState != AppState.Gameplay)
                return false;

            if (TryTransitionTo(AppState.Paused, reason))
            {
                EventBus.PublishSessionPaused(new SessionPausedEvent(reason, message, requestPassthrough));
                return true;
            }
            return false;
        }

        public bool ResumeGameplay()
        {
            if (CurrentState != AppState.Paused)
                return false;

            if (TryTransitionTo(AppState.Gameplay))
            {
                EventBus.PublishSessionResumed();
                return true;
            }
            return false;
        }

        public bool FinishOrStopGameplay()
        {
            if (CurrentState != AppState.Gameplay && CurrentState != AppState.Paused)
                return false;

            return TryTransitionTo(AppState.Results);
        }
    }
}

