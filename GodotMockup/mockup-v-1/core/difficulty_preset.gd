class_name DifficultyPreset
extends Resource

## Configurable DifficultyPreset Resource (00-gameplay-overview.md §5.4, Rule 8).

@export var tier: int = ZenoEnums.DifficultyTier.STANDARD
@export var preset_name: String = "Standard"
@export_range(0.10, 0.85, 0.01) var reach_factor_k: float = 0.75
@export var target_radius_m: float = 0.10
@export var start_tempo_bpm: float = 60.0
@export var max_tempo_bpm: float = 80.0
@export var target_lifetime_beats: int = 2

# Mechanic-specific preset parameters (§6.2, §6.3, §6.7)
@export var m02_elevation_phi_deg: float = 45.0
@export var m03_abduction_theta_deg: float = 75.0
@export var m07_circle_radius_m: float = 0.18
@export var m07_cadence_hz: float = 0.75

static func create_for_tier(p_tier: int) -> DifficultyPreset:
	var preset := DifficultyPreset.new()
	preset.tier = p_tier
	match p_tier:
		ZenoEnums.DifficultyTier.GENTLE:
			preset.preset_name = "Gentle"
			preset.reach_factor_k = 0.60
			preset.target_radius_m = 0.12
			preset.start_tempo_bpm = 50.0
			preset.max_tempo_bpm = 70.0
			preset.target_lifetime_beats = 3
			preset.m02_elevation_phi_deg = 35.0
			preset.m03_abduction_theta_deg = 60.0
			preset.m07_circle_radius_m = 0.12
			preset.m07_cadence_hz = 0.50
		ZenoEnums.DifficultyTier.ACTIVE:
			preset.preset_name = "Active"
			preset.reach_factor_k = 0.85
			preset.target_radius_m = 0.08
			preset.start_tempo_bpm = 70.0
			preset.max_tempo_bpm = 90.0
			preset.target_lifetime_beats = 2
			preset.m02_elevation_phi_deg = 55.0
			preset.m03_abduction_theta_deg = 90.0
			preset.m07_circle_radius_m = 0.25
			preset.m07_cadence_hz = 1.00
		_:
			preset.preset_name = "Standard"
			preset.reach_factor_k = 0.75
			preset.target_radius_m = 0.10
			preset.start_tempo_bpm = 60.0
			preset.max_tempo_bpm = 80.0
			preset.target_lifetime_beats = 2
			preset.m02_elevation_phi_deg = 45.0
			preset.m03_abduction_theta_deg = 75.0
			preset.m07_circle_radius_m = 0.18
			preset.m07_cadence_hz = 0.75
	return preset
