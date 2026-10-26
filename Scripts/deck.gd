extends Node2D

#Constants
const STARTING_HAND_SIZE = 5
const DEFAULT_CARD_SCALE = Vector2(0.125, 0.125)
const HIGHLIGHTED_CARD_SCALE = Vector2(0.135, 0.135)
#Variables
var deck_list
#References
var hand
var reveal

func _ready() -> void:
	##Register to Net, Set References
	#Variables
	if "Opp" in name:
		Net.objects[name.replace("Opp", "")] = self
	else:
		Net.objects["Opp"+name] = self
		hand = $"../Hand"
		reveal = $"../Reveal"
	##Create Decks
	#Variables
	if "DPDeck" in self.name:
		deck_list = ["DP", "DP", "DP", "DP", "DP", "DP", "DP", "DP", "DP", "DP"]
	elif "Deck" in self.name:
		deck_list = ["Myrtle", "Closure", "Ines", 
					"Qiubai", "Surtr", "Młynar", 
					"Ray", "Typhon", "Lemuen", 
					"Eyja, Hvít Aska", "Mon3tr", "Reed, Flame Shadow", 
					"Suzuran", "Virtuosa", "Haruka", 
					"Texas, Omertosa", "Exusiai, New Covenant", "Mizuki", 
					"Blaze, Igniting Spark", "Necrass", "Leizi", 
					"Shu", "Saria", "Mudrock"]
	else:
		deck_list = []
	deck_list.shuffle()

#region Inputs
func _on_area_2d_mouse_entered() -> void:
	self.scale = Vector2(1.05, 1.05)

func _on_area_2d_mouse_exited() -> void:
	self.scale = Vector2(1, 1)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and "Opp" not in name:
				draw_card(1)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and "Opp" not in name:
				reveal_card(1)
#endregion

#region Active Functions
func draw_card(amount):
	for i in range(amount):
		if deck_list:
			##Create Card
			#Variables
			var card_drawn_id = deck_list[0]
			deck_list.erase(card_drawn_id)
			var new_card = CardDatabase.create_card(card_drawn_id)
			#Visuals
			if deck_list.size() == 0:
				$Area2D/CollisionShape2D.disabled = true
				$DeckImage.visible = false
				Net.send_show_deck(false)
			new_card.position = self.position
			#Nodes
			$"../CardManager".add_child(new_card)
			
			##Draw Card
			#Nodes
			hand.add_card(new_card)
			Net.send_add(hand, new_card)
			
	#Sounds
	AudioManager.play("draw")
			
func reveal_card(amount):
	for i in range(amount):
		if deck_list:
			##Create Card
			#Variables
			var card_drawn_id = deck_list[0]
			deck_list.erase(card_drawn_id)
			var new_card = CardDatabase.create_card(card_drawn_id)
			
			#Visuals
			if deck_list.size() == 0:
				$Area2D/CollisionShape2D.disabled = true
				$DeckImage.visible = false
				Net.send_show_deck(false)
			new_card.position = self.position
			
			#Nodes
			$"../CardManager".add_child(new_card)
			
			##Reveal Card
			#Nodes
			reveal.add_card(new_card)
			Net.send_add(reveal, new_card)
			
	#Sounds
	AudioManager.play("draw")
			
#endregion
