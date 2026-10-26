extends Node2D

#Signals
signal left_mb_clicked
signal left_mb_released
signal right_mb_clicked
signal right_mb_released
signal middle_mb_clicked
signal middle_mb_released
signal escape_key_clicked
signal escape_key_released
#References
var card_manager

func _ready() -> void:
	card_manager = $"../CardManager"
	card_manager.connect_input_signals(self)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				emit_signal("left_mb_clicked")
			else:
				emit_signal("left_mb_released")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				emit_signal("right_mb_clicked")
			else:
				emit_signal("right_mb_released")
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				emit_signal("middle_mb_clicked")
			else:
				emit_signal("middle_mb_released")
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			if event.is_pressed():
				emit_signal("escape_key_clicked")
			else:
				emit_signal("escape_key_released")
