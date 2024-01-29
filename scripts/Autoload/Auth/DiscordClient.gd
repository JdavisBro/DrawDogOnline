class_name DiscordClient
extends Node

const auth_url = "https://discord.com/oauth2/authorize"

var client_id

const REDIRECT_IP = "127.0.0.1"
const REDIRECT_PORT = 38493

var redirect_uri = ("http://%s:%s/" % [REDIRECT_IP, REDIRECT_PORT])
var redirect_server = TCPServer.new()

const redirect_response = """HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE HTML>
<html>
<head>
<style>
:root {margin: 0;}
body {
	font-family: sans-serif;
	margin: 0;
	width: 100vw;
	height: 100vh;
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
}
</style>
</head>
<body>
<h1>Login Completed!</h1>
<h2>You Can Close This Page</h2>
</body>
</html>
"""

func _init(nclient_id):
	client_id = nclient_id

func _ready():
	var _err = redirect_server.listen(REDIRECT_PORT, REDIRECT_IP)
	
	var query = [
		"client_id=%s" % client_id,
		"response_type=code",
		"redirect_uri=%s" % redirect_uri,
		"scope=identify"
	]
	
	var url = auth_url + "?" + query.reduce(func(accum, new): return accum + "&" + new)
	
	OS.shell_open(url)

func _process(_delta):
	if not redirect_server.is_connection_available():
		return
	var connection = redirect_server.take_connection()
	var request = connection.get_string(connection.get_available_bytes())
	connection.put_data(redirect_response.to_ascii_buffer())
	if not request:
		return
	var query := request.split("\n")
	for i in query:
		if i.begins_with("GET /?code="):
			var value = i.split("code=")[1].split(" HTTP/")[0]
			MultiplayerManager.auth_get_tokens.rpc_id(1, value)
			DisplayServer.window_request_attention()
			break