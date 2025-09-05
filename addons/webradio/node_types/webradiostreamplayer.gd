extends AudioStreamPlayer
class_name WebRadioStreamPlayer

@export var url: String

var _http_instance: HTTPClientInstance

func _ready() -> void:
                self.process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD
                _http_instance = WebRadioStreamHelper.get_radio(url)

                if _http_instance == null:
                                _http_instance = WebRadioStreamHelper.add_radio(url)

                _http_instance.stream_ready.connect(_on_stream_ready)
                if _http_instance.generator != null:
                                _on_stream_ready(_http_instance.generator)

func _on_stream_ready(gen: AudioStreamGenerator) -> void:
                self.stream = gen
                self.play()
                var pb = self.get_stream_playback()
                if pb is AudioStreamGeneratorPlayback:
                                _http_instance.set_playback(pb)
