using System.IO;
using NUnit.Framework;
using UnityEngine;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Exercises;
using ZenoFit.Persistence;
using ZenoFit.Platform;
using ZenoFit.Safety;
using ZenoFit.Scoring;
using ZenoFit.Targets;

namespace ZenoFit.Tests.EditMode
{
    /// <summary>
    /// Automated EditMode acceptance tests covering AT-01 through AT-16 (11-acceptance-tests.md §10).
    /// </summary>
    public class AcceptanceTests
    {
        [Test]
        public void AT01_ForwardReach_LeftHandTargetDepth_MatchesComfortFormula()
        {
            // Given calibration with R_f,L = 0.60, k = 0.85
            var profile = ComfortProfile.CreateDefault();
            profile.leftHand.reachForwardM = 0.60f;
            float k = 0.85f;

            // When a Forward Reach target is computed for the left hand
            Vector3 localPos = ForwardArmReachExercise.ComputeLocalPosition(
                profile,
                Hand.Left,
                k,
                jitterX: 0f,
                jitterY: 0f);

            // Then its BodyFrame z = 0.51 m ± 0.001
            Assert.AreEqual(0.51f, localPos.z, 0.001f);
        }

        [Test]
        public void AT01_CaseStudy_RaniAsymmetricReach_PlacesEachArmAtItsOwnDepth()
        {
            // Case study (§4.3): R_f,L = 0.55 m, R_f,R = 0.42 m, Standard k = 0.75
            var profile = ComfortProfile.CreateDefault();
            profile.leftHand.reachForwardM = 0.55f;
            profile.rightHand.reachForwardM = 0.42f;

            float leftZ = profile.GetTargetForwardDistance(Hand.Left, 0.75f);
            float rightZ = profile.GetTargetForwardDistance(Hand.Right, 0.75f);

            Assert.AreEqual(0.4125f, leftZ, 0.001f);
            Assert.AreEqual(0.3150f, rightZ, 0.001f);
        }

        [Test]
        public void AT02_SideArmRaise_ComputesExpectedShoulderOffset()
        {
            // Given L = 0.60, k = 0.85, θ = 60°
            float armLengthM = 0.60f;
            float k = 0.85f;
            float thetaDeg = 60f;

            // When a Side Raise target is computed for the right hand
            Vector2 offset = SideArmRaiseExercise.ComputeShoulderOffset(
                armLengthM,
                k,
                thetaDeg,
                Hand.Right);

            // Then x_offset = 0.442 ± 0.001 and y_offset = -0.255 ± 0.001
            Assert.AreEqual(0.442f, offset.x, 0.001f);
            Assert.AreEqual(-0.255f, offset.y, 0.001f);
        }

        [Test]
        public void AT03_SideArmRaise_ClampsAngleToConfiguredMaxAndHardCap70()
        {
            // Given θ_max = 60°, when a spawner requests θ = 75°, then θ is clamped to <= 60°
            float clampedDefault = SideArmRaiseExercise.ClampAbductionAngle(75f, configuredMaxAngleDeg: 60f);
            Assert.AreEqual(60f, clampedDefault, 0.001f);

            // And never above 70° even if configured higher (e.g. 85°)
            float clampedHardCap = SideArmRaiseExercise.ClampAbductionAngle(85f, configuredMaxAngleDeg: 85f);
            Assert.AreEqual(70f, clampedHardCap, 0.001f);
        }

        [Test]
        public void AT04_TargetSpawner_AvoidsObstacleExclusionSphere()
        {
            // Given an obstacle sphere at a candidate position
            var profile = ComfortProfile.CreateDefault();
            Vector3 obstacleCenter = new Vector3(0.0f, 0.0f, 0.45f);
            profile.obstacles.Add(new ObstaclePoint(obstacleCenter));

            float exclusionRadiusM = 0.12f;
            float targetRadiusM = 0.10f;

            // Candidate directly inside the obstacle must be flagged as violating
            Assert.IsTrue(profile.IsViolatingObstacleZone(obstacleCenter, targetRadiusM, exclusionRadiusM));

            // When the spawner picks a position
            bool found = TargetSpawner.TryResolveObstacleFreePosition(
                profile,
                obstacleCenter,
                targetRadiusM,
                exclusionRadiusM,
                maxAttempts: 16,
                out Vector3 resolvedLocalPos);

            // Then the target is not within r_ex + targetRadius of the obstacle
            Assert.IsTrue(found);
            float dist = Vector3.Distance(resolvedLocalPos, obstacleCenter);
            Assert.GreaterOrEqual(dist, exclusionRadiusM + targetRadiusM - 1e-4f);
        }

