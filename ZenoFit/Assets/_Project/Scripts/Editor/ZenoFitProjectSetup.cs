using System.Collections.Generic;
using System.IO;
using System.Linq;
using TMPro;
using Unity.XR.CoreUtils;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using UnityEditor.SceneManagement;
using UnityEditor.XR.Management;
using UnityEditor.XR.Management.Metadata;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.XR;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;
using UnityEngine.XR.Interaction.Toolkit;
using UnityEngine.XR.Interaction.Toolkit.UI;
using UnityEngine.XR.Management;
using UnityEngine.XR.OpenXR;
using UnityEngine.XR.OpenXR.Features;
using UnityEngine.XR.OpenXR.Features.Interactions;
using UnityEngine.XR.OpenXR.Features.MetaQuestSupport;
using ZenoFit.Calibration;
using ZenoFit.Core;
using ZenoFit.Exercises;
using ZenoFit.Feedback;
using ZenoFit.Safety;
using ZenoFit.Targets;
using ZenoFit.UI;

namespace ZenoFit.Editor
{
    /// <summary>
    /// In-Editor VR Setup & Scene/Asset Generator for ZenoFit (01-techstack.md, 02-quest-config.md).
    /// Safely configures OpenXR (Meta Quest 2/3/3S), PlayerSettings, ScriptableObject presets/configs,
    /// Target prefab, and all 6 scenes (00_Boot to 05_Results) using Unity Editor APIs.
    /// </summary>
    public static class ZenoFitProjectSetup
    {
        private const string ProjectRoot = "Assets/_Project";
        private const string ScenesFolder = "Assets/_Project/Scenes";
        private const string ScriptableObjectsFolder = "Assets/_Project/ScriptableObjects";
        private const string PrefabsFolder = "Assets/_Project/Prefabs";
        private const string MaterialsFolder = "Assets/_Project/Materials";

        private static AddAndRemoveRequest _packageRequest;

        [MenuItem("ZenoFit/1. Run Full VR Project Setup (Quest OpenXR + Scenes + Assets)", priority = 10)]
        public static void RunFullSetup()
        {
            EnsureFolders();
            ConfigurePlayerAndXrSettings();
            var generatedAssets = GenerateScriptableObjectsAndPrefabs();
            GenerateAllScenesAndBuildSettings(generatedAssets);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log("[ZenoFit Setup] Full VR Project Setup completed! Open 'Assets/_Project/Scenes/00_Boot.unity' and press Play, or run 'ZenoFit > 5. Update Packages (Quest OpenXR / Remove PICO)' to update UPM packages.");
        }

        [MenuItem("ZenoFit/2. Configure Meta Quest OpenXR & Player Settings", priority = 20)]
        public static void ConfigurePlayerAndXrSettings()
        {
            // 1. Player Settings (02-quest-config.md §2 Step 6, NF-04)
            PlayerSettings.companyName = "ZenoFit";
            PlayerSettings.productName = "SeatedVRFitness";
            PlayerSettings.colorSpace = ColorSpace.Linear;

            // Android Graphics API: Vulkan first, OpenGLES3 fallback
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[]
            {
                GraphicsDeviceType.Vulkan,
                GraphicsDeviceType.OpenGLES3
            });

            // Android API levels & IL2CPP ARM64
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel29;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;

            // NF-04: No internet permission
            PlayerSettings.Android.forceInternetPermission = false;

            // Add PLATFORM_QUEST scripting define on Android (02-quest-config.md §2 Step 10)
            AddScriptingDefineIfMissing(NamedBuildTarget.Android, "PLATFORM_QUEST");

            // Quality: 4x MSAA (02-quest-config.md §2 Step 7)
            QualitySettings.antiAliasing = 4;

            // 2. XR Plug-in Management: Enable OpenXR on Android & Standalone, remove PICO Loader
            ConfigureOpenXrLoadersAndFeatures();

            AssetDatabase.SaveAssets();
            Debug.Log("[ZenoFit Setup] Configured Android PlayerSettings (Linear, Vulkan, API 29+, IL2CPP, ARM64, PLATFORM_QUEST) and OpenXR (Meta Quest 2/3/3S, Touch & Touch Plus).");
        }

