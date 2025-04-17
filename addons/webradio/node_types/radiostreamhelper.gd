extends Node

@export var buffering_length: float = 8

func add_radio(url: String) -> HTTPClientInstance:
	var new_http_client = HTTPClientInstance.new()
	new_http_client.radio_url = url
	new_http_client.name = str(hash(url))
	self.add_child(new_http_client, true)
	return new_http_client

func get_radio(url: String) -> HTTPClientInstance:
	var hash_name = str(hash(url))
	return self.get_node_or_null(hash_name)
