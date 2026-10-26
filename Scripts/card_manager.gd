extends Node2D

#Constants
const ARROW_COLOR = Color(1, 1, 1, 0.9)  
const ARROW_WIDTH = 2
const ARROW_HEAD_SIZE = 10.0
const ARROW_HEAD_ANGLE = 30.0
const ARROW_END_OFFSET = 0.0
const ARROW_CURVE = 0.25     # how much the line bends (0 = straight)
const ARROW_SEGMENTS = 24    # curve smoothness
const ARROW_SHADOW_COLOR = Color(0, 0, 0, 0.35)
const ARROW_SHADOW_OFFSET = Vector2(2, 3)
const DEFAULT_CARD_SCALE = Vector2(0.125, 0.125)
const HIGHLIGHTED_CARD_SCALE = Vector2(0.135, 0.135)
const DISTANCES = {
	"OppBase": [["OppBase"], ["OppStage1", "OppStage3"], ["OppStage2", "OppStage4", "Stage4"], ["Stage3", "Stage2", "Stage1"], ["Base"]],
	"OppStage1": [["OppStage1"], ["OppBase", "OppStage2", "OppStage3", "OppStage4"], ["Stage4", "Stage3"], ["Stage2", "Stage1", "Base"], []],
	"OppStage2": [["OppStage2"], ["OppStage1", "OppStage4"], ["OppBase", "OppStage3", "Stage3"], ["Stage4", "Stage1", "Base"], ["Stage2"]],
	"OppStage3": [["OppStage3"], ["OppBase", "OppStage1", "OppStage4", "Stage4"], ["OppStage2", "Stage3", "Stage2", "Stage1"], ["Base"], []],
	"OppStage4": [["OppStage4"], ["OppStage1", "OppStage2", "OppStage3", "Stage3"], ["OppBase", "Stage4", "Stage1", "Base"], ["Stage2"], []],
	"Stage4": [["Stage4"], ["OppStage3", "Stage3", "Stage2", "Stage1"], ["OppBase", "OppStage1", "OppStage4", "Base"], ["OppStage2"], []],
	"Stage3": [["Stage3"], ["OppStage4", "Stage4", "Stage1", "Base"], ["OppStage1", "OppStage2", "OppStage3", "Stage2"], ["OppBase"], []],
	"Stage2": [["Stage2"], ["Stage4", "Stage1"], ["OppStage3", "Stage3", "Base"], ["OppBase", "OppStage1", "OppStage4"], ["OppStage2"]],
	"Stage1": [["Stage1"], ["Stage4", "Stage3", "Stage2", "Base"], ["OppStage3", "OppStage4"], ["OppBase", "OppStage1", "OppStage2"], []],
	"Base": [["Base"], ["Stage3", "Stage1"], ["OppStage4", "Stage4", "Stage2"], ["OppStage1", "OppStage2", "OppStage3"], ["OppBase"]],
}
#Variables
var card_being_dragged
var card_being_hovered
var relative_pos
var target_source = null
var arrows = []
var arrow_layer
#References
var deck
var card_preview

func _ready() -> void:
	##References
	if "Opp" not in self.name:
		deck = $"../Deck"
		card_preview = $CardPreview
	Net.card_manager = self
	##Create Arrow
	arrow_layer = Node2D.new()
	arrow_layer.z_index = 1000
	add_child(arrow_layer)
	arrow_layer.draw.connect(_create_arrows)

func _process(_delta: float) -> void:
	##Card Dragging
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x + relative_pos.x, 0, Net.screen_size.x), clamp(mouse_pos.y + relative_pos.y, 0, Net.screen_size.y))
	##Arrow Targetting
	if target_source and target_source.get_parent() != self:
		target_source = null
	arrows = arrows.filter(func(a): return a["from"].get_parent() == self and a["to"].get_parent() == self)
	arrow_layer.queue_redraw()