        [MenuItem("ZenoFit/3. Generate ScriptableObject Configs & Presets", priority = 30)]
        public static void MenuGenerateScriptableObjects()
        {
            EnsureFolders();
            GenerateScriptableObjectsAndPrefabs();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log("[ZenoFit Setup] Generated ScriptableObjects and Target prefab under Assets/_Project/.");
        }

        [MenuItem("ZenoFit/4. Generate All 6 Scenes (00_Boot to 05_Results) & Build Settings", priority = 40)]
        public static void MenuGenerateScenes()
        {
            EnsureFolders();
            var assets = GenerateScriptableObjectsAndPrefabs();
            GenerateAllScenesAndBuildSettings(assets);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log("[ZenoFit Setup] Generated 00_Boot to 05_Results scenes and updated Build Settings.");
        }

        [MenuItem("ZenoFit/5. Update Packages (Add Meta OpenXR + ARFoundation + XRI, Remove PICO)", priority = 50)]
        public static void UpdatePackagesForQuest()
        {
            // Clean up PICO-specific asset files first so removing the package leaves zero broken script references
            DeletePicoAssetsIfPresent();

            string[] packagesToAdd =
            {
                "com.unity.xr.interaction.toolkit@3.0.10",
                "com.unity.xr.meta-openxr",
                "com.unity.xr.arfoundation"
            };

            string[] packagesToRemove =
            {
                "com.unity.xr.picoxr",
                "com.unity.pico.livepreview"
            };

            Debug.Log("[ZenoFit Setup] Updating UPM packages via Client.AddAndRemove...");
            _packageRequest = Client.AddAndRemove(packagesToAdd, packagesToRemove);
            EditorApplication.update += PollPackageUpdate;
        }

        [MenuItem("ZenoFit/6. Open Test Runner (Run AT-01..AT-16 Unit Tests)", priority = 60)]
        public static void OpenTestRunnerWindow()
        {
            EditorApplication.ExecuteMenuItem("Window/General/Test Runner");
        }

        private static void PollPackageUpdate()
        {
            if (_packageRequest == null || !_packageRequest.IsCompleted)
                return;

            EditorApplication.update -= PollPackageUpdate;
            if (_packageRequest.Status == StatusCode.Success)
            {
                Debug.Log("[ZenoFit Setup] UPM packages updated: Meta OpenXR, AR Foundation, and XRI 3.x installed; PICO packages removed.");
            }
            else
            {
                Debug.LogError($"[ZenoFit Setup] Package update error: {_packageRequest.Error?.message}");
            }
        }

        private static void DeletePicoAssetsIfPresent()
        {
            string[] picoAssetPaths =
            {
                "Assets/Resources/PXR_DebuggerPanel.prefab",
                "Assets/Resources/PXR_PICODebugger.prefab",
                "Assets/Resources/PXR_PicoDebuggerSO.asset",
                "Assets/Resources/PXR_ProjectSetting.asset",
                "Assets/XR/Loaders/PXR_Loader.asset",
                "Assets/XR/Loaders/PXR_PTLoader.asset",
                "Assets/XR/Settings/PXR_PTSettings.asset",
                "Assets/XR/Settings/PXR_Settings.asset"
            };

            foreach (string path in picoAssetPaths)
            {
                if (File.Exists(path) || AssetDatabase.LoadMainAssetAtPath(path) != null)
                {
                    AssetDatabase.DeleteAsset(path);
                }
            }
        }

