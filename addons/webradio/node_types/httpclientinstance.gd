extends Node
class_name HTTPClientInstance

## Emitted once the audio generator is ready for playback.
signal stream_ready(stream: AudioStreamGenerator)

@export var radio_url: String
@export var buffer: PackedByteArray

var http_client: HTTPClient

# Audio generator used to feed PCM data directly to the player.
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback

const buffer_time: float = 5
const buffer_size: int = 320 * 1000 / 8 * buffer_time * 2

# Mix rate for the generated audio. Most MP3 radio streams use 44.1 kHz.
const mix_rate: int = 44100

func _ready() -> void:

        while !self.is_inside_tree():
                await get_tree().process_frame

        http_client = HTTPClient.new()
        http_client.read_chunk_size = buffer_size

        # Prepare the audio generator and expose it to any listening players.
        generator = AudioStreamGenerator.new()
        generator.mix_rate = mix_rate
        generator.buffer_length = buffer_time
        emit_signal("stream_ready", generator)

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

        if playback != null and playback.get_frames_available() < mix_rate:
                # Not enough audio in the buffer; this indicates an underrun.
                # Additional data will be queued once received in _buffer_dat_shit().
                pass

# I just noticed I gave this function this name. Whoops...
func _buffer_dat_shit() -> void:
        if !http_client.has_response():
                return

        var data = http_client.read_response_body_chunk()
        if data.is_empty():
                return

        buffer.append_array(data)

        if playback == null:
                return

        var pcm := _decode_mp3_to_pcm(buffer)
        for sample in pcm:
                playback.push_frame(Vector2(sample, sample))

        buffer.clear()

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


func set_playback(p: AudioStreamGeneratorPlayback) -> void:
        playback = p

# Placeholder MP3 decoding. This should convert the accumulated MP3 bytes
# into an array of normalized PCM samples that can be pushed to the generator.
func _decode_mp3_to_pcm(data: PackedByteArray) -> PackedFloat32Array:
        # TODO: Implement proper MP3 decoding.
        return PackedFloat32Array()
