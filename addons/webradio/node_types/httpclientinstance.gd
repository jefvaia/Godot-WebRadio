extends Node
class_name HTTPClientInstance

signal buffer_ready(buffer: AudioStreamMP3)

@export var radio_url: String
@export var buffer: PackedByteArray
@export var player_done_connected: bool = false

var http_client: HTTPClient
var kickstart_timer: Timer

func _ready() -> void:
	process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD
	http_client = HTTPClient.new()
	http_client.read_chunk_size = 320 / 8 * 1024 * WebRadioStreamHelper.buffering_length
	
	var url_parsed = _parse_url(radio_url)
	if url_parsed["error"] == true:
		self.queue_free()
		return
	
	http_client.connect_to_host(str(url_parsed["scheme"], "://", url_parsed["domain"]), url_parsed["port"])
	
	kickstart_timer = Timer.new()
	kickstart_timer.timeout.connect(_kickstart_callback)
	self.call_deferred("add_child", kickstart_timer, true)

func _process(delta: float) -> void:
	http_client.poll()
	
	var status = http_client.get_status()
	
	if status == HTTPClient.STATUS_BODY:
		_buffer_dat_shit()
	elif status == HTTPClient.STATUS_CONNECTED:
		http_client.request(HTTPClient.METHOD_GET, _parse_url(radio_url)["path"], [])
	elif status == HTTPClient.STATUS_CANT_CONNECT || status == HTTPClient.STATUS_CANT_RESOLVE || status == HTTPClient.STATUS_CONNECTION_ERROR || status == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR || status == HTTPClient.STATUS_DISCONNECTED:
		push_error(str("Error with connection to stream: ", radio_url))
		self.queue_free()

# I just noticed I gave this function this name. Whoops...
func _buffer_dat_shit() -> void:
	if !http_client.has_response():
		return
	if kickstart_timer != null:
		if kickstart_timer.is_stopped():
			kickstart_timer.start(WebRadioStreamHelper.buffering_length)
	
	var data = http_client.read_response_body_chunk()
	
	buffer.append_array(data)

func _parse_url(url: String) -> Dictionary:
	var result = {
		"scheme": "",
		"domain": "",
		"port": 0,
		"path": "",
		"error": false
	}
	
	# Match: scheme://host:port/path
	var regex = RegEx.new()
	regex.compile(r"^(https?)://([^/:]+)(?::(\d+))?(.*)$")
	
	var _match = regex.search(url)
	if _match:
		result.scheme = _match.get_string(1)
		result.domain = _match.get_string(2)
		result.port = int(_match.get_string(3)) if _match.get_string(3) != "" else (443 if result.scheme == "https" else 80)
		result.path = _match.get_string(4) if _match.get_string(4) != "" else "/"
	else:
		push_error("Invalid URL format: " + url)
		result["error"] = true
	
	return result

func _emit_buffer() -> void:
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = buffer
	buffer.clear()
	emit_signal("buffer_ready", audio_stream)

func player_done():
	call_deferred("_emit_buffer")

func _kickstart_callback() -> void:
	kickstart_timer.queue_free()
	_emit_buffer()
