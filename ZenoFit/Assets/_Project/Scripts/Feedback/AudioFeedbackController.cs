using UnityEngine;
using ZenoFit.Core;

namespace ZenoFit.Feedback
{
    /// <summary>
    /// Soft, non-startling audio cue player for hits, clicks, countdowns, and completion (10-feedback-and-ui.md §9.2).
    /// Generates gentle procedural sine chimes when no external AudioClips are assigned.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public class AudioFeedbackController : MonoBehaviour
    {
        [SerializeField] private AudioClip _softPopClip;
        [SerializeField] private AudioClip _clickClip;
        [SerializeField] private AudioClip _solidHitClip;
        [SerializeField] private AudioClip _completeChimeClip;

        private AudioSource _audioSource;
        private AppSettings _settings;

        private void Awake()
        {
            _audioSource = GetComponent<AudioSource>();
            _audioSource.playOnAwake = false;
            _audioSource.spatialBlend = 0f;

            if (_softPopClip == null)
                _softPopClip = CreateProceduralTone("SoftPop", 528f, 0.09f);
            if (_clickClip == null)
                _clickClip = CreateProceduralTone("SoftClick", 660f, 0.05f);
            if (_solidHitClip == null)
                _solidHitClip = CreateProceduralTone("SolidHit", 440f, 0.11f);
            if (_completeChimeClip == null)
                _completeChimeClip = CreateProceduralTone("CompleteChime", 784f, 0.25f);
        }

        public void BindSettings(AppSettings settings)
        {
            _settings = settings;
        }

        public void PlaySoftPop() => PlayClip(_softPopClip, 0.55f);
        public void PlayClick() => PlayClip(_clickClip, 0.60f);
        public void PlaySolidHit() => PlayClip(_solidHitClip, 0.70f);
        public void PlayCompleteChime() => PlayClip(_completeChimeClip, 0.65f);

        private void PlayClip(AudioClip clip, float baseScale)
        {
            if (_audioSource == null || clip == null)
                return;

            float volume = _settings != null ? _settings.audioVolume01 : 0.8f;
            if (volume <= 0.001f)
                return;

            _audioSource.PlayOneShot(clip, Mathf.Clamp01(volume * baseScale));
        }

        private static AudioClip CreateProceduralTone(string name, float frequencyHz, float durationSeconds)
        {
            const int sampleRate = 22050;
            int sampleCount = Mathf.Max(64, Mathf.RoundToInt(sampleRate * durationSeconds));
            float[] samples = new float[sampleCount];

            for (int i = 0; i < sampleCount; i++)
            {
                float t = (float)i / sampleRate;
                float normalized = (float)i / sampleCount;
                // Smooth attack + exponential decay envelope so there are zero harsh clicks
                float envelope = Mathf.Sin(Mathf.Min(1f, normalized * 10f) * Mathf.PI * 0.5f) * (1f - normalized);
                samples[i] = Mathf.Sin(2f * Mathf.PI * frequencyHz * t) * envelope * 0.35f;
            }

            AudioClip clip = AudioClip.Create(name, sampleCount, 1, sampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }
    }
}

