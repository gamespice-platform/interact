class_name GSInteractPromptView
extends Label

## Draws a [GSInteractPrompt]: hidden unless there is something to say, tinted when locked. No textures; the font size and outline are theme overrides a game can replace.

@export var locked_colour := Color(1.0, 0.6, 0.5)

var _cfg: GSInteractConfig


func _init() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 6)
	visible = false


func setup(cfg: GSInteractConfig) -> void:
	_cfg = cfg


## Shows what [GSInteractFocus] chose; an empty aim hides it. Sets the text only when it changed, so an unchanged prompt costs nothing.
func show_aim(aim: Dictionary) -> void:
	var d := GSInteractPrompt.describe(_cfg, aim)
	var state: int = d.state
	visible = state != GSInteractPrompt.HIDDEN
	if not visible:
		return
	var t: String = d.text
	if t != text:
		text = t
	modulate = locked_colour if state == GSInteractPrompt.LOCKED else Color.WHITE
