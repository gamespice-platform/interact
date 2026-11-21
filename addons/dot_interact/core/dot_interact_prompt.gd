class_name DotInteractPrompt
extends RefCounted

## The text and state of the look-at prompt as a pure model: "[E] Open" while something usable is in reach, the bare label when it is locked, nothing otherwise. A view only draws what [method describe] returns.
##
## An aim is a Dictionary: `label` (String), `in_range` (bool), optionally `state` (`&"locked"` for a locked target).

const HIDDEN := 0
const USABLE := 1
const LOCKED := 2


## Returns `{state, text}`; the state is HIDDEN, USABLE or LOCKED. An empty aim, an empty label or a target out of range is HIDDEN.
static func describe(cfg: DotInteractConfig, aim: Dictionary) -> Dictionary:
	var label := String(aim.get("label", ""))
	if aim.is_empty() or label == "" or not bool(aim.get("in_range", false)) or not cfg.enabled:
		return {"state": HIDDEN, "text": ""}
	if aim.get("state") == &"locked":
		return {"state": LOCKED, "text": label + cfg.prompt_locked_suffix}
	return {"state": USABLE, "text": "[%s] %s" % [cfg.prompt_key, label]}
