using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;

namespace ZenoFit.Persistence
{
    /// <summary>
    /// Local JSON persistence for calibration profile, session history, and settings (D-07, GP-CAL-08, GP-PROG-01, AT-15).
    /// No cloud or network access is ever used.
    /// </summary>
    public class JsonPersistenceService
    {
        public const string CalibrationFileName = "calibration_profile.json";
        public const string SessionsFileName = "sessions.json";
        public const string SettingsFileName = "settings.json";

        private readonly string _rootDirectory;

        public JsonPersistenceService(string customDirectory = null)
        {
            _rootDirectory = string.IsNullOrEmpty(customDirectory)
                ? Application.persistentDataPath
                : customDirectory;

            if (!Directory.Exists(_rootDirectory))
            {
                Directory.CreateDirectory(_rootDirectory);
            }
        }

        public string CalibrationFilePath => Path.Combine(_rootDirectory, CalibrationFileName);
        public string SessionsFilePath => Path.Combine(_rootDirectory, SessionsFileName);
        public string SettingsFilePath => Path.Combine(_rootDirectory, SettingsFileName);

        public void SaveCalibrationProfile(ComfortProfile profile)
        {
            if (profile == null)
                return;

            string json = JsonUtility.ToJson(profile, true);
            File.WriteAllText(CalibrationFilePath, json);
        }

        public bool TryLoadCalibrationProfile(out ComfortProfile profile)
        {
            profile = null;
            if (!File.Exists(CalibrationFilePath))
                return false;

            try
            {
                string json = File.ReadAllText(CalibrationFilePath);
                if (string.IsNullOrWhiteSpace(json))
                    return false;

                profile = JsonUtility.FromJson<ComfortProfile>(json);
                return profile != null && profile.IsValid();
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[JsonPersistenceService] Failed to load calibration profile: {ex.Message}");
                return false;
            }
        }

        public void AppendSessionRecord(SessionRecord record, int maxHistoryCount = 50)
        {
            if (record == null)
                return;

            SessionHistoryFile history = LoadSessionHistoryFile();
            history.sessions.Add(record);

            if (maxHistoryCount > 0 && history.sessions.Count > maxHistoryCount)
            {
                int removeCount = history.sessions.Count - maxHistoryCount;
                history.sessions.RemoveRange(0, removeCount);
            }

            string json = JsonUtility.ToJson(history, true);
            File.WriteAllText(SessionsFilePath, json);
        }

        public List<SessionRecord> LoadRecentSessions(int maxCount = 10)
        {
            SessionHistoryFile history = LoadSessionHistoryFile();
            if (history.sessions == null || history.sessions.Count == 0)
                return new List<SessionRecord>();

            int count = Mathf.Min(maxCount, history.sessions.Count);
            int startIndex = history.sessions.Count - count;
            return history.sessions.GetRange(startIndex, count);
        }

        public SessionHistoryFile LoadSessionHistoryFile()
        {
            if (!File.Exists(SessionsFilePath))
                return new SessionHistoryFile();

            try
            {
                string json = File.ReadAllText(SessionsFilePath);
                if (string.IsNullOrWhiteSpace(json))
                    return new SessionHistoryFile();

                var history = JsonUtility.FromJson<SessionHistoryFile>(json);
                if (history == null)
                    return new SessionHistoryFile();
                if (history.sessions == null)
                    history.sessions = new List<SessionRecord>();
                return history;
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[JsonPersistenceService] Failed to load sessions.json: {ex.Message}");
                return new SessionHistoryFile();
            }
        }

        public void SaveSettings(AppSettings settings)
        {
            if (settings == null)
                return;

            settings.ClampToSafeRanges();
            string json = JsonUtility.ToJson(settings, true);
            File.WriteAllText(SettingsFilePath, json);
        }

        public AppSettings LoadSettings()
        {
            if (!File.Exists(SettingsFilePath))
                return new AppSettings();

            try
            {
                string json = File.ReadAllText(SettingsFilePath);
                if (string.IsNullOrWhiteSpace(json))
                    return new AppSettings();

                var settings = JsonUtility.FromJson<AppSettings>(json) ?? new AppSettings();
                settings.ClampToSafeRanges();
                return settings;
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"[JsonPersistenceService] Failed to load settings.json: {ex.Message}");
                return new AppSettings();
            }
        }

        public void DeleteAllSavedData()
        {
            if (File.Exists(CalibrationFilePath))
                File.Delete(CalibrationFilePath);
            if (File.Exists(SessionsFilePath))
                File.Delete(SessionsFilePath);
            if (File.Exists(SettingsFilePath))
                File.Delete(SettingsFilePath);
        }
    }
}

