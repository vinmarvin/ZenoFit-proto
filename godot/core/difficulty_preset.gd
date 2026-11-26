class_name DifficultyPreset
extends Resource

## Configurable DifficultyPreset Resource for ZenoFit v1.0.
## Caps reach_factor_k strictly at <= 0.85 so targets never exceed comfortable seated reach.

@export var tier: int = ZenoEnums.DifficultyTier.STANDARD
@export var preset_name: String = "Standard"
@export_range(0.10, 0.85, 0.01) var reach_factor_k: float = 0.75
@export var target_radius_m: float = 0.10
@export var start_tempo_bpm: float = 60.0
@export var max_tempo_bpm: float = 80.0
@export var target_lifetime_beats: int = 2

# Exercise-specific tunables
@export var reach_elevation_phi_deg: float = 45.0
@export var orbit_radius_m: float = 0.18
@export var orbit_cadence_hz: float = 0.75
@export var wrist_target_deg: float = 55.0

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
			preset.reach_elevation_phi_deg = 35.0
			preset.orbit_radius_m = 0.14
			preset.orbit_cadence_hz = 0.55
			preset.wrist_target_deg = 45.0
		ZenoEnums.DifficultyTier.ACTIVE:
			preset.preset_name = "Active"
			preset.reach_factor_k = 0.85
			preset.target_radius_m = 0.085
			preset.start_tempo_bpm = 70.0
			preset.max_tempo_bpm = 90.0
			preset.target_lifetime_beats = 2
			preset.reach_elevation_phi_deg = 52.0
			preset.orbit_radius_m = 0.22
			preset.orbit_cadence_hz = 0.90
			preset.wrist_target_deg = 65.0
		_:
			preset.preset_name = "Standard"
			preset.reach_factor_k = 0.75
			preset.target_radius_m = 0.10
			preset.start_tempo_bpm = 60.0
			preset.max_tempo_bpm = 80.0
			preset.target_lifetime_beats = 2
			preset.reach_elevation_phi_deg = 45.0
			preset.orbit_radius_m = 0.18
			preset.orbit_cadence_hz = 0.75
			preset.wrist_target_deg = 55.0
	return preset
