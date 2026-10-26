extends Node2D

#Constants
const SFX_DIR = "res://Assets/SFX/"

#Variables
var sounds := {}
var _player: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic

func _ready() -> void:
	#References
	_load_sounds(SFX_DIR)
	_player = AudioStreamPlayer.new()
	var poly = AudioStreamPolyphonic.new()
	poly.polyphony = 16
	_player.stream = poly
	_player.bus = "SFX"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

func _load_sounds(path: String):
	for file in ResourceLoader.list_directory(path):
		#Search Subfolders
		if file.ends_with("/"):
			_load_sounds(path + file)
		#Load Sounds to Array
		else:
			sounds[file.get_basename()] = load(path + file)
			
func play(sound, volume_db = -20):
	#Play Sound if it Exists
	if sound not in sounds:
		return
	else:
		_playback.play_stream(sounds[sound], 0.0, volume_db, randf_range(0.95, 1.05))
