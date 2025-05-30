extends AudioStreamPlayer2D
class_name WebRadioStreamPlayer2D

@export var url: String

func _ready() -> void:
	self.process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD
	
	var http_instance = WebRadioStreamHelper.get_radio(url)
	
	if http_instance == null:
		http_instance = WebRadioStreamHelper.add_radio(url)
	
	if http_instance.player_done_connected == false:
		self.finished.connect(http_instance.player_done)
		http_instance.player_done_connected = true
	http_instance.buffer_ready.connect(_refresh_stream)

func _refresh_stream(new_stream: AudioStreamMP3):
	self.set_deferred("stream", new_stream)
	self.call_deferred("play", 0)