        private static void ConfigureOpenXrLoadersAndFeatures()
        {
            XRGeneralSettingsPerBuildTarget generalSettings = XRGeneralSettingsPerBuildTarget.XRGeneralSettingsForBuildTarget(BuildTargetGroup.Android) != null
                ? AssetDatabase.LoadAssetAtPath<XRGeneralSettingsPerBuildTarget>("Assets/XR/XRGeneralSettingsPerBuildTarget.asset")
                : null;

            string openXrLoaderTypeName = typeof(OpenXRLoader).FullName;

            foreach (BuildTargetGroup group in new[] { BuildTargetGroup.Android, BuildTargetGroup.Standalone })
            {
                XRGeneralSettings groupSettings = XRGeneralSettingsPerBuildTarget.XRGeneralSettingsForBuildTarget(group);
                if (groupSettings != null && groupSettings.Manager != null)
                {
                    // Remove any non-OpenXR loaders (such as PXR_Loader / PXR_PTLoader)
                    var existingLoaders = groupSettings.Manager.activeLoaders.ToList();
                    foreach (var loader in existingLoaders)
                    {
                        if (loader == null || loader.GetType() != typeof(OpenXRLoader))
                        {
                            string loaderTypeName = loader != null ? loader.GetType().FullName : string.Empty;
                            if (!string.IsNullOrEmpty(loaderTypeName))
                            {
                                XRPackageMetadataStore.RemoveLoader(groupSettings.Manager, loaderTypeName, group);
                            }
                        }
                    }

                    // Assign OpenXRLoader on both Android and Standalone
                    XRPackageMetadataStore.AssignLoader(groupSettings.Manager, openXrLoaderTypeName, group);
                    EditorUtility.SetDirty(groupSettings.Manager);
                    EditorUtility.SetDirty(groupSettings);
                }

                // Configure OpenXR settings for the build target group
                OpenXRSettings openXrSettings = OpenXRSettings.GetSettingsForBuildTargetGroup(group);
                if (openXrSettings != null)
                {
                    openXrSettings.renderMode = OpenXRSettings.RenderMode.SinglePassInstanced;
                    openXrSettings.depthSubmissionMode = OpenXRSettings.DepthSubmissionMode.Depth16Bit;

                    foreach (OpenXRFeature feature in openXrSettings.GetFeatures())
                    {
                        if (feature == null)
                            continue;

                        // Enable Touch & Touch Plus (and Touch Pro) controller profiles (02-quest-config.md §2 Step 5)
                        if (feature is OculusTouchControllerProfile ||
                            feature is MetaQuestTouchPlusControllerProfile ||
                            feature is MetaQuestTouchProControllerProfile)
                        {
                            feature.enabled = true;
                        }
                        // Enable Meta Quest Support on Android (Quest 2, 3, 3S)
                        else if (feature is MetaQuestFeature questFeature)
                        {
                            questFeature.enabled = (group == BuildTargetGroup.Android);
                            SerializedObject so = new SerializedObject(questFeature);
                            SerializedProperty removeNetProp = so.FindProperty("forceRemoveInternetPermission");
                            if (removeNetProp != null)
                            {
                                removeNetProp.boolValue = true; // NF-04: no internet permission
                            }
                            so.ApplyModifiedPropertiesWithoutUndo();
                            EditorUtility.SetDirty(questFeature);
                        }
                        // D-03 / Rule 4: Disable hand tracking / hand interaction profiles
                        else if ((feature.name != null && feature.name.Contains("Hand")) || feature.GetType().Name.Contains("Hand"))
                        {
                            feature.enabled = false;
                        }

                        EditorUtility.SetDirty(feature);
                    }

                    EditorUtility.SetDirty(openXrSettings);
                }
            }

            if (generalSettings != null)
            {
                EditorUtility.SetDirty(generalSettings);
            }
        }

        private static void AddScriptingDefineIfMissing(NamedBuildTarget buildTarget, string symbol)
        {
            PlayerSettings.GetScriptingDefineSymbols(buildTarget, out string[] defines);
            if (!defines.Contains(symbol))
            {
                var list = new List<string>(defines) { symbol };
                PlayerSettings.SetScriptingDefineSymbols(buildTarget, list.ToArray());
            }
        }

