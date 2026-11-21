extends Node

## gs-interact's headless suite (res://examples/interact_selftest.tscn).
## Counts sections run to their last line as well as checks, because a script error
## aborts a section and not the run.

const EXPECTED_SECTIONS := 5
const EXPECTED_CHECKS := 56

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	print("gs-interact")
	_config()
	_focus()
	_hold()
	_request()
	_prompt()
	print("")
	_check(_sections == EXPECTED_SECTIONS, "every section ran to its last line (%d of %d)" % [_sections, EXPECTED_SECTIONS])
	_check(_passed + _failed == EXPECTED_CHECKS, "and the suite ran all %d of its checks (%d)" % [EXPECTED_CHECKS, _passed + _failed])
	print("%d passed, %d failed" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _config() -> void:
	var c := GSInteractConfig.new()
	_check(c.validate().ok, "defaults validate")
	_check(c.config_keys().size() >= 8, "every tunable is a config key", str(c.config_keys().size()))
	for k in ["range_m", "focus_angle", "require_line_of_sight", "max_candidates", "hold_seconds", "cooldown_seconds", "server_range_slack", "enabled"]:
		_check(c.has_key(k), "key %s exists" % k)
	c.range_m = 0.0
	_check(not c.validate().ok, "a zero range is refused")
	c.range_m = 2.5
	c.max_candidates = -1
	_check(not c.validate().ok, "a negative candidate count is refused, 0 means every")
	c.max_candidates = 0
	c.focus_angle = 200.0
	_check(not c.validate().ok, "a cone over 180 is refused")
	_sections += 1


func _focus() -> void:
	var c := GSInteractConfig.new()
	var near := {"id": "door", "distance": 1.0, "angle": 20.0}
	var far := {"id": "far", "distance": 3.0, "angle": 1.0}
	var off := {"id": "side", "distance": 1.0, "angle": 60.0}
	_check(GSInteractFocus.eligible(c, near), "a near target in the cone is eligible")
	_check(not GSInteractFocus.eligible(c, far), "beyond the range is not")
	_check(not GSInteractFocus.eligible(c, off), "outside the cone is not")
	_check(GSInteractFocus.eligible(c, {"distance": 3.0, "angle": 0.0, "range": 4.0}), "a target's own range overrides")
	_check(not GSInteractFocus.eligible(c, {"distance": 1.0, "visible": false}), "no line of sight is not")
	c.require_line_of_sight = false
	_check(GSInteractFocus.eligible(c, {"distance": 1.0, "visible": false}), "unless line of sight is off")
	c.require_line_of_sight = true
	_check(not GSInteractFocus.eligible(c, {"distance": 1.0, "enabled": false}), "a disabled target is not")
	_check(GSInteractFocus.pick(c, [far, off]) == -1, "nothing eligible picks -1")
	_check(GSInteractFocus.pick(c, []) == -1, "no candidates picks -1")
	var a := {"id": "a", "distance": 1.0, "angle": 20.0}
	var b := {"id": "b", "distance": 2.0, "angle": 5.0}
	_check(GSInteractFocus.pick(c, [a, b]) == 1, "the smaller angle wins")
	var p := {"id": "p", "distance": 2.0, "angle": 30.0, "priority": 5}
	_check(GSInteractFocus.pick(c, [a, b, p]) == 2, "priority beats angle")
	var t1 := {"id": "t1", "distance": 2.0, "angle": 10.0}
	var t2 := {"id": "t2", "distance": 1.0, "angle": 10.0}
	_check(GSInteractFocus.pick(c, [t1, t2]) == 1, "equal angles pick the nearer")
	c.max_candidates = 1
	_check(GSInteractFocus.pick(c, [t1, b, t2]) == 2, "a candidate limit keeps only the nearest")
	c.enabled = false
	_check(GSInteractFocus.pick(c, [a]) == -1, "disabled focuses nothing")
	_sections += 1


func _hold() -> void:
	var c := GSInteractConfig.new()
	var h := GSInteractHold.new()
	h.begin(c, &"door", 1.0)
	_check(not h.tick(0.4, true, &"door") and is_equal_approx(h.progress(), 0.4), "a hold fills with time")
	_check(not h.tick(0.4, true, &"door"), "and is not done early")
	_check(h.tick(0.3, true, &"door") and h.state == GSInteractHold.DONE, "it completes once it is full")
	_check(not h.tick(1.0, true, &"door"), "and never fires twice")
	h.begin(c, &"door", 1.0)
	h.tick(0.5, true, &"door")
	_check(not h.tick(0.1, false, &"door") and h.state == GSInteractHold.IDLE, "releasing cancels")
	h.begin(c, &"door", 1.0)
	h.tick(0.5, true, &"door")
	h.tick(0.1, true, &"other")
	_check(h.state == GSInteractHold.IDLE and h.progress() == 0.0, "looking at another target cancels")
	h.begin(c, &"btn", 0.0)
	_check(h.progress() == 1.0, "an instant use reads full at once")
	_check(h.tick(0.016, true, &"btn"), "and completes on the first tick")
	c.hold_seconds = 2.0
	h.begin(c, &"x")
	_check(is_equal_approx(h.required, 2.0), "the config default applies when the target says nothing")
	_sections += 1


func _request() -> void:
	var c := GSInteractConfig.new()
	var ok_world := {"distance": 2.0, "visible": true, "now": 10.0, "last_use": 5.0}
	_check(GSInteractRequest.validate(c, ok_world).ok, "an honest use is accepted")
	var far := GSInteractRequest.validate(c, {"distance": 4.0, "visible": true, "now": 10.0})
	_check(not far.ok and far.error.code == GSError.CODE_FORBIDDEN, "out of range is forbidden")
	_check(GSInteractRequest.validate(c, {"distance": 2.9, "visible": true, "now": 10.0}).ok, "the server slack forgives a step taken in flight")
	_check(GSInteractRequest.validate(c, {"distance": 4.0, "range": 5.0, "visible": true, "now": 10.0}).ok, "a target's own range is honoured")
	var blind := GSInteractRequest.validate(c, {"distance": 1.0, "visible": false, "now": 10.0})
	_check(not blind.ok and blind.error.message.contains("line of sight"), "no line of sight is refused with the reason")
	_check(GSInteractRequest.validate(c, {"distance": 1.0, "now": 10.0}).ok == false, "an unmeasured line of sight is not assumed")
	var fast := GSInteractRequest.validate(c, {"distance": 1.0, "visible": true, "now": 10.0, "last_use": 9.9})
	_check(not fast.ok and fast.error.code == GSError.CODE_RATE_LIMITED, "inside the cooldown is rate limited")
	_check(GSInteractRequest.validate(c, {"distance": 1.0, "visible": true, "now": 10.0, "target_enabled": false}).error.code == GSError.CODE_STATE, "a disabled target is a state error")
	c.enabled = false
	_check(GSInteractRequest.validate(c, ok_world).error.code == GSError.CODE_FORBIDDEN, "a disabled addon refuses every request")
	c.enabled = true
	c.cooldown_seconds = 0.0
	_check(GSInteractRequest.validate(c, {"distance": 1.0, "visible": true, "now": 1.0, "last_use": 1.0}).ok, "a cooldown of 0 is none")
	_sections += 1



func _check(ok: bool, what: String, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		print("  FAIL  ", what, "  ", extra)


func _prompt() -> void:
	var c := GSInteractConfig.new()
	var ok := GSInteractPrompt.describe(c, {"label": "Open", "in_range": true})
	_check(ok.state == GSInteractPrompt.USABLE and ok.text == "[E] Open", "a usable target reads [key] label")
	c.prompt_key = "F"
	_check(GSInteractPrompt.describe(c, {"label": "Open", "in_range": true}).text == "[F] Open", "a rebound key shows in the text")
	var lk := GSInteractPrompt.describe(c, {"label": "Locked door", "in_range": true, "state": &"locked"})
	_check(lk.state == GSInteractPrompt.LOCKED and lk.text == "Locked door", "a locked target shows the bare label")
	_check(GSInteractPrompt.describe(c, {}).state == GSInteractPrompt.HIDDEN, "an empty aim hides the prompt")
	_check(GSInteractPrompt.describe(c, {"label": "Open", "in_range": false}).state == GSInteractPrompt.HIDDEN, "out of range hides it")
	_check(GSInteractPrompt.describe(c, {"label": "", "in_range": true}).state == GSInteractPrompt.HIDDEN, "no label hides it")
	c.enabled = false
	_check(GSInteractPrompt.describe(c, {"label": "Open", "in_range": true}).state == GSInteractPrompt.HIDDEN, "a disabled addon shows nothing")
	var v := GSInteractPromptView.new()
	v.setup(GSInteractConfig.new())
	v.show_aim({"label": "Open", "in_range": true})
	_check(v.visible and v.text == "[E] Open", "the view shows the prompt")
	v.show_aim({})
	_check(not v.visible, "and hides on an empty aim")
	v.free()
	_sections += 1
