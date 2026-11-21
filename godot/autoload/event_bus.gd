extends Node

## Global EventBus autoload for decoupled communication across UI, Mechanics, Safety, and Mascot.

signal state_changed(previous_state: int, new_state: int)
signal round_started(round_index: int, mechanic_id: int)
signal round_ended(round_index: int, mechanic_id: int, round_score: int)
signal target_hit(hand: int, points: int, streak: int, is_solid: bool)
signal target_missed()
signal session_paused(reason: int, message: String)
signal resume_countdown_tick(seconds_remaining: float)
signal safety_cue(message: String)
signal mascot_poked(hand: int)
signal mascot_demo_requested(mechanic_id: int)
