extends Node

@export var buffering_length: float = 0.5

func add_radio(url: String) -> HTTPClientInstance:
	var new_http_client = HTTPClientInstance.new()
	new_http_client.radio_url = url
	new_http_client.name = str(hash(url))
	self.add_child(new_http_client, true)
	printt("Created new radio client")
	return new_http_client

func get_radio(url: String) -> HTTPClientInstance:
	var hash_name = str(hash(url))
	return self.get_node_or_null(hash_name)
