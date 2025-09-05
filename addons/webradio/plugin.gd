@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("WebRadioStreamPlayer", "AudioStreamPlayer", preload("res://addons/webradio/node_types/WebRadioStreamPlayer.cs"), preload("res://addons/webradio/icons/WebRadioStreamPlayer.svg"))
	add_custom_type("WebRadioStreamPlayer2D", "AudioStreamPlayer2D", preload("res://addons/webradio/node_types/WebRadioStreamPlayer2D.cs"), preload("res://addons/webradio/icons/WebRadioStreamPlayer2D.svg"))
	add_custom_type("WebRadioStreamPlayer3D", "AudioStreamPlayer3D", preload("res://addons/webradio/node_types/WebRadioStreamPlayer3D.cs"), preload("res://addons/webradio/icons/WebRadioStreamPlayer3D.svg"))
	add_autoload_singleton("WebRadioStreamHelper", "res://addons/webradio/node_types/WebRadioStreamHelper.cs")

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
