# GameSpice Interact

Press-to-use interaction decisions: focus, hold, server validation. Read the family [CLAUDE.md](../../CLAUDE.md) first. **The distributable is `addons/dot_interact/`**; it requires [GameSpice Core](../dot-core) only (`ln -s ../../dot-core/addons/dot_core addons/dot_core`, gitignored).

| Path | What |
| --- | --- |
| `core/dot_interact_config.gd` | `DotInteractConfig`: every tunable, `from_files()` |
| `core/dot_interact_focus.gd` | `DotInteractFocus`: which candidate the use key acts on (range, cone, line of sight, priority) |
| `core/dot_interact_hold.gd` | `DotInteractHold`: hold-to-use state machine, no clock of its own |
| `core/dot_interact_request.gd` | `DotInteractRequest`: the server's verdict on a use request, as a `DotResult` with a reason code |
| `examples/interact_selftest.tscn` | the headless suite |

- **Boundaries.** The `use` action and rebinding belong to GameSpice Input; view rays and the camera to the game or GameSpice Camera; prompt drawing to GameSpice UI/HUD; seats to GameSpice Vehicle. This addon takes measured numbers in and returns decisions.
- **Server authority.** Never accept the client's distance or sight. The server measures and calls `DotInteractRequest.validate`.
- **Pure and clockless.** No autoloads, no scene paths, no `Time` calls; callers pass `now` and `delta`.
- **No hard caps.** `max_candidates` 0 is every candidate, `hold_seconds` and `cooldown_seconds` 0 are none; a bad config fails `validate()` loudly.
- **Next slices** (in `runtime/`): a `DotInteractable` node for targets and a prompt-model node a HUD binds to.
- **Validate**: `--import`, parse every `.gd`, run the suite.
