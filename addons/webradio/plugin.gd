@tool
extends EditorPlugin

func _enter_tree() -> void:
	if not ClassDB.class_exists("CSharpScript"):
		var dialog = AcceptDialog.new()
		dialog.title = "Missing .NET support"
		dialog.dialog_text = "WebRadio relies on Godot's .NET (C#) support. Please enable the .NET version of Godot to use this plugin."
		get_editor_interface().get_base_control().add_child(dialog)
		dialog.popup_centered()
		return
	
	add_custom_type("WebRadioStreamPlayer", "AudioStreamPlayer", load("res://addons/webradio/node_types/WebRadioStreamPlayer.cs"), load("res://addons/webradio/icons/WebRadioStreamPlayer.svg"))
	add_custom_type("WebRadioStreamPlayer2D", "AudioStreamPlayer2D", load("res://addons/webradio/node_types/WebRadioStreamPlayer2D.cs"), load("res://addons/webradio/icons/WebRadioStreamPlayer2D.svg"))
	add_custom_type("WebRadioStreamPlayer3D", "AudioStreamPlayer3D", load("res://addons/webradio/node_types/WebRadioStreamPlayer3D.cs"), load("res://addons/webradio/icons/WebRadioStreamPlayer3D.svg"))

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
