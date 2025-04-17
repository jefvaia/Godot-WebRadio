@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("WebRadioStreamPlayer", "AudioStreamPlayer", preload("res://addons/webradio/node_types/webradiostreamplayer.gd"), preload("res://icon.svg"))
	add_custom_type("WebRadioStreamPlayer2D", "AudioStreamPlayer2D", preload("res://addons/webradio/node_types/webradiostreamplayer2d.gd"), preload("res://icon.svg"))
	add_custom_type("WebRadioStreamPlayer3D", "AudioStreamPlayer3D", preload("res://addons/webradio/node_types/webradiostreamplayer3d.gd"), preload("res://icon.svg"))
	add_autoload_singleton("WebRadioStreamHelper", "res://addons/webradio/node_types/radiostreamhelper.gd")

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
