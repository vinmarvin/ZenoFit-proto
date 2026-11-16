using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Exercises
{
    /// <summary>
    /// Base ScriptableObject configuration for an exercise (00-README.md §5 Rules 8 & 11).
    /// </summary>
    public abstract class ExerciseConfig : ScriptableObject
    {
        [Header("Exercise Identity")]
        [SerializeField] private ExerciseType _exerciseType;
        [SerializeField] private string _displayName = "Exercise";
        [TextArea(2, 4)]
        [SerializeField] private string _shortDescription = "Seated upper-body exercise.";

        [Header("Adaptive Tempo Settings (02-targets-and-hit-detection.md §6.4 [P])")]
        [SerializeField] private bool _useAdaptiveTempo = true;
        [Range(4, 16)]
        [SerializeField] private int _adaptiveWindowSize = 8;
        [Range(0.50f, 1.00f)]
        [SerializeField] private float _increaseTempoAccuracyThreshold = 0.85f;
        [Range(0.20f, 0.80f)]
        [SerializeField] private float _decreaseTempoAccuracyThreshold = 0.60f;
        [Range(1f, 15f)]
        [SerializeField] private float _tempoStepBpm = 5f;
        [Range(30f, 60f)]
        [SerializeField] private float _minTempoBpm = 40f;

        public ExerciseType ExerciseType => _exerciseType;
        public string DisplayName => _displayName;
        public string ShortDescription => _shortDescription;
        public bool UseAdaptiveTempo => _useAdaptiveTempo;
        public int AdaptiveWindowSize => _adaptiveWindowSize;
        public float IncreaseTempoAccuracyThreshold => _increaseTempoAccuracyThreshold;
        public float DecreaseTempoAccuracyThreshold => _decreaseTempoAccuracyThreshold;
        public float TempoStepBpm => _tempoStepBpm;
        public float MinTempoBpm => _minTempoBpm;

        protected void InitMetadata(ExerciseType type, string displayName, string description, bool adaptiveTempo = true)
        {
            _exerciseType = type;
            _displayName = displayName;
            _shortDescription = description;
            _useAdaptiveTempo = adaptiveTempo;
        }
    }
}

