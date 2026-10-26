extends Node2D

#Constants
const CARD_RATIO = 1050.0 / 750.0
const BASE_CARD_WIDTH = 100.0
const STATIONED_CARD_WIDTH = (BASE_CARD_WIDTH * CARD_RATIO)
const COUNTER_SCENE_PATH = "res://Scenes/counter.tscn"
#Variables
var existing_cards = []
var max_span

func _ready() -> void:
	#Register to Net
	if "Opp" in name:
		Net.objects[name.replace("Opp", "")] = self
	else:
		Net.objects["Opp"+name] = self
		
#region Active Functions
func add_card(card, card_pos = card.position):
	#New Card?
	if card not in existing_cards:
		#Immediately Station
		if "Hand" in self.name or "Reveal" in self.name:
			card.get_node("Counter").visible = false
			card.get_node("Counter").text = str(CardDatabase.CARDS[card.card_id][1])
			card.rotation_degrees = 0
		else:
			card.get_node("Counter").visible = true
			card.rotation_degrees = 90
			AudioManager.play("move")
		#Insert
		var index = get_insert_index(card, card_pos)
		existing_cards.insert(index, card)
		#Update
		card.card_zone_origin = self
		update_card_positions()
	#Existing Card?
	else:
		#Identify Indexes
		var old_index = existing_cards.find(card)
		existing_cards.erase(card)
		var new_index = get_insert_index(card, card_pos)
		existing_cards.insert(new_index, card)
		
		#Insert to New Index? Rearrange
		if new_index != old_index:
			update_card_positions()
		#Insert to Old Index? Station
		else:
			station(card)
			animate_card_to_position(card, card.card_zone_position)
	
	#Auto Hide/Unhide Card
	if "OppHand" in self.name:
		card.hide_card()
	else:
		card.unhide_card()
		
func remove_card(card):
	#Remove
	if card in existing_cards:
		existing_cards.erase(card)
		update_card_positions()
		
func station(card):
	#Not Hand? Station Available
	if "Hand" not in self.name and "Reveal" not in self.name:
		AudioManager.play("station")
		if card.rotation_degrees == 0:
			card.rotation_degrees = 90
		else:
			card.rotation_degrees = 0
	update_card_positions()
#endregion

#region Helper Functions
func get_card_width(card):
	#Check Orientation
	if is_equal_approx(card.rotation_degrees, 90.0):
		return STATIONED_CARD_WIDTH
	return BASE_CARD_WIDTH
			
func get_insert_index(card, card_pos = card.position):
	#No Position? Append to End
	if card_pos.x == null:
		return existing_cards.size()
		
	#Find Insert Index
	var index = 0
	for other in existing_cards:
		if card_pos.x > other.position.x:
			index += 1
	return index

func update_card_positions():
	#Update Positions for All Cards in Zone
	for i in range(existing_cards.size()):
		var new_position = Vector2(calculate_card_position(i), self.position.y)
		var card = existing_cards[i]
		card.card_zone_position = new_position
		card.z_index = i+1
		animate_card_to_position(card, new_position)

func calculate_card_position(index):
	var existing_card_count = existing_cards.size()
	
	var offset_to_index = 0.0
	var total_span = 0.0
	for i in range(1, existing_card_count):
		var gap = (get_card_width(existing_cards[i - 1]) + get_card_width(existing_cards[i])) / 2.0
		total_span += gap
		if i <= index:
			offset_to_index += gap
			
	if "Reveal" in self.name:
		max_span = 300.0
	else:
		max_span = 400.0
		
	var dynamic_max_span = max_span * (existing_card_count - 1) / existing_card_count
	var squeeze = 1.0
	if total_span > dynamic_max_span:
		squeeze = dynamic_max_span / total_span
	
	return self.position.x + (offset_to_index - total_span / 2.0) * squeeze
	
func animate_card_to_position(card, new_position):
	#Animate via Tween
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)
#endregion
	
