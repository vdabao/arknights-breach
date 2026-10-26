extends Button

func _ready() -> void:
	#Register to Net
	if "Opp" in name:
		Net.objects[name.replace("Opp", "")] = self
	else:
		Net.objects["Opp"+name] = self

func _on_pressed() -> void:
	#States
	self.disabled = true
	
	#Nodes
	for card in Net.opp_cards.values():
		if card.card_zone_origin.name != "Hand" and card.card_zone_origin.name != "Reveal" and card.rotation_degrees == 90:
			card.card_zone_origin.add_card(card)
			card.get_node("Counter").text = str(CardDatabase.CARDS[card.card_id][1])
	Net.send_end_turn()
	
	#Sounds
	AudioManager.play("highlight")
