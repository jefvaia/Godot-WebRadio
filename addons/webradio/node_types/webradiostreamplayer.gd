extends AudioStreamPlayer
class_name WebRadioStreamPlayer

@export var url: String

var _http_instance: HTTPClientInstance
var _playback: AudioStreamGeneratorPlayback
var _frame_queue: Array
var _queue_mutex: Mutex
var _push_thread: Thread
var _thread_running := false

const REFILL_THRESHOLD := 1024

func _ready() -> void:
	_http_instance = WebRadioStreamHelper.get_radio(url)
	if _http_instance == null:
		_http_instance = WebRadioStreamHelper.add_radio(url)

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 48000
	generator.buffer_length = 5.0
	stream = generator
	play()
	_playback = get_stream_playback()

	# Preload ~0.5s of silence
	var initial_frames := int(generator.mix_rate * 0.5)
	for i in range(initial_frames):
		_playback.push_frame(Vector2.ZERO)

	_frame_queue = []
	_queue_mutex = Mutex.new()

	_http_instance.buffer_ready.connect(_refresh_stream)

func _process(_delta: float) -> void:
	if _playback == null:
		return

	var avail := _playback.get_frames_available()
	if avail <= 0:
		return

	# Drain queued decoded frames first
	_queue_mutex.lock()
	while avail > 0 and _frame_queue.size() > 0:
		_playback.push_frame(_frame_queue.pop_front())
		avail -= 1
	_queue_mutex.unlock()

	# Top up with silence if needed
	while avail > 0:
		_playback.push_frame(Vector2.ZERO)
		avail -= 1


func _refresh_stream(pcm: PackedByteArray) -> void:
	if _playback == null or pcm.is_empty():
		return
	var local_queue: Array[Vector2] = []
	var i := 0
	# s16le stereo → 4 bytes per frame
	while i + 3 < pcm.size():
		var l := pcm.decode_s16(i) / 32768.0
		var r := pcm.decode_s16(i + 2) / 32768.0
		local_queue.append(Vector2(l, r))
		i += 4
	_queue_mutex.lock()
	_frame_queue += local_queue
	_queue_mutex.unlock()


func _push_frames(userdata) -> void:
		while _thread_running:
				if _playback == null:
						OS.delay_msec(10)
						continue
				var avail = _playback.get_frames_available()
				if avail > REFILL_THRESHOLD:
						_queue_mutex.lock()
						while avail > 0 and _frame_queue.size() > 0:
								_playback.push_frame(_frame_queue.pop_front())
								avail -= 1
						_queue_mutex.unlock()
						while avail > 0:
								_playback.push_frame(Vector2.ZERO)
								avail -= 1
				else:
						OS.delay_msec(5)

func _exit_tree() -> void:
	# No thread anymore.
	pass
