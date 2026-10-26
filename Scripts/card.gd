extends Node2D

#Signals
signal hovered_over
signal hovered_off
#Variables
var card_id
var card_zone_origin
var card_zone_position
var card_movable = true
var card_highlightable = true
var card_hidden = false
var card_is_opp = false
var card_range
#References
var card_manager

func _ready() -> void:
	#References
	card_manager = get_parent()
	#Signals
	card_manager.connect_card_signals(self)
	#Disable Card Preview and Skill Stack
	if self.name == "CardPreview" or self.name == "SkillStack":
		disable_card()

#region Active Functions
func hide_card():
	self.get_node("CardBG").visible = false
	self.get_node("CardArt").visible = false
	self.get_node("CardBorder").visible = false
	self.get_node("CardBack").visible = true
	self.get_node("DP").visible = false
	self.get_node("Force").visible = false
	self.get_node("CardName").visible = false
	self.get_node("CardAlias").visible = false
	card_highlightable = false
	card_hidden = true
	
	
func unhide_card():
	self.get_node("CardBG").visible = true
	self.get_node("CardArt").visible = true
	self.get_node("CardBorder").visible = true
	self.get_node("CardBack").visible = false
	self.get_node("DP").visible = true
	self.get_node("Force").visible = true
	self.get_node("CardName").visible = true
	self.get_node("CardAlias").visible = true
	card_highlightable = true
	card_hidden = false

func disable_card():
	card_movable = false
	card_highlightable = false
	
func enable_card():
	card_movable = true
	card_highlightable = true
#endregion

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered_over", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
	