        [Test]
        public void AT05_AdaptiveTempo_BeatIntervalsMatchSpec()
        {
            // Given BPM = 60, then interval = 1.0 s; given BPM = 75, then 0.8 s
            Assert.AreEqual(1.0f, AdaptiveTempo.GetBeatIntervalSeconds(60f), 0.0001f);
            Assert.AreEqual(0.8f, AdaptiveTempo.GetBeatIntervalSeconds(75f), 0.0001f);
        }

        [Test]
        public void AT06_AdaptiveTempo_CaseStudyAccuracySequence()
        {
            // Session starts at 60 BPM (Standard, max 80 BPM)
            var tempo = new AdaptiveTempo(startBpm: 60f, maxBpm: 80f, windowSize: 8);
            Assert.AreEqual(60f, tempo.CurrentBpm, 0.001f);

            // Window 1: 7 hits of 8 -> 87.5 % -> 65 BPM
            Assert.AreEqual(65f, tempo.EvaluateWindow(hits: 7, targetsInWindow: 8), 0.001f);

            // Window 2: 6 hits of 8 -> 75 % -> hold 65 BPM
            Assert.AreEqual(65f, tempo.EvaluateWindow(hits: 6, targetsInWindow: 8), 0.001f);

            // Window 3: 4 hits of 8 -> 50 % -> 60 BPM
            Assert.AreEqual(60f, tempo.EvaluateWindow(hits: 4, targetsInWindow: 8), 0.001f);
        }

        [Test]
        public void AT07_ScoreCalculator_SingleHitPointsMatchesFormula()
        {
            // Given lifetime = 2.0 s, hit at 0.5 s, then points = 137
            int points = ScoreCalculator.ComputeHitPoints(hitTimeSeconds: 0.5f, lifetimeSeconds: 2.0f);
            Assert.AreEqual(137, points);
        }

        [Test]
        public void AT08_ScoreCalculator_FiveTargetCaseStudyMatchesSpec()
        {
            // Given the 5-target case study (§7.1): 60 BPM, lifetime = 2.0 s
            var tracker = new AccuracyTracker();
            float lifetime = ScoreCalculator.ComputeLifetimeSeconds(lifetimeBeats: 2, bpm: 60f);
            Assert.AreEqual(2.0f, lifetime, 0.001f);

            // Target 1: Hit at 0.4 s -> 140
            Assert.AreEqual(140, tracker.RecordHit(Hand.Left, 0.4f, lifetime));
            // Target 2: Hit at 1.0 s -> 125
            Assert.AreEqual(125, tracker.RecordHit(Hand.Right, 1.0f, lifetime));
            // Target 3: Miss -> 0
            tracker.RecordMiss();
            // Target 4: Hit at 0.2 s -> 145
            Assert.AreEqual(145, tracker.RecordHit(Hand.Left, 0.2f, lifetime));
            // Target 5: Hit at 1.8 s -> 105
            Assert.AreEqual(105, tracker.RecordHit(Hand.Right, 1.8f, lifetime));

            // Total = 515 points; accuracy = 80 %
            Assert.AreEqual(515, tracker.TotalScore);
            Assert.AreEqual(80.0f, tracker.AccuracyPercent, 0.01f);
        }

        [Test]
        public void AT09_AutoPauseMonitor_PausesOnlyWhenBothHandsInLapForTwoSeconds()
        {
            var monitor = new AutoPauseMonitor(lapDistanceThresholdM: 0.15f, holdDurationSeconds: 2.0f);
            Vector3 lapPoint = new Vector3(0f, -0.45f, 0.20f);
            Vector3 insideLap = new Vector3(0f, -0.45f, 0.32f); // 0.12 m from lapPoint (<= 0.15)
            Vector3 outsideLap = new Vector3(0f, 0.0f, 0.40f);  // > 0.15 m

            // With one hand outside, it does not pause even after 3 seconds
            for (int i = 0; i < 6; i++)
            {
                bool pausedOneOutside = monitor.Evaluate(insideLap, outsideLap, lapPoint, deltaTime: 0.5f);
                Assert.IsFalse(pausedOneOutside);
            }

            // With both hands inside 0.15 m of LapPoint for 2.0 s, the game pauses
            Assert.IsFalse(monitor.Evaluate(insideLap, insideLap, lapPoint, deltaTime: 1.0f));
            Assert.IsFalse(monitor.Evaluate(insideLap, insideLap, lapPoint, deltaTime: 0.5f));
            Assert.IsTrue(monitor.Evaluate(insideLap, insideLap, lapPoint, deltaTime: 0.5f));
        }

