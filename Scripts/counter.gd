extends RichTextLabel

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if event.is_pressed() and !get_parent().card_is_opp:
				self.text = str(int(self.text) + 1)
				Net.send_counter(self.get_parent(), "+")
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.is_pressed() and !get_parent().card_is_opp:
				self.text = str(int(self.text) - 1)
				Net.send_counter(self.get_parent(), "-")