        private class GeneratedProjectAssets
        {
            public DifficultyPreset GentlePreset;
            public DifficultyPreset StandardPreset;
            public DifficultyPreset ActivePreset;
            public CalibrationConfig CalibrationConfig;
            public SafetyConfig SafetyConfig;
            public ForwardArmReachConfig ForwardReachConfig;
            public AlternatingArmReachConfig AlternatingReachConfig;
            public SideArmRaiseConfig SideArmRaiseConfig;
            public ForwardPressConfig ForwardPressConfig;
            public SeatedBoxingConfig SeatedBoxingConfig;
            public Target TargetPrefab;
            public Material TargetMaterial;
            public Material FloorMaterial;
            public Material ControllerMaterial;
        }

        private static GeneratedProjectAssets GenerateScriptableObjectsAndPrefabs()
        {
            var assets = new GeneratedProjectAssets();

            // 1. Difficulty Presets (§5.3)
            assets.GentlePreset = CreateOrLoadAsset<DifficultyPreset>($"{ScriptableObjectsFolder}/Difficulty_Gentle.asset");
            DifficultyPreset.ApplySpecDefaults(assets.GentlePreset, DifficultyTier.Gentle);
            EditorUtility.SetDirty(assets.GentlePreset);

            assets.StandardPreset = CreateOrLoadAsset<DifficultyPreset>($"{ScriptableObjectsFolder}/Difficulty_Standard.asset");
            DifficultyPreset.ApplySpecDefaults(assets.StandardPreset, DifficultyTier.Standard);
            EditorUtility.SetDirty(assets.StandardPreset);

            assets.ActivePreset = CreateOrLoadAsset<DifficultyPreset>($"{ScriptableObjectsFolder}/Difficulty_Active.asset");
            DifficultyPreset.ApplySpecDefaults(assets.ActivePreset, DifficultyTier.Active);
            EditorUtility.SetDirty(assets.ActivePreset);

            // 2. Calibration & Safety Configs
            assets.CalibrationConfig = CreateOrLoadAsset<CalibrationConfig>($"{ScriptableObjectsFolder}/CalibrationConfig.asset");
            EditorUtility.SetDirty(assets.CalibrationConfig);

            assets.SafetyConfig = CreateOrLoadAsset<SafetyConfig>($"{ScriptableObjectsFolder}/SafetyConfig.asset");
            EditorUtility.SetDirty(assets.SafetyConfig);

            // 3. Five Exercise Configs (Rule 11)
            assets.ForwardReachConfig = CreateOrLoadAsset<ForwardArmReachConfig>($"{ScriptableObjectsFolder}/Ex01_ForwardArmReachConfig.asset");
            EditorUtility.SetDirty(assets.ForwardReachConfig);

            assets.AlternatingReachConfig = CreateOrLoadAsset<AlternatingArmReachConfig>($"{ScriptableObjectsFolder}/Ex02_AlternatingArmReachConfig.asset");
            EditorUtility.SetDirty(assets.AlternatingReachConfig);

            assets.SideArmRaiseConfig = CreateOrLoadAsset<SideArmRaiseConfig>($"{ScriptableObjectsFolder}/Ex03_SideArmRaiseConfig.asset");
            EditorUtility.SetDirty(assets.SideArmRaiseConfig);

            assets.ForwardPressConfig = CreateOrLoadAsset<ForwardPressConfig>($"{ScriptableObjectsFolder}/Ex04_ForwardPressConfig.asset");
            EditorUtility.SetDirty(assets.ForwardPressConfig);

            assets.SeatedBoxingConfig = CreateOrLoadAsset<SeatedBoxingConfig>($"{ScriptableObjectsFolder}/Ex05_SeatedBoxingConfig.asset");
            EditorUtility.SetDirty(assets.SeatedBoxingConfig);

            // 4. Calm URP Materials
            assets.TargetMaterial = CreateOrUpdateUrpMaterial($"{MaterialsFolder}/M_TargetSphere.mat", new Color(0.20f, 0.62f, 0.98f, 1f));
            assets.FloorMaterial = CreateOrUpdateUrpMaterial($"{MaterialsFolder}/M_CalmSeatedFloor.mat", new Color(0.14f, 0.18f, 0.24f, 1f));
            assets.ControllerMaterial = CreateOrUpdateUrpMaterial($"{MaterialsFolder}/M_HandTipCue.mat", new Color(0.35f, 0.85f, 0.75f, 1f));

            // 5. Target Sphere Prefab
            assets.TargetPrefab = CreateOrUpdateTargetPrefab($"{PrefabsFolder}/TargetSphere.prefab", assets.TargetMaterial);

            return assets;
        }

