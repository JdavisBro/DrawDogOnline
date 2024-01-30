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
	process_mode = PROCESS_MODE_ALWAYS

func login():
	if OS.has_feature("web"):
		var window = JavaScriptBridge.eval("window.location.href")
		window = "/".join(window.split("/").slice(0, -1)) + "/auth.html"
		redirect_uri = "%s" % window
	
	var query = [
		"client_id=%s" % client_id,
		"response_type=code",
		"redirect_uri=%s" % redirect_uri,
		"scope=identify"
	]
	
	var url = auth_url + "?" + query.reduce(func(accum, new): return accum + "&" + new)
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.localStorage['authcode'] = null")
		JavaScriptBridge.eval("popup = window.open('%s', 'popup', 'popup')" % url, true)
	else:
		var _err = redirect_server.listen(REDIRECT_PORT, REDIRECT_IP)
		OS.shell_open(url)

func _process(_delta):
	if OS.has_feature("web"):
		var window_url = JavaScriptBridge.eval("window.localStorage['authcode']")
		if window_url and window_url.begins_with(redirect_uri):
			var authcode = window_url.split("?")[1].split("code=")[1]
			MultiplayerManager.auth_get_tokens.rpc_id(1, authcode, redirect_uri)
			JavaScriptBridge.eval("window.localStorage['authcode'] = null")
			JavaScriptBridge.eval("popup.close()", true)
			set_process(false)
		return
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
			# value = "a" # invalid code test
			MultiplayerManager.auth_get_tokens.rpc_id(1, value)
			DisplayServer.window_request_attention()
			set_process(false)
			break
