class_name GSInteractHold
extends RefCounted

## Hold-to-use as a small state machine with no clock of its own: the caller feeds it frame times. Releasing early, looking away (another target) or being disabled cancels; completing fires once.

const IDLE := 0
const HOLDING := 1
const DONE := 2

var state: int = IDLE
var target: StringName = &""
var elapsed: float = 0.0
var required: float = 0.0


## Starts holding on [param id]. [param seconds] under 0 uses the config's default; 0 completes on the first [method tick].
func begin(cfg: GSInteractConfig, id: StringName, seconds: float = -1.0) -> void:
	state = HOLDING
	target = id
	elapsed = 0.0
	required = cfg.hold_seconds if seconds < 0.0 else seconds


## Advances by [param delta] seconds while [param held] and [param focused] is the id the player is still aiming at. Returns true on the tick the hold completes, never again.
func tick(delta: float, held: bool, focused: StringName) -> bool:
	if state != HOLDING:
		return false
	if not held or focused != target:
		cancel()
		return false
	elapsed += maxf(delta, 0.0)
	if elapsed >= required:
		state = DONE
		return true
	return false


func cancel() -> void:
	state = IDLE
	target = &""
	elapsed = 0.0


## 0 to 1, for a progress ring; an instant use reads 1 once started.
func progress() -> float:
	if state == IDLE:
		return 0.0
	if required <= 0.0:
		return 1.0
	return clampf(elapsed / required, 0.0, 1.0)
