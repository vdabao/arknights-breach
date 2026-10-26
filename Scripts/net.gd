extends Node2D

#Constants
const CARD_SCENE_PATH := "res://Scenes/card.tscn"
const OPP_DECK_POS = Vector2(197, 80)
#Variables
var screen_size
var card_manager
var objects := {}
var opp_cards := {}
var ally_cards := {}
var next_uid := 0

func _ready() -> void:
	screen_size = get_viewport_rect().size

#region Sender Functions
func send_add(zone: Node, card: Node) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_add.rpc(get_uid(card), card.card_id, zone.name, card.position)

func send_remove(zone: Node, card: Node) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_remove.rpc(get_uid(card), zone.name)
		
func send_retreat(zone: Node, card: Node) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_retreat.rpc(get_uid(card), zone.name)
		
func send_arrows(from_card: Node, to_card: Node) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_arrows.rpc(get_uid(from_card), get_uid(to_card))
		
func send_counter(card: Node, type: String) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_counter.rpc(get_uid(card), type)
		
func send_resource(bar: Node, type: String) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_resource.rpc(bar.name, type)
		
func send_show_deck(show_deck: bool) -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_show_deck.rpc(show_deck)
		
func send_end_turn() -> void:
	if multiplayer.has_multiplayer_peer():
		rpc_end_turn.rpc()
#endregion

#region Receiver Functions
@rpc("any_peer", "call_remote", "reliable")
func rpc_add(uid: String, card_id: String, zone_name: String, card_pos: Vector2) -> void:
	var zone = objects.get(zone_name)
	var card = opp_cards.get(uid)
	var mirror_pos = Vector2(screen_size - card_pos)
	if card == null or not is_instance_valid(card):
		card = CardDatabase.create_card(card_id)
		card.set_meta("net_uid", uid)
		card.card_is_opp = true
		card.card_movable = false
		card.position = OPP_DECK_POS
		get_tree().current_scene.get_node("Player/CardManager").add_child(card)
		opp_cards[uid] = card
		
	zone.add_card(card, mirror_pos)
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_remove(uid: String, zone_name: String) -> void:
	var zone = objects.get(zone_name)
	var card = find_card(uid)
	if zone == null or card == null or not is_instance_valid(card):
		return
	
	zone.remove_card(card)
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_retreat(uid: String, zone_name: String) -> void:
	var zone = objects.get(zone_name)
	var card = find_card(uid)
	if zone == null or card == null or not is_instance_valid(card):
		return
	
	zone.remove_card(card)
	card_manager.remove_child(card)
	opp_cards.erase(uid)
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_arrows(from_uid: String, to_uid: String) -> void:	
	var from_card = find_card(from_uid)
	var to_card = find_card(to_uid)
	if from_card == null or to_card == null:
		return
		
	card_manager.draw_targets(from_card)
	card_manager.draw_targets(to_card)
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_counter(uid: String, type: String) -> void:
	var card = find_card(uid)
	if card == null or not is_instance_valid(card):
		return
	if type == "+":
		card.get_node("Counter").text = str(int(card.get_node("Counter").text) + 1)
	else:
		card.get_node("Counter").text = str(int(card.get_node("Counter").text) - 1)
		
@rpc("any_peer", "call_remote", "reliable")
func rpc_resource(bar_name: String, type: String) -> void:
	var bar = objects.get(bar_name)
	if bar == null or not is_instance_valid(bar):
		return
	if type == "+":
		bar.get_node("ResourceBar").value += 1
		bar.get_node("Counter").text = str(int(bar.get_node("ResourceBar").value))
	else:
		bar.get_node("ResourceBar").value -= 1
		bar.get_node("Counter").text = str(int(bar.get_node("ResourceBar").value))
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_show_deck(show_deck: bool) -> void:
	var zone = objects.get("Deck")
	if !show_deck:
		zone.get_node("Area2D/CollisionShape2D").disabled = true
		zone.get_node("DeckImage").visible = false
	else:
		zone.get_node("Area2D/CollisionShape2D").disabled = false
		zone.get_node("DeckImage").visible = true
		
@rpc("any_peer", "call_remote", "reliable")
func rpc_end_turn() -> void:
	var button = objects.get("OppEoT")
	button.disabled = false
	for card in ally_cards.values():
		if card.card_zone_origin.name != "Hand" and card.card_zone_origin.name != "Reveal" and card.rotation_degrees == 90:
			card.card_zone_origin.add_card(card)
			card.get_node("Counter").text = str(CardDatabase.CARDS[card.card_id][1])
	AudioManager.play("highlight")
#endregion

#region Helper Functions
func get_uid(card: Node) -> String:
	if not card.has_meta("net_uid"):
		next_uid += 1
		card.set_meta("net_uid", "%d_%d" % [multiplayer.get_unique_id(), next_uid])
	ally_cards[card.get_meta("net_uid")] = card
	return card.get_meta("net_uid")

func find_card(uid: String) -> Node:
	for dict in [opp_cards, ally_cards]:
		var card = dict.get(uid)
		if card != null and is_instance_valid(card):
			return card
	return null
#endregion