        private static Target CreateOrUpdateTargetPrefab(string prefabPath, Material targetMat)
        {
            GameObject tempRoot = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            tempRoot.name = "TargetSphere";

            var sphereCol = tempRoot.GetComponent<SphereCollider>();
            sphereCol.isTrigger = true;
            sphereCol.radius = 0.5f;

            var meshRenderer = tempRoot.GetComponent<MeshRenderer>();
            if (targetMat != null)
                meshRenderer.sharedMaterial = targetMat;

            // Non-color hand badge ("L" / "R" / "L/R") so color is never the sole indicator (§6.0)
            GameObject badgeGo = new GameObject("HandBadgeText");
            badgeGo.transform.SetParent(tempRoot.transform, false);
            badgeGo.transform.localPosition = new Vector3(0f, 0f, -0.55f);
            badgeGo.transform.localScale = Vector3.one * 0.14f;
            var tmp = badgeGo.AddComponent<TextMeshPro>();
            tmp.text = "L/R";
            tmp.fontSize = 18f;
            tmp.alignment = TextAlignmentOptions.Center;
            tmp.color = Color.white;

            Target targetComp = tempRoot.AddComponent<Target>();
            var so = new SerializedObject(targetComp);
            so.FindProperty("_meshRenderer").objectReferenceValue = meshRenderer;
            so.FindProperty("_handLabelText").objectReferenceValue = tmp;
            so.ApplyModifiedPropertiesWithoutUndo();

            GameObject savedPrefab = PrefabUtility.SaveAsPrefabAsset(tempRoot, prefabPath);
            Object.DestroyImmediate(tempRoot);
            return savedPrefab.GetComponent<Target>();
        }

