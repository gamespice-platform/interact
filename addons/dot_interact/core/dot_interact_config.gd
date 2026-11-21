class_name GSInteractConfig
extends GSConfig

## Every tunable of press-to-use interaction. A game binds it with GSGameConfigBinder (kind `interact`) for cvars and the workbench; `cfg/addon/dot_interact/*.yml`, `DOT_INTERACT_*` and `--interact-*` layer over these defaults.

const ADDON := "dot-interact"

## Master switch: off, nothing is focusable and every use request is refused.
@export var enabled: bool = true

@export_group("Focus")
## Metres from the eye a target may be used from, unless the target declares its own range.
@export_range(0.5, 20.0, 0.1) var range_m: float = 2.5
## Half-angle of the cone around the view direction a target must sit in, in degrees; 0 is any direction.
@export_range(0.0, 180.0, 1.0) var focus_angle: float = 35.0
## Whether a target must be in line of sight to be focused or used.
@export var require_line_of_sight: bool = true
## The most candidates one focus pick considers, nearest first; 0 is every candidate.
@export_range(0, 256, 1) var max_candidates: int = 0

@export_group("Use")
## Seconds a use must be held when the target does not say; 0 is an instant press.
@export_range(0.0, 30.0, 0.05) var hold_seconds: float = 0.0
## Seconds before the same actor may use again.
@export_range(0.0, 10.0, 0.05) var cooldown_seconds: float = 0.25
## Metres the server adds to the range when judging a request, so latency and a step taken while the packet flew do not refuse an honest use.
@export_range(0.0, 5.0, 0.05) var server_range_slack: float = 0.5

@export_group("Prompt")
## Text of the use key in the prompt, "[E] Open"; a game with a rebound key sets it.
@export var prompt_key: String = "E"
## Shown instead of "[key] label" when the target is locked.
@export var prompt_locked_suffix: String = ""


func env_prefix() -> String:
	return "DOT_INTERACT_"


func cli_prefix() -> String:
	return "--interact-"


func validate() -> GSResult:
	if range_m <= 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "interact range_m %.2f must be positive" % range_m)
	if focus_angle < 0.0 or focus_angle > 180.0:
		return GSResult.fail(GSError.CODE_INVALID, "interact focus_angle %.0f must be 0 to 180 (0 is any direction)" % focus_angle)
	if max_candidates < 0:
		return GSResult.fail(GSError.CODE_INVALID, "interact max_candidates %d is negative (0 is every candidate)" % max_candidates)
	if hold_seconds < 0.0 or cooldown_seconds < 0.0 or server_range_slack < 0.0:
		return GSResult.fail(GSError.CODE_INVALID, "interact hold_seconds, cooldown_seconds and server_range_slack cannot be negative")
	return GSResult.success(self)


## Defaults, then `cfg/addon/dot_interact/*.yml` and the game tier, then environment and command line.
static func from_files() -> GSResult:
	var cfg := GSInteractConfig.new()
	var files := GSAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "interact %s range %.1f m cone %.0f° los %s hold %.2fs cooldown %.2fs slack %.1f m" % [
		"on" if enabled else "disabled", range_m, focus_angle, require_line_of_sight, hold_seconds, cooldown_seconds, server_range_slack]
