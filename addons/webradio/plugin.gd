@tool
extends EditorPlugin

const PREF_KEY := "webradio_plugin/shown_setup_hint"

func _enter_tree() -> void:
	# If the editor doesn't have C#/.NET, show the missing-support dialog.
	if not ClassDB.class_exists("CSharpScript"):
		var dlg := AcceptDialog.new()
		dlg.title = "Missing .NET support"
		dlg.dialog_text = "WebRadio relies on Godot's .NET (C#) support.\n" \
			+ "Please run the .NET build of Godot to use this plugin."
		get_editor_interface().get_base_control().add_child(dlg)
		dlg.popup_centered()
		return

	# Show a one-time setup hint when C# is available.
	var es := get_editor_interface().get_editor_settings()
	var shown := false
	if es.has_setting(PREF_KEY):
		shown = bool(es.get_setting(PREF_KEY))
	if not shown:
		var hint := AcceptDialog.new()
		hint.title = "WebRadio setup"
		hint.dialog_text = "To make this work, make sure your project has a C# solution (.sln/.csproj)\n" \
			+ "and run:\n\n    dotnet add package FFMpegCore"
		get_editor_interface().get_base_control().add_child(hint)
		hint.popup_centered()
		es.set_setting(PREF_KEY, true)
		es.save()

	add_custom_type("WebRadioStreamPlayer", "AudioStreamPlayer",
		load("res://addons/webradio/node_types/WebRadioStreamPlayer.cs"),
		load("res://addons/webradio/icons/WebRadioStreamPlayer.svg"))
	add_custom_type("WebRadioStreamPlayer2D", "AudioStreamPlayer2D",
		load("res://addons/webradio/node_types/WebRadioStreamPlayer2D.cs"),
		load("res://addons/webradio/icons/WebRadioStreamPlayer2D.svg"))
	add_custom_type("WebRadioStreamPlayer3D", "AudioStreamPlayer3D",
		load("res://addons/webradio/node_types/WebRadioStreamPlayer3D.cs"),
		load("res://addons/webradio/icons/WebRadioStreamPlayer3D.svg"))

func _exit_tree() -> void:
	# Optional but recommended: remove custom types when the plugin disables.
	remove_custom_type("WebRadioStreamPlayer")
	remove_custom_type("WebRadioStreamPlayer2D")
	remove_custom_type("WebRadioStreamPlayer3D")
