extends Node2D

#Constants
const PORT = 7777
const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
#Variables
var peer = ENetMultiplayerPeer.new()
var server_address

@export var player_field_scene : PackedScene
@export var opp_field_scene : PackedScene

func _on_host_pressed() -> void:
	$Join.disabled = true
	$Host.disabled = true
	
	$RoomCode.visible = true
	$RoomCode.text += encode_address()
	$ServerAddress.visible = false
	
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	
func _on_join_pressed() -> void:
	server_address = decode_code($ServerAddress.text)
	#server_address = $ServerAddress.text
	if !server_address:
		$ServerAddress.visible = true
	else:
		disable_buttons()
		$ServerAddress.visible = false
		$MenuBG.visible = false
		
		peer.create_client(server_address, PORT)
		multiplayer.multiplayer_peer = peer
		
		var player_field = player_field_scene.instantiate()
		add_child(player_field)
		var opp_field = opp_field_scene.instantiate()
		add_child(opp_field)

func _on_peer_connected(_peer_id):
	disable_buttons()
	$RoomCode.visible = false
	$ServerAddress.visible = false
	$MenuBG.visible = false
	
	var player_field = player_field_scene.instantiate()
	add_child(player_field)
	var opp_field = opp_field_scene.instantiate()
	add_child(opp_field)
	
func disable_buttons():
	#UI/X
	$Host.disabled = true
	$Host.visible = false
	$Join.disabled = true
	$Join.visible = false
	
func encode_address() -> String:
	#State
	var code = ""

	for addr in IP.get_local_addresses():
		var p = addr.split(".")
		if p.size() != 4:
			continue

		var value = 0
		var length = 0
		if addr.begins_with("192.168."):
			value = (int(p[2]) << 8) | int(p[3])
			length = 4
		elif addr.begins_with("26.") or addr.begins_with("10."):
			value = (int(p[1]) << 16) | (int(p[2]) << 8) | int(p[3])
			if addr.begins_with("26."):
				value |= 1 << 24
			length = 5
		else:
			continue

		for c in length:
			code += ALPHABET[(value >> (5 * (length - 1 - c))) & 31]
		break

	return code
	
func decode_code(code: String) -> String:
	#Guards
	code = code.to_upper().strip_edges()
	if code.length() != 4 and code.length() != 5:
		return ""

	#State
	var value = 0
	for ch in code:
		var idx = ALPHABET.find(ch)
		#Order: validity check must happen per character while building value
		if idx == -1:
			return ""
		value = (value << 5) | idx

	if code.length() == 4:
		return "192.168.%d.%d" % [(value >> 8) & 255, value & 255]

	var prefix = "26" if (value >> 24) & 1 else "10"
	return "%s.%d.%d.%d" % [prefix, (value >> 16) & 255, (value >> 8) & 255, value & 255]