#region Inputs
func connect_card_signals(card):
	card.connect("hovered_over", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func connect_input_signals(input_manager):
	input_manager.connect("left_mb_clicked", on_left_mb_clicked)
	input_manager.connect("left_mb_released", on_left_mb_released)
	input_manager.connect("right_mb_clicked", on_right_mb_clicked)
	input_manager.connect("middle_mb_clicked", on_middle_mb_clicked)
	input_manager.connect("escape_key_clicked", on_escape_key_clicked)

func on_left_mb_clicked():
	var card = raycast_check_for_card()
	if card:
		start_drag(card)

func on_left_mb_released():
	if card_being_dragged:
		finish_drag()
		
func on_right_mb_clicked():
	var card = raycast_check_for_card()
	if card:
		retreat(card)
	else:
		if target_source:
			target_source = null
		if arrows:
			arrows.clear()
		
func on_middle_mb_clicked():
	var card = raycast_check_for_card()
	if card:
		if target_source:
			Net.send_arrows(target_source, card)
		draw_targets(card)
	else:
		target_source = null

func on_escape_key_clicked():
	if target_source:
		target_source = null
	if arrows:
		arrows.clear()
#endregion

#region Active Functions
func start_drag(card):
	#Guards
	if !card.card_movable:
		return
		
	#Variables
	card_being_dragged = card
	
	#Visuals
	relative_pos = card.position - get_global_mouse_position()
	card.z_index = 100
	card.scale = DEFAULT_CARD_SCALE
	indicate_range(card, false)

func finish_drag():
	#Variables
	var card = card_being_dragged
	var origin = card.card_zone_origin
	var card_zone_found = raycast_check_for_card_zone()
	var changed_zones = card_zone_found != null and card_zone_found != origin
	card_being_dragged = null
	
	#Nodes
	if card_zone_found:
		if changed_zones:
			origin.remove_card(card)
			Net.send_remove(origin, card)
		card_zone_found.add_card(card)
		print(get_global_mouse_position())
		Net.send_add(card_zone_found, card)
	else:
		origin.update_card_positions()
	
	#Visuals
	highlight_card(card, true)

func retreat(card):
	if card.card_id and !card.card_is_opp and !card_being_dragged:
		#Sounds
		AudioManager.play("retreat")
		#Retreat
		deck.deck_list.append(card.card_id)
		Net.send_show_deck(true)
		deck.get_node("Area2D/CollisionShape2D").disabled = false
		deck.get_node("DeckImage").visible = true
		#Remove Card from Card Zone
		card.card_zone_origin.remove_card(card)
		indicate_range(card, false)
		#Remove Card from Card Manager
		self.remove_child(card)
		Net.send_retreat(card.card_zone_origin, card)
#endregion

#region Helper Functions
func on_hovered_over_card(_card):
	#Guards
	var top_card = raycast_check_for_card()
	if !top_card or top_card == card_being_hovered or card_being_dragged:
		return
		
	#Variables
	var previous_card = card_being_hovered
	card_being_hovered = top_card
	
	#Visuals
	if previous_card != null:
		highlight_card(previous_card, false)
	highlight_card(card_being_hovered, true)

func on_hovered_off_card(card):
	#Guards
	if card_being_dragged:
		return
		
	#Variables
	var top_card = raycast_check_for_card()
	var next_card = null
	if top_card and top_card != card:
		next_card = top_card
		
	if card_being_hovered == card:
		card_being_hovered = null
	if next_card:
		card_being_hovered = next_card
		
	#Visuals
	highlight_card(card, false)
	if next_card:
		highlight_card(next_card, true)

func highlight_card(card, hovered):
	if card.card_highlightable:
		#Increase Scale, Indicate Range, and Update Preview
		if hovered:
			card.scale = HIGHLIGHTED_CARD_SCALE
			indicate_range(card, true)
			update_card_preview(card_preview)
		#Return to Original Scale
		else:
			indicate_range(card, false)
			card.scale = DEFAULT_CARD_SCALE

func indicate_range(card, indicate):
	if card.card_zone_origin.name in DISTANCES.keys():
		var card_range = card.card_range
		for i in DISTANCES[card.card_zone_origin.name][card_range]:
			var zone = self.get_parent().get_node(i)
			if indicate:
					zone.modulate = Color(1, 0, 0, 0.25)
			else:
					zone.modulate = Color(1, 1, 1, 1)

func update_card_preview(card):
	var new_card = raycast_check_for_card()
	if new_card and new_card != card:
		card_preview.get_node("CardArt").texture = load("res://Assets/Images/" + new_card.card_id + ".png")
		var data = CardDatabase.CARDS[new_card.card_id]
		card_preview.get_node("DP").text = str(data[0])
		card_preview.get_node("Force").text = str(data[1])
		card_preview.get_node("Counter").text = str(data[1])
		var parts = new_card.card_id.split(", ")
		card_preview.get_node("CardName").text = parts[0]
		if parts.size() > 1:
			card_preview.get_node("CardAlias").text = parts[1]
		else:
			card_preview.get_node("CardAlias").text = ""

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	#Check Mask 1
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func raycast_check_for_card_zone():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	#Check Mask 2
	parameters.collision_mask = 2
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func get_card_with_highest_z_index(cards):
	#Find Highest Z Index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
#endregion

#region Draw Arrow Code (For Review)
func draw_targets(card):
	#Pick Source Card
	if target_source == null:
		target_source = card
		return
	#Target Self: Cancel Target
	if card == target_source:
		target_source = null
		return
	#Target Different Card: Draw Arrows
	for a in arrows:
		#Erase Arrows if Arrows Exist
		if a["from"] == target_source and a["to"] == card:
			arrows.erase(a)
			target_source = null
			return
	arrows.append({"from": target_source, "to": card})
	target_source = null

func _create_arrows():
	for a in arrows:
		_draw_arrow(a["from"].position, a["to"].position, ARROW_END_OFFSET)
	if target_source:
		_draw_arrow(target_source.position, get_local_mouse_position(), 0.0)

func _draw_arrow(from_pos: Vector2, to_pos: Vector2, end_offset: float):
	var dist = from_pos.distance_to(to_pos)
	if dist <= end_offset + ARROW_HEAD_SIZE:
		return
	
	# Quadratic bezier: the control point sits off to the side of the midpoint
	var mid = (from_pos + to_pos) / 2.0
	var control = mid + (to_pos - from_pos).orthogonal().normalized() * dist * ARROW_CURVE
	
	# Sample the curve, stopping short of the target card
	var points = PackedVector2Array()
	for i in range(ARROW_SEGMENTS + 1):
		var t = float(i) / ARROW_SEGMENTS
		var p = from_pos.lerp(control, t).lerp(control.lerp(to_pos, t), t)
		if p.distance_to(to_pos) < end_offset:
			break
		points.append(p)
	if points.size() < 2:
		return
	
	# Arrowhead follows the curve's direction at the tip
	var tip = points[points.size() - 1]
	var dir = (tip - points[points.size() - 2]).normalized()
	var angle = deg_to_rad(ARROW_HEAD_ANGLE)
	var head_a = tip - dir.rotated(angle) * ARROW_HEAD_SIZE
	var head_b = tip - dir.rotated(-angle) * ARROW_HEAD_SIZE
	
	var head = PackedVector2Array([head_a, tip, head_b])
	
	# Shadow first, shifted by the offset
	var shadow_points = PackedVector2Array()
	for p in points:
		shadow_points.append(p + ARROW_SHADOW_OFFSET)
	var shadow_head = PackedVector2Array()
	for p in head:
		shadow_head.append(p + ARROW_SHADOW_OFFSET)
	arrow_layer.draw_polyline(shadow_points, ARROW_SHADOW_COLOR, ARROW_WIDTH + 1.0, true)
	arrow_layer.draw_polyline(shadow_head, ARROW_SHADOW_COLOR, ARROW_WIDTH + 1.0, true)
	
	# Arrow on top
	arrow_layer.draw_polyline(points, ARROW_COLOR, ARROW_WIDTH, true)
	arrow_layer.draw_polyline(head, ARROW_COLOR, ARROW_WIDTH, true)
#endregion
