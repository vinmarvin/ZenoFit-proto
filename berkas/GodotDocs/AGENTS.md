# Godot build rules (ZenoFit Mockup v1)

- Godot 4.7+ (`4.7.2.stable`), GDScript only, Compatibility renderer (`gl_compatibility`), OpenXR enabled (`Reference Space = Local`).
- Spec space is `+X` right, `+Y` up, `+Z` FORWARD. Godot is `-Z` forward (`+Z` back). Convert ONLY via `core/spec_space.gd`.
  Yaw: spec positive = turn right; Godot positive = turn left. See `MarkdownGuideForAIReconstruction/03-godot-build.md` §3.1.
- Pure maths in `core/` with automated tests in `tests/` that use the SAME numbers as `MarkdownGuideForAIReconstruction/16-acceptance-tests.md`.
- Platform-specific calls (haptics, passthrough, recenter signal) only through the `autoload/platform.gd` autoload.
- Use a different Android package name (`com.zenofit.godot.mockup`) from the Unity build (`com.zenofit.seatedvrfitness`).
- Not a medical device. Never add health or treatment claims to UI text or documentation.
