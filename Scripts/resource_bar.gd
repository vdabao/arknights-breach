extends Node2D

#References
var resource_bar
var counter

func _ready() -> void:
	#References
	resource_bar = $ResourceBar
	counter = $Counter
	#Register to Net
	if "Opp" in name:
		Net.objects[name.replace("Opp", "")] = self
	else:
		Net.objects["Opp"+name] = self

func _on_resource_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and "Opp" not in self.name:
				resource_bar.value += 1
				counter.text = str(int(resource_bar.value))
				Net.send_resource(self, "+")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed() and "Opp" not in self.name:
				resource_bar.value -= 1
				counter.text = str(int(resource_bar.value))
				Net.send_resource(self, "-")
