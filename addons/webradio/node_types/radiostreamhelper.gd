extends Node

func add_radio(url: String) -> HTTPClientInstance:
	var new_http_client = HTTPClientInstance.new()
	new_http_client.radio_url = url
	new_http_client.name = str(hash(url))
	new_http_client.process_thread_group = Node.PROCESS_THREAD_GROUP_SUB_THREAD
	self.add_child(new_http_client, true)
	printt("Created new radio client")
	return new_http_client

func get_radio(url: String) -> HTTPClientInstance:
	var hash_name = str(hash(url))
	return self.get_node_or_null(hash_name)
