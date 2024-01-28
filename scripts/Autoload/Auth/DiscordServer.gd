extends Node

const token_url = "https://discord.com/api/oauth2/token" 
const me_url = "https://discord.com/api/oauth2/@me"

var client_id: int
var client_secret: String

const environment_client_id = "DRAWDOG_DISCORD_CLIENT_ID"
const environment_client_secret = "DRAWDOG_DISCORD_CLIENT_SECRET"

const REDIRECT_IP = "127.0.0.1"
const REDIRECT_PORT = 38493

var redirect_uri = ("http://%s:%s/" % [REDIRECT_IP, REDIRECT_PORT])

var players = {}

func load_client_info():
	# Check Environment
	if OS.has_environment(environment_client_id):
		client_id = int(OS.get_environment(environment_client_id))
	if OS.has_environment(environment_client_secret):
		client_secret = OS.get_environment(environment_client_secret)
	if (client_id and client_secret):
		return true
	# Check Storage
	if FileAccess.file_exists("user://client_id"):
		client_id = int(FileAccess.open("user://client_id", FileAccess.READ).get_line().strip_edges())
	if FileAccess.file_exists("user://client_secret"):
		client_secret = FileAccess.open("user://client_secret", FileAccess.READ).get_line().strip_edges()
	return (client_id and client_secret)

func _ready():
	set_process(false)
	if not load_client_info():
		push_error("Discord Setup Failed. Client ID: %s  | Client Secret: %s" % [client_id>0, client_secret != ""])
		#get_tree().quit()

func get_token_from_code(code):
	var headers = PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	
	var query = [
		"code=%s" % code,
		"client_id=%s" % client_id,
		"client_secret=%s" % client_secret,
		"redirect_uri=%s" % redirect_uri,
		"grant_type=authorization_code"
	]
	query = query.reduce(func(accum, new): return accum + "&" + new)
	
	var http_req = HTTPRequest.new()
	add_child(http_req)
	
	var err = http_req.request(token_url, headers, HTTPClient.METHOD_POST, query)
	if err != OK:
		push_error("Token Request Failed: %s" % err)
	
	var response = await http_req.request_completed
	response = JSON.parse_string(response[3].get_string_from_utf8())
	
	http_req.queue_free()
	
	return response["access_token"]

func get_user_from_token(token):
	var headers = PackedStringArray(["Authorization: Bearer %s" % token])
	
	var http_req = HTTPRequest.new()
	add_child(http_req)
	
	var err = http_req.request(me_url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("@me Request Failed: %s" % err)
	
	var response = await http_req.request_completed
	response = JSON.parse_string(response[3].get_string_from_utf8())
	return response

func get_user_from_code(code):
	var token = await get_token_from_code(code)
	return await get_user_from_token(token)