        [Test]
        public void AT10_LeanMonitor_WarnsAt22CmFor06s_AndIgnores12Cm()
        {
            var leanMonitor = new LeanMonitor(leanThresholdM: 0.20f, holdSeconds: 0.5f);

            // At 0.12 m, nothing happens
            Assert.IsFalse(leanMonitor.Evaluate(headLocalX: 0.12f, seatAnchorLocalX: 0f, deltaTime: 0.6f));
            Assert.AreEqual(0f, leanMonitor.AccumulatedLeanSeconds, 0.001f);

            // At |Δx| = 0.22 m for 0.6 s, a lean warning/pause is triggered
            Assert.IsFalse(leanMonitor.Evaluate(headLocalX: -0.22f, seatAnchorLocalX: 0f, deltaTime: 0.3f));
            Assert.IsTrue(leanMonitor.Evaluate(headLocalX: -0.22f, seatAnchorLocalX: 0f, deltaTime: 0.3f));
        }

        [Test]
        public void AT11_DisabledRightHand_SpawnsOnlyLeftTargetsAndIgnoresRightController()
        {
            var profile = ComfortProfile.CreateDefault();
            profile.leftHand.enabled = true;
            profile.rightHand.enabled = false;

            var settings = new AppSettings { handMode = HandMode.BothHands };
            HandMode effectiveMode = settings.GetEffectiveHandMode(profile.leftHand.enabled, profile.rightHand.enabled);
            Assert.AreEqual(HandMode.LeftOnly, effectiveMode);

            var preset = DifficultyPreset.CreateRuntimePreset(DifficultyTier.Standard);
            var exercise = new AlternatingArmReachExercise();
            exercise.Initialize(profile, preset, settings, new AdaptiveTempo(), new AccuracyTracker(), null);

            for (int i = 0; i < 6; i++)
            {
                Assert.IsTrue(exercise.TryGetNextTargetSpawn(i, out TargetSpawnSpec spec));
                Assert.AreEqual(TargetHand.Left, spec.RequiredHand);
            }

            // Right controller touch at exact target center is ignored
            Vector3 targetCenter = new Vector3(-0.20f, 0f, 0.40f);
            bool rightHit = HitDetector.TryCheckValidHandHit(
                Hand.Right,
                isCandidateHandEnabled: profile.rightHand.enabled,
                effectiveMode,
                TargetHand.Left,
                targetCenter,
                targetRadiusM: 0.10f,
                prevHandTipPos: targetCenter,
                currHandTipPos: targetCenter);

            Assert.IsFalse(rightHit);
        }

        [Test]
        public void AT12_SeatedBoxing_DistinguishesSolidAndLightHitsAndScoresBoth()
        {
            // Given Seated Boxing with v_solid = 0.30
            // Hand speed 0.4 m/s -> solid hit; 0.2 m/s -> light hit; both score
            bool solidAt04 = SeatedBoxingExercise.IsSolidHit(0.40f, solidSpeedThresholdMps: 0.30f, touchMode: false);
            bool solidAt02 = SeatedBoxingExercise.IsSolidHit(0.20f, solidSpeedThresholdMps: 0.30f, touchMode: false);

            Assert.IsTrue(solidAt04);
            Assert.IsFalse(solidAt02);

            int pointsSolid = ScoreCalculator.ComputeHitPoints(0.5f, 2.0f, isSolidBoxingHit: solidAt04);
            int pointsLight = ScoreCalculator.ComputeHitPoints(0.5f, 2.0f, isSolidBoxingHit: solidAt02);

            Assert.AreEqual(137 + 25, pointsSolid);
            Assert.AreEqual(137, pointsLight);
            Assert.Greater(pointsLight, 0);
        }

        [Test]
        public void AT13_HitDetector_SegmentDistanceDetectsFastHandWithoutTunnelling()
        {
            // Target of radius 0.08 m at (0, 0, 0.45)
            Vector3 targetCenter = new Vector3(0f, 0f, 0.45f);
            float targetRadius = 0.08f;
            float handTipRadius = 0.04f;

            // Fast hand moves from z = 0.20 m to z = 0.70 m in a single frame
            // Both endpoints are 0.25 m away from targetCenter (> 0.12 m combined radius),
            // so a naive point-in-sphere check at P0 and P1 would miss!
            Vector3 p0 = new Vector3(0.02f, 0f, 0.20f);
            Vector3 p1 = new Vector3(0.02f, 0f, 0.70f);

            Assert.Greater(Vector3.Distance(p0, targetCenter), targetRadius + handTipRadius);
            Assert.Greater(Vector3.Distance(p1, targetCenter), targetRadius + handTipRadius);

            // Segment-distance check registers the hit
            bool hit = HitDetector.IsSegmentHit(targetCenter, targetRadius, p0, p1, handTipRadius);
            Assert.IsTrue(hit);
        }

