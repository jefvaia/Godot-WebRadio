extends RefCounted
class_name Mp3Decoder

## Blocking MP3 → PCM (s16le) using ffmpeg via temp files.
## No pipes (works in Godot 4.4.1). Cleans up temps immediately.

var default_channels: int = 2
var default_sample_rate: int = 48000

func _get_ffmpeg_path() -> String:
	var rel := ""
	match OS.get_name():
		"Windows":
			rel = "thirdparty/ffmpeg/windows/ffmpeg.exe"
		"Linux", "FreeBSD", "NetBSD":
			rel = "thirdparty/ffmpeg/linux/ffmpeg.exe"
		"macOS":
			rel = "thirdparty/ffmpeg/macos/ffmpeg.exe"
		_:
			push_error("Unsupported platform for ffmpeg.")
			return ""

	if Engine.is_editor_hint():
		return ProjectSettings.globalize_path("res://" + rel)
	else:
		var exe_dir := OS.get_executable_path().get_base_dir()
		return exe_dir.path_join("ffmpeg.exe")

func decode(mp3_bytes: PackedByteArray, channels: int = default_channels, sample_rate: int = default_sample_rate) -> PackedByteArray:
	var ff := _get_ffmpeg_path()
	if ff == "":
		return PackedByteArray()

	var in_path := "user://__ff_in.mp3"
	var out_path := "user://__ff_out.pcm"

	var f := FileAccess.open(in_path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to write temp MP3.")
		return PackedByteArray()
	f.store_buffer(mp3_bytes)
	f.close()

	var args := [
		"-hide_banner","-loglevel","error",
		"-i", ProjectSettings.globalize_path(in_path),
		"-f","s16le","-acodec","pcm_s16le",
		"-ac", str(channels), "-ar", str(sample_rate),
		ProjectSettings.globalize_path(out_path)
	]
	var code := OS.execute(ff, args, [], true)
	if code != 0:
		_cleanup_tmp(in_path, out_path)
		push_error("ffmpeg failed with exit code %d" % code)
		return PackedByteArray()

	var pcm := FileAccess.get_file_as_bytes(out_path)
	_cleanup_tmp(in_path, out_path)
	return pcm

func _cleanup_tmp(p_in: String, p_out: String) -> void:
	for p in [p_in, p_out]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
