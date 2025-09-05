extends AudioStreamPlayer3D
class_name WebRadioStreamPlayer3D

@export var url: String

var _http_instance: HTTPClientInstance

func _ready() -> void:
	self.process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD
	_http_instance = WebRadioStreamHelper.get_radio(url)
	
	if _http_instance == null:
		_http_instance = WebRadioStreamHelper.add_radio(url)
	
	self.finished.connect(_http_instance.player_done)
	_http_instance.buffer_ready.connect(_refresh_stream)

func _refresh_stream(new_stream: AudioStreamMP3):
	self.set_deferred("stream", new_stream)
	self.call_deferred("play", 0)
