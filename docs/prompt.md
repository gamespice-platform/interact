# The use prompt

`GSInteractFocus.pick` chooses the target, `GSInteractPrompt.describe` turns the aim into `{state, text}`, and `GSInteractPromptView` draws it. A locked target shows its bare label (plus `prompt_locked_suffix`); out of range or no label hides it.

This is the generic half of the map addon's use prompt, which still carries its own copy.
