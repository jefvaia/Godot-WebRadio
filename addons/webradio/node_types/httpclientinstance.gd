extends Node
class_name HTTPClientInstance

signal buffer_ready(pcm: PackedByteArray)

@export var radio_url: String
@export var buffer: PackedByteArray

var http_client: HTTPClient
var decoder: Mp3Decoder = Mp3Decoder.new()

const buffer_time: float = 5
const buffer_size: int = 320 * 1000 / 8 * buffer_time * 2
const buffer_emit_threshold: int = 320 * 1000 / 8 * buffer_time

func _ready() -> void:
	http_client = HTTPClient.new()
	http_client.read_chunk_size = buffer_size
	var url_parsed := _parse_url(radio_url)
	if url_parsed["error"]:
		queue_free()
		return

	var host : String= str(url_parsed["domain"])
	var port : int = url_parsed["port"]

	if url_parsed["scheme"] == "https":
		var tls := TLSOptions.client()  # default client options
		http_client.connect_to_host(host, port, tls)
	else:
		http_client.connect_to_host(host, port)  # no TLS

func _process(_delta: float) -> void:
	if http_client == null:
		return

	http_client.poll()
	var status := http_client.get_status()

	if status == HTTPClient.STATUS_BODY:
		_buffer_dat_shit()
	elif status == HTTPClient.STATUS_CONNECTED:
		var path : String = _parse_url(radio_url)["path"]
		http_client.request(HTTPClient.METHOD_GET, path, [])
	elif status == HTTPClient.STATUS_CANT_CONNECT or status == HTTPClient.STATUS_CANT_RESOLVE \
		or status == HTTPClient.STATUS_CONNECTION_ERROR or status == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR \
		or status == HTTPClient.STATUS_DISCONNECTED:
		push_error(str("Error with connection to stream: ", radio_url))
		queue_free()

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
	var pcm := decoder.decode(buffer)  # blocking ffmpeg call
	buffer.clear()
	if pcm.size() > 0:
		emit_signal("buffer_ready", pcm)


func _on_pcm_ready(pcm: PackedByteArray) -> void:
	emit_signal("buffer_ready", pcm)
	printt("Emitted buffer")

func _exit_tree() -> void:
	# Nothing special to stop in the blocking version.
	pass
