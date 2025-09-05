extends RefCounted
class_name Mp3Decoder

## Decode an MP3 buffer into raw PCM bytes using ffmpeg.
## Writes to temp files under user://, then cleans up.
##
## Output format: s16le PCM, interleaved (signed 16-bit little endian).

var default_channels: int = 2
var default_sample_rate: int = 48000

func _get_ffmpeg_path() -> String:
	var ffmpeg_rel := ""
	match OS.get_name():
		"Windows":
			ffmpeg_rel = "thirdparty/ffmpeg/windows/ffmpeg.exe"
		"Linux", "FreeBSD", "NetBSD":
			ffmpeg_rel = "thirdparty/ffmpeg/linux/ffmpeg.exe"
		"macOS":
			ffmpeg_rel = "thirdparty/ffmpeg/macos/ffmpeg.exe"
		_:
			push_error("Unsupported platform for ffmpeg.")
			return ""

	if Engine.is_editor_hint():
		# In editor → use res:// path so you can test
		return ProjectSettings.globalize_path("res://" + ffmpeg_rel)
	else:
		# In exported build → expect ffmpeg.exe next to your game exe
		var exe_dir := OS.get_executable_path().get_base_dir()
		return exe_dir.path_join("ffmpeg.exe")


func decode(mp3_bytes: PackedByteArray, channels: int = default_channels, sample_rate: int = default_sample_rate) -> PackedByteArray:
	var ff := _get_ffmpeg_path()
	if ff == "":
		return PackedByteArray()

	# Temporary paths
	var mp3_path := "user://tmp_input.mp3"
	var pcm_path := "user://tmp_output.pcm"

	# Save MP3 input
	var f := FileAccess.open(mp3_path, FileAccess.WRITE)
	if f == null:
		push_error("Could not write temp MP3 file")
		return PackedByteArray()
	f.store_buffer(mp3_bytes)
	f.close()

	# Run ffmpeg to decode → raw PCM
	var args := [
		"-hide_banner", "-loglevel", "error",
		"-i", ProjectSettings.globalize_path(mp3_path),
		"-f", "s16le", "-acodec", "pcm_s16le",
		"-ac", str(channels), "-ar", str(sample_rate),
		ProjectSettings.globalize_path(pcm_path)
	]

	var exit_code := OS.execute(ff, args, [], true)  # blocking
	if exit_code != 0:
		push_error("ffmpeg failed with exit code %d" % exit_code)
		return PackedByteArray()

	# Read back PCM
	var pcm := FileAccess.get_file_as_bytes(pcm_path)

	# Clean up
	if FileAccess.file_exists(mp3_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(mp3_path))
	if FileAccess.file_exists(pcm_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(pcm_path))

	return pcm
