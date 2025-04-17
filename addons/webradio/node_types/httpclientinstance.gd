extends Node
class_name HTTPClientInstance

signal buffer_ready(buffer: AudioStreamMP3)

@export var radio_url: String
@export var buffer: PackedByteArray
@export var player_done_connected: bool = false

var http_client: HTTPClient
var kickstart_timer: Timer

func _ready() -> void:
	http_client = HTTPClient.new()
	http_client.read_chunk_size = 8 * 1024 * 1024
	
	var url_parsed = _parse_url(radio_url)
	
	printt(url_parsed)
	
	http_client.connect_to_host(str(url_parsed["scheme"], "://", url_parsed["domain"]), url_parsed["port"])
	
	kickstart_timer = Timer.new()
	kickstart_timer.one_shot = true
	kickstart_timer.timeout.connect(_kickstart_callback)
	self.add_child(kickstart_timer, true)

func _process(delta: float) -> void:
	http_client.poll()
	
	var status = http_client.get_status()
	
	if status == HTTPClient.STATUS_BODY:
		_buffer_dat_shit()
	elif status == HTTPClient.STATUS_RESOLVING:
		printt("Resolving url")
	elif status == HTTPClient.STATUS_CONNECTING:
		printt("Connecting url")
	elif status == HTTPClient.STATUS_CONNECTED:
		printt("Connected to url")
		http_client.request(HTTPClient.METHOD_GET, _parse_url(radio_url)["path"], [])
	elif status == HTTPClient.STATUS_REQUESTING:
		printt("requesting path")
	else:
		printt("Error with url", status)
		self.queue_free()

func _buffer_dat_shit():
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
		"path": ""
	}
	
	# Match: scheme://host:port/path
	var regex = RegEx.new()
	regex.compile(r"^(https?)://([^/:]+)(?::(\d+))?(.*)$")
	
	var match = regex.search(url)
	if match:
		result.scheme = match.get_string(1)
		result.domain = match.get_string(2)
		result.port = int(match.get_string(3)) if match.get_string(3) != "" else (443 if result.scheme == "https" else 80)
		result.path = match.get_string(4) if match.get_string(4) != "" else "/"
	else:
		push_error("Invalid URL format: " + url)
	
	return result

func _emit_buffer():
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = buffer
	buffer.clear()
	emit_signal("buffer_ready", audio_stream)
	printt("Emitted buffer")

func player_done():
	_emit_buffer()

func _kickstart_callback():
	kickstart_timer.queue_free()
	_emit_buffer()