        [Test]
        public void AT14_ManualMenuPause_TransitionsToPausedImmediately()
        {
            var flow = new GameFlowStateMachine();
            flow.OnBootComplete();
            flow.OnStartFromMainMenu(hasValidCalibrationProfile: true);
            flow.OnPlayExercise();
            Assert.AreEqual(AppState.Gameplay, flow.CurrentState);

            // Pressing Menu transitions immediately to Paused in the same frame
            bool paused = flow.PauseGameplay(PauseReason.Manual, "Menu button pressed");
            Assert.IsTrue(paused);
            Assert.AreEqual(AppState.Paused, flow.CurrentState);
            Assert.AreEqual(PauseReason.Manual, flow.CurrentPauseReason);
        }

        [Test]
        public void AT15_JsonPersistence_SavesAndReloadsCalibrationAndSessionHistory()
        {
            string tempDir = Path.Combine(Path.GetTempPath(), "ZenoFit_AT15_" + System.Guid.NewGuid().ToString("N"));
            try
            {
                var persistence1 = new JsonPersistenceService(tempDir);

                var profile = ComfortProfile.CreateDefault();
                profile.shoulderWidthM = 0.44f;
                profile.leftHand.reachForwardM = 0.58f;
                profile.rightHand.reachForwardM = 0.46f;
                profile.obstacles.Add(new ObstaclePoint(-0.30f, -0.30f, 0.0f));
                persistence1.SaveCalibrationProfile(profile);

                persistence1.AppendSessionRecord(new SessionRecord
                {
                    dateUtc = "2026-11-12T10:00:00Z",
                    exercise = ExerciseType.ForwardArmReach.ToString(),
                    difficulty = DifficultyTier.Standard.ToString(),
                    handMode = HandMode.BothHands.ToString(),
                    durationSeconds = 45f,
                    hits = 18,
                    misses = 2,
                    accuracyPercent = 90f,
                    score = 2450,
                    maxTempoReachedBpm = 70f
                });

                // Simulate app quit and reopen with a fresh service instance
                var persistence2 = new JsonPersistenceService(tempDir);
                bool loaded = persistence2.TryLoadCalibrationProfile(out ComfortProfile reloadedProfile);
                Assert.IsTrue(loaded);
                Assert.AreEqual(0.44f, reloadedProfile.shoulderWidthM, 0.001f);
                Assert.AreEqual(0.58f, reloadedProfile.leftHand.reachForwardM, 0.001f);
                Assert.AreEqual(0.46f, reloadedProfile.rightHand.reachForwardM, 0.001f);
                Assert.AreEqual(1, reloadedProfile.obstacles.Count);

                var history = persistence2.LoadRecentSessions(10);
                Assert.AreEqual(1, history.Count);
                Assert.AreEqual(2450, history[0].score);
            }
            finally
            {
                if (Directory.Exists(tempDir))
                {
                    Directory.Delete(tempDir, recursive: true);
                }
            }
        }

        [Test]
        public void AT16_HeadsetRecenterEvent_PausesGameplayAndRequestsSeatReconfirmation()
        {
            var flow = new GameFlowStateMachine();
            flow.OnBootComplete();
            flow.OnStartFromMainMenu(hasValidCalibrationProfile: true);
            flow.OnPlayExercise();
            Assert.AreEqual(AppState.Gameplay, flow.CurrentState);

            var simPlatform = new EditorSimPlatform();
            simPlatform.Initialize();

            PauseReason capturedReason = PauseReason.None;
            simPlatform.TrackingOriginRecentered += () =>
            {
                flow.PauseGameplay(PauseReason.RecenterRequired, "Sit comfortably and confirm.");
                capturedReason = flow.CurrentPauseReason;
            };

            // When headset recenter event fires during gameplay
            simPlatform.SimulateRecenter();

            // Then game pauses and requests seat re-confirmation (GP-CAL-06)
            Assert.AreEqual(AppState.Paused, flow.CurrentState);
            Assert.AreEqual(PauseReason.RecenterRequired, capturedReason);
        }
    }
}