        private static void GenerateAllScenesAndBuildSettings(GeneratedProjectAssets assets)
        {
            string bootPath = $"{ScenesFolder}/00_Boot.unity";
            string mainMenuPath = $"{ScenesFolder}/01_MainMenu.unity";
            string calibrationPath = $"{ScenesFolder}/02_Calibration.unity";
            string exerciseSelectPath = $"{ScenesFolder}/03_ExerciseSelect.unity";
            string gameplayPath = $"{ScenesFolder}/04_Gameplay.unity";
            string resultsPath = $"{ScenesFolder}/05_Results.unity";

            // Build 00_Boot scene with full seated XR Origin (Device mode) + HandTips + GameFlow + WorldUI
            BuildBootScene(bootPath, assets);

            // Build additive sub-scenes (01..05) with calm environment markers
            BuildAdditiveSubScene(mainMenuPath, "01_MainMenu_Anchor");
            BuildAdditiveSubScene(calibrationPath, "02_Calibration_Anchor");
            BuildAdditiveSubScene(exerciseSelectPath, "03_ExerciseSelect_Anchor");
            BuildAdditiveSubScene(gameplayPath, "04_Gameplay_Anchor");
            BuildAdditiveSubScene(resultsPath, "05_Results_Anchor");

            // Also update existing Assets/Scenes/VR Scene.unity if present so both scenes have the seated rig
            if (File.Exists("Assets/Scenes/VR Scene.unity"))
            {
                BuildBootScene("Assets/Scenes/VR Scene.unity", assets);
            }

            // Re-open 00_Boot as the active scene in Editor
            EditorSceneManager.OpenScene(bootPath, OpenSceneMode.Single);

            // Configure EditorBuildSettings so 00_Boot is index 0 and 01..05 can be loaded additively
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(bootPath, true),
                new EditorBuildSettingsScene(mainMenuPath, true),
                new EditorBuildSettingsScene(calibrationPath, true),
                new EditorBuildSettingsScene(exerciseSelectPath, true),
                new EditorBuildSettingsScene(gameplayPath, true),
                new EditorBuildSettingsScene(resultsPath, true)
            };
        }

        private static void BuildBootScene(string scenePath, GeneratedProjectAssets assets)
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // 1. Calm Directional Light (02-quest-config.md §2 Step 7: no expensive shadows, soft warm light)
            GameObject lightGo = new GameObject("Directional Light (Calm)");
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(0.96f, 0.95f, 0.92f, 1f);
            light.intensity = 0.9f;
            light.shadows = LightShadows.None;
            lightGo.transform.rotation = Quaternion.Euler(45f, -30f, 0f);

            // 2. Static Reference Floor Platform (GP-COMFORT-01: static reference prevents cybersickness, zero locomotion)
            GameObject floorGo = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            floorGo.name = "StaticSeatedReferencePlatform";
            floorGo.transform.position = new Vector3(0f, -1.15f, 0f);
            floorGo.transform.localScale = new Vector3(3.0f, 0.02f, 3.0f);
            if (assets.FloorMaterial != null)
            {
                floorGo.GetComponent<MeshRenderer>().sharedMaterial = assets.FloorMaterial;
            }

            // 3. XR Interaction Manager & EventSystem (XRI 3.x UI interaction)
            GameObject xriManagerGo = new GameObject("XR Interaction Manager");
            var xriManager = xriManagerGo.AddComponent<XRInteractionManager>();

            GameObject eventSystemGo = new GameObject("EventSystem");
            eventSystemGo.AddComponent<EventSystem>();
            eventSystemGo.AddComponent<XRUIInputModule>();

            // 4. XR Origin (Seated / Device Tracking Origin Mode - D-05, 02-quest-config.md §2 Step 9)
            GameObject xrOriginGo = new GameObject("XR Origin (Seated VR)");
            var xrOrigin = xrOriginGo.AddComponent<XROrigin>();
            xrOrigin.Origin = xrOriginGo;
            xrOrigin.RequestedTrackingOriginMode = XROrigin.TrackingOriginMode.Device;
            xrOrigin.CameraYOffset = 0f; // Device mode places origin at seated head/device level

            GameObject cameraOffsetGo = new GameObject("Camera Offset");
            cameraOffsetGo.transform.SetParent(xrOriginGo.transform, false);
            cameraOffsetGo.transform.localPosition = Vector3.zero;
            xrOrigin.CameraFloorOffsetObject = cameraOffsetGo;

            // Main Camera with TrackedPoseDriver
            GameObject mainCamGo = new GameObject("Main Camera");
            mainCamGo.tag = "MainCamera";
            mainCamGo.transform.SetParent(cameraOffsetGo.transform, false);
            var cam = mainCamGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.10f, 0.14f, 0.20f, 1f);
            cam.nearClipPlane = 0.01f;
            cam.farClipPlane = 100f;
            mainCamGo.AddComponent<AudioListener>();

            var headPoseDriver = mainCamGo.AddComponent<TrackedPoseDriver>();
            headPoseDriver.positionInput = new InputActionProperty(new InputAction("HeadPosition", expectedControlType: "Vector3", binding: "<XRHMD>/centerEyePosition"));
            headPoseDriver.rotationInput = new InputActionProperty(new InputAction("HeadRotation", expectedControlType: "Quaternion", binding: "<XRHMD>/centerEyeRotation"));
            xrOrigin.Camera = cam;

            // Left & Right Controllers with HandTip sphere colliders (radius 0.04 m [P])
            HandTipTracker leftHandTip = CreateTrackedControllerWithHandTip(
                cameraOffsetGo.transform,
                "Left Controller",
                Hand.Left,
                "<XRController>{LeftHand}/devicePosition",
                "<XRController>{LeftHand}/deviceRotation",
                assets.ControllerMaterial);

            HandTipTracker rightHandTip = CreateTrackedControllerWithHandTip(
                cameraOffsetGo.transform,
                "Right Controller",
                Hand.Right,
                "<XRController>{RightHand}/devicePosition",
                "<XRController>{RightHand}/deviceRotation",
                assets.ControllerMaterial);

            // 5. ZenoFit Persistent Systems & World-Space UI
            GameObject systemsGo = new GameObject("ZenoFitSystems");

            var spawner = systemsGo.AddComponent<TargetSpawner>();
            var spawnerSo = new SerializedObject(spawner);
            spawnerSo.FindProperty("_targetPrefab").objectReferenceValue = assets.TargetPrefab;
            spawnerSo.FindProperty("_defaultTargetMaterial").objectReferenceValue = assets.TargetMaterial;
            spawnerSo.ApplyModifiedPropertiesWithoutUndo();

            systemsGo.AddComponent<AudioSource>();
            var audioFeedback = systemsGo.AddComponent<AudioFeedbackController>();

            var calibrationFlow = systemsGo.AddComponent<CalibrationFlow>();
            var calSo = new SerializedObject(calibrationFlow);
            calSo.FindProperty("_config").objectReferenceValue = assets.CalibrationConfig;
            calSo.FindProperty("_headTransform").objectReferenceValue = mainCamGo.transform;
            calSo.FindProperty("_leftHandTip").objectReferenceValue = leftHandTip;
            calSo.FindProperty("_rightHandTip").objectReferenceValue = rightHandTip;
            calSo.ApplyModifiedPropertiesWithoutUndo();

            var gameplayController = systemsGo.AddComponent<GameplaySessionController>();
            var gpSo = new SerializedObject(gameplayController);
            gpSo.FindProperty("_targetSpawner").objectReferenceValue = spawner;
            gpSo.FindProperty("_leftHandTip").objectReferenceValue = leftHandTip;
            gpSo.FindProperty("_rightHandTip").objectReferenceValue = rightHandTip;
            gpSo.FindProperty("_audioFeedback").objectReferenceValue = audioFeedback;
            gpSo.FindProperty("_forwardReachConfig").objectReferenceValue = assets.ForwardReachConfig;
            gpSo.FindProperty("_alternatingReachConfig").objectReferenceValue = assets.AlternatingReachConfig;
            gpSo.FindProperty("_sideArmRaiseConfig").objectReferenceValue = assets.SideArmRaiseConfig;
            gpSo.FindProperty("_forwardPressConfig").objectReferenceValue = assets.ForwardPressConfig;
            gpSo.FindProperty("_seatedBoxingConfig").objectReferenceValue = assets.SeatedBoxingConfig;
            gpSo.ApplyModifiedPropertiesWithoutUndo();

            var safetyCoordinator = systemsGo.AddComponent<SafetyCoordinator>();
            var safeSo = new SerializedObject(safetyCoordinator);
            safeSo.FindProperty("_config").objectReferenceValue = assets.SafetyConfig;
            safeSo.FindProperty("_headTransform").objectReferenceValue = mainCamGo.transform;
            safeSo.FindProperty("_leftHandTip").objectReferenceValue = leftHandTip;
            safeSo.FindProperty("_rightHandTip").objectReferenceValue = rightHandTip;
            safeSo.ApplyModifiedPropertiesWithoutUndo();

            var gameFlow = systemsGo.AddComponent<GameFlow>();
            var flowSo = new SerializedObject(gameFlow);
            flowSo.FindProperty("_headTransform").objectReferenceValue = mainCamGo.transform;
            flowSo.FindProperty("_leftHandTip").objectReferenceValue = leftHandTip;
            flowSo.FindProperty("_rightHandTip").objectReferenceValue = rightHandTip;
            flowSo.FindProperty("_calibrationFlow").objectReferenceValue = calibrationFlow;
            flowSo.FindProperty("_gameplayController").objectReferenceValue = gameplayController;
            flowSo.FindProperty("_safetyCoordinator").objectReferenceValue = safetyCoordinator;
            flowSo.FindProperty("_targetSpawner").objectReferenceValue = spawner;
            flowSo.FindProperty("_audioFeedback").objectReferenceValue = audioFeedback;
            flowSo.FindProperty("_gentlePreset").objectReferenceValue = assets.GentlePreset;
            flowSo.FindProperty("_standardPreset").objectReferenceValue = assets.StandardPreset;
            flowSo.FindProperty("_activePreset").objectReferenceValue = assets.ActivePreset;
            flowSo.ApplyModifiedPropertiesWithoutUndo();

            var worldUi = systemsGo.AddComponent<ZenoFitWorldUI>();
            var uiSo = new SerializedObject(worldUi);
            uiSo.FindProperty("_gameFlow").objectReferenceValue = gameFlow;
            uiSo.FindProperty("_calibrationFlow").objectReferenceValue = calibrationFlow;
            uiSo.FindProperty("_gameplayController").objectReferenceValue = gameplayController;
            uiSo.ApplyModifiedPropertiesWithoutUndo();

            EditorSceneManager.SaveScene(scene, scenePath);
        }

        private static HandTipTracker CreateTrackedControllerWithHandTip(
            Transform parent,
            string controllerName,
            Hand hand,
            string posBinding,
            string rotBinding,
            Material cueMaterial)
        {
            GameObject controllerGo = new GameObject(controllerName);
            controllerGo.transform.SetParent(parent, false);
            controllerGo.transform.localPosition = new Vector3(hand == Hand.Left ? -0.22f : 0.22f, -0.20f, 0.35f);

            var poseDriver = controllerGo.AddComponent<TrackedPoseDriver>();
            poseDriver.positionInput = new InputActionProperty(new InputAction($"{hand}Position", expectedControlType: "Vector3", binding: posBinding));
            poseDriver.rotationInput = new InputActionProperty(new InputAction($"{hand}Rotation", expectedControlType: "Quaternion", binding: rotBinding));

            // HandTip Sphere (radius 0.04 m [P], 02-quest-config.md §2 Step 9)
            GameObject tipGo = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            tipGo.name = $"{hand}HandTip";
            tipGo.transform.SetParent(controllerGo.transform, false);
            tipGo.transform.localPosition = new Vector3(0f, 0f, 0.05f);
            tipGo.transform.localScale = Vector3.one * (HitDetector.DefaultHandTipRadiusM * 2f);

            if (cueMaterial != null)
            {
                tipGo.GetComponent<MeshRenderer>().sharedMaterial = cueMaterial;
            }

            var sphereCol = tipGo.GetComponent<SphereCollider>();
            sphereCol.isTrigger = true;
            sphereCol.radius = 0.5f;

            var tracker = tipGo.AddComponent<HandTipTracker>();
            tracker.Configure(hand, HitDetector.DefaultHandTipRadiusM);

            return tracker;
        }

        private static void BuildAdditiveSubScene(string scenePath, string anchorName)
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            GameObject anchor = new GameObject(anchorName);
            anchor.transform.position = Vector3.zero;
            EditorSceneManager.SaveScene(scene, scenePath);
        }

        private static T CreateOrLoadAsset<T>(string assetPath) where T : ScriptableObject
        {
            T existing = AssetDatabase.LoadAssetAtPath<T>(assetPath);
            if (existing != null)
                return existing;

            T instance = ScriptableObject.CreateInstance<T>();
            AssetDatabase.CreateAsset(instance, assetPath);
            return instance;
        }

        private static Material CreateOrUpdateUrpMaterial(string assetPath, Color color)
        {
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(assetPath);
            if (mat == null)
            {
                Shader shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
                mat = new Material(shader);
                AssetDatabase.CreateAsset(mat, assetPath);
            }
            mat.color = color;
            if (mat.HasProperty("_BaseColor"))
                mat.SetColor("_BaseColor", color);
            EditorUtility.SetDirty(mat);
            return mat;
        }

        private static void EnsureFolders()
        {
            string[] folders =
            {
                ProjectRoot,
                ScenesFolder,
                ScriptableObjectsFolder,
                PrefabsFolder,
                MaterialsFolder,
                "Assets/_Project/Audio",
                "Assets/_Project/Art",
                "Assets/_Project/Tests/PlayMode"
            };

            foreach (string folder in folders)
            {
                if (!Directory.Exists(folder))
                {
                    Directory.CreateDirectory(folder);
                }
            }
            AssetDatabase.Refresh();
        }
    }
}
