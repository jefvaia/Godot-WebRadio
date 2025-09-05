extends AudioStreamPlayer3D
class_name WebRadioStreamPlayer3D

@export var url: String

var _http_instance: HTTPClientInstance
var _playback: AudioStreamGeneratorPlayback

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

		_http_instance.buffer_ready.connect(_refresh_stream)

func _refresh_stream(pcm: PackedByteArray) -> void:
		if _playback == null:
				return
		var i := 0
		while i < pcm.size():
				while _playback.get_frames_available() <= 0:
						await get_tree().process_frame
				var left = pcm.decode_s16(i) / 32768.0
				var right = pcm.decode_s16(i + 2) / 32768.0
				_playback.push_frame(Vector2(left, right))
				i += 4
