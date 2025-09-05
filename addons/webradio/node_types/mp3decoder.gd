extends RefCounted
class_name Mp3Decoder

## Decode MP3 buffers into raw PCM bytes using a long‑lived ffmpeg
## process. Chunks are fed through stdin and decoded data is pulled
## from stdout asynchronously.
##
## Output format: s16le PCM, interleaved (signed 16-bit little endian).

signal pcm_ready(pcm: PackedByteArray)

var default_channels: int = 2
var default_sample_rate: int = 48000

var _pipe: FileAccess
var _pid: int = -1
var _thread: Thread
var _queue: Array[PackedByteArray] = []
var _mutex := Mutex.new()
var _running := false

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
                # Running in editor → use the res:// copy for this platform
                return ProjectSettings.globalize_path("res://" + ffmpeg_rel)
        else:
                # Exported build → expect ffmpeg.exe next to your game exe
                var exe_dir := OS.get_executable_path().get_base_dir()
                return exe_dir.path_join("ffmpeg.exe")

func _init() -> void:
        _start_ffmpeg()

func _start_ffmpeg(channels: int = default_channels, sample_rate: int = default_sample_rate) -> void:
        var ff := _get_ffmpeg_path()
        if ff == "":
                return

        var args := [
                "-hide_banner", "-loglevel", "error",
                "-i", "pipe:0",
                "-f", "s16le", "-acodec", "pcm_s16le",
                "-ac", str(channels), "-ar", str(sample_rate),
                "pipe:1",
        ]

        var result := OS.execute_with_pipe(ff, args, false)
        if result.is_empty():
                push_error("Failed to start ffmpeg.")
                return

        _pipe = result["stdio"]
        _pid = result["pid"]

        _running = true
        _thread = Thread.new()
        _thread.start(_decode_loop)

func decode(mp3_bytes: PackedByteArray) -> void:
        if !_running:
                return
        _mutex.lock()
        _queue.push_back(mp3_bytes.duplicate())
        _mutex.unlock()

func _decode_loop() -> void:
        while _running and OS.is_process_running(_pid):
                _mutex.lock()
                if _queue.size() > 0:
                        var chunk: PackedByteArray = _queue.pop_front()
                        _pipe.store_buffer(chunk)
                        _pipe.flush()
                _mutex.unlock()

                var pcm := _pipe.get_buffer(4096)
                if pcm.size() > 0:
                        emit_signal("pcm_ready", pcm)

                OS.delay_msec(10)

func stop() -> void:
        _running = false
        if _thread and _thread.is_started():
                _thread.wait_to_finish()
        if _pipe:
                _pipe.close()
        if _pid != -1 and OS.is_process_running(_pid):
                OS.kill(_pid)

func _finalize() -> void:
        stop()
