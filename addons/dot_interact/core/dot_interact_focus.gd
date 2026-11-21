class_name DotInteractFocus
extends RefCounted

## Chooses which thing the use key would act on. Pure: the caller measures (distance, angle, line of sight) and this decides, so a client prompt and a server check agree.
##
## A candidate is a Dictionary: `id`, `distance` (metres from the eye), `angle` (degrees off the view direction), and optionally `priority` (int, higher wins, default 0), `visible` (line of sight, default true), `enabled` (default true) and `range` (its own use range, default the config's).


## Whether one candidate may be focused at all.
static func eligible(cfg: DotInteractConfig, c: Dictionary) -> bool:
	if not cfg.enabled or not bool(c.get("enabled", true)):
		return false
	if cfg.require_line_of_sight and not bool(c.get("visible", true)):
		return false
	var reach := float(c.get("range", 0.0))
	if reach <= 0.0:
		reach = cfg.range_m
	if float(c.get("distance", INF)) > reach:
		return false
	return cfg.focus_angle <= 0.0 or float(c.get("angle", 0.0)) <= cfg.focus_angle


## The index in [param candidates] of the one to focus, or -1. Higher priority wins, then the smaller angle, then the nearer one, then the earlier one.
static func pick(cfg: DotInteractConfig, candidates: Array) -> int:
	var order: Array = range(candidates.size())
	if cfg.max_candidates > 0 and order.size() > cfg.max_candidates:
		order.sort_custom(func(a: int, b: int) -> bool: return float(candidates[a].get("distance", INF)) < float(candidates[b].get("distance", INF)))
		order = order.slice(0, cfg.max_candidates)
		order.sort()
	var best := -1
	for i: int in order:
		var c: Dictionary = candidates[i]
		if not eligible(cfg, c):
			continue
		if best < 0 or _better(c, candidates[best]):
			best = i
	return best


static func _better(a: Dictionary, b: Dictionary) -> bool:
	var pa := int(a.get("priority", 0))
	var pb := int(b.get("priority", 0))
	if pa != pb:
		return pa > pb
	var aa := float(a.get("angle", 0.0))
	var ab := float(b.get("angle", 0.0))
	if not is_equal_approx(aa, ab):
		return aa < ab
	return float(a.get("distance", INF)) < float(b.get("distance", INF))
