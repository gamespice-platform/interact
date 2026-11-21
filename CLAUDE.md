# GameSpice Interact

Press-to-use interaction decisions: focus, hold, server validation. Read the family [CLAUDE.md](../../CLAUDE.md) first. **The distributable is `addons/gs_interact/`**; it requires [GameSpice Core](../gs-core) only (`ln -s ../../gs-core/addons/gs_core addons/gs_core`, gitignored).

| Path | What |
| --- | --- |
| `core/gs_interact_config.gd` | `GSInteractConfig`: every tunable, `from_files()` |
| `core/gs_interact_focus.gd` | `GSInteractFocus`: which candidate the use key acts on (range, cone, line of sight, priority) |
| `core/gs_interact_hold.gd` | `GSInteractHold`: hold-to-use state machine, no clock of its own |
| `core/gs_interact_prompt.gd`, `runtime/gs_interact_prompt_view.gd` | `GSInteractPrompt` (pure text and state of the look-at prompt, moved here from the map addon's use prompt) and `GSInteractPromptView` (a Label) |
| `core/gs_interact_request.gd` | `GSInteractRequest`: the server's verdict on a use request, as a `GSResult` with a reason code |
| `examples/interact_selftest.tscn` | the headless suite |

- **Boundaries.** The `use` action and rebinding belong to GameSpice Input; view rays and the camera to the game or GameSpice Camera; prompt drawing to GameSpice UI/HUD; seats to GameSpice Vehicle. This addon takes measured numbers in and returns decisions.
- **Server authority.** Never accept the client's distance or sight. The server measures and calls `GSInteractRequest.validate`.
- **Pure and clockless.** No autoloads, no scene paths, no `Time` calls; callers pass `now` and `delta`.
- **No hard caps.** `max_candidates` 0 is every candidate, `hold_seconds` and `cooldown_seconds` 0 are none; a bad config fails `validate()` loudly.
- **Next slices** (in `runtime/`): a `GSInteractable` node for targets and a prompt-model node a HUD binds to.
- **Validate**: `--import`, parse every `.gd`, run the suite.
