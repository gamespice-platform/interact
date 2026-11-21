class_name GSInteractRequest
extends RefCounted

## The server's judgement of a use request. Nothing the client says about distance or sight is trusted: the server passes what it measured itself, and the verdict is a [GSResult] whose error code says why it was refused.
##
## [param world] is what the server measured: `distance` (metres, actor eye to target), `visible` (its own line-of-sight test), `target_enabled`, optional `range` (the target's own), `now` (seconds, any monotonic clock) and `last_use` (when this actor last used anything, or -INF).


static func validate(cfg: GSInteractConfig, world: Dictionary) -> GSResult:
	if not cfg.enabled:
		return GSResult.fail(GSError.CODE_FORBIDDEN, "interaction is disabled")
	if not bool(world.get("target_enabled", true)):
		return GSResult.fail(GSError.CODE_STATE, "that cannot be used right now")
	var reach := float(world.get("range", 0.0))
	if reach <= 0.0:
		reach = cfg.range_m
	var distance := float(world.get("distance", INF))
	if distance > reach + cfg.server_range_slack:
		return GSResult.fail(GSError.CODE_FORBIDDEN, "out of range (%.2f m, limit %.2f m)" % [distance, reach + cfg.server_range_slack])
	if cfg.require_line_of_sight and not bool(world.get("visible", false)):
		return GSResult.fail(GSError.CODE_FORBIDDEN, "no line of sight to the target")
	var since := float(world.get("now", 0.0)) - float(world.get("last_use", -INF))
	if since < cfg.cooldown_seconds:
		return GSResult.fail(GSError.CODE_RATE_LIMITED, "used again after %.2f s, the cooldown is %.2f s" % [since, cfg.cooldown_seconds])
	return GSResult.success(world)
