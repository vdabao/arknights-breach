extends Node2D

#Constants
const CARD_SCENE_PATH = "res://Scenes/card.tscn"
const CARDS = {
	"Myrtle": [2, 1, 1],
	"Closure": [1, 1, 1],
	"Ines": [2, 2, 1],
	"Qiubai": [5, 6, 1],
	"Młynar": [3, 8, 1],
	"Surtr": [8, 9, 1],
	"Shu": [4, 5, 0],
	"Saria": [4, 3, 0],
	"Mudrock": [7, 6, 1],
	"Ray": [4, 2, 2],
	"Typhon": [4, 4, 2],
	"Lemuen": [6, 5, 3],
	"Blaze, Igniting Spark": [4, 3, 1],
	"Necrass": [3, 2, 1],
	"Leizi": [2, 2, 1],
	"Eyja, Hvít Aska": [3, 3, 2],
	"Mon3tr": [5, 3, 1],
	"Reed, Flame Shadow": [4, 3, 1],
	"Suzuran": [2, 1, 1],
	"Virtuosa": [6, 5, 1],
	"Haruka": [3, 3, 1],
	"Texas, Omertosa": [2, 2, 1],
	"Exusiai, New Covenant": [6, 3, 1],
	"Mizuki": [3, 2, 1],
	"DP": [0, 0]
}

func create_card(card_id: String):
	#Create Card
	var card = load(CARD_SCENE_PATH).instantiate()
	#Card Art
	card.get_node("CardArt").texture = load("res://Assets/Images/" + card_id + ".png")
	#Card Text
	var data = CARDS[card_id]
	card.get_node("DP").text = str(data[0])
	card.get_node("Force").text = str(data[1])
	card.get_node("Counter").text = str(data[1])
	var parts := card_id.split(", ")
	card.get_node("CardName").text = parts[0]
	if parts.size() > 1:
		card.get_node("CardAlias").text = parts[1]
	#Card Data
	card.name = card_id
	card.card_id = card_id
	card.card_highlightable = true
	card.card_movable = true
	card.card_range = data[2]
	card.scale = Vector2(0.125, 0.125)
	return card
	
