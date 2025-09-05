extends Node
class_name HTTPClientInstance

signal buffer_ready(buffer: AudioStreamMP3)

@export var radio_url: String
@export var buffer: PackedByteArray

var http_client: HTTPClient

const buffer_size: int = 320 * 1000
const buffer_emit_threshold: int = 320 * 1000 / 8

func _ready() -> void:
	
	while !self.is_inside_tree():
		await get_tree().process_frame
	
	http_client = HTTPClient.new()
	http_client.read_chunk_size = buffer_size
	
	var url_parsed = _parse_url(radio_url)
	if url_parsed["error"] == true:
		self.queue_free()
		return
	
	http_client.connect_to_host(str(url_parsed["scheme"], "://", url_parsed["domain"]), url_parsed["port"])

func _process(delta: float) -> void:
	
	if !self.is_inside_tree():
		return
	
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
	
	var data = http_client.read_response_body_chunk()
	
	buffer.append_array(data)
	
	if buffer.size() >= buffer_emit_threshold:
		_emit_buffer()

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
	printt("Emitted buffer")
