extends Node

@onready var api_sources = $"../API-sources"

var wolfx = WebSocketPeer.new()
var fan = WebSocketPeer.new()
var p2pq = WebSocketPeer.new()

var news_message_scene = preload("res://scenes/newswindow.tscn")

var fan_attempts = 0

func add_notification(message, sec):
	var msg = news_message_scene.instantiate()
	msg.clear_text()
	msg.add_text(message)
	$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
	msg.start_different_hidden_timer(sec)

func connect_wolfx():
	wolfx.connect_to_url(api_sources.eqUrls.wolfx_ws[0])
	$"../StatContainer/Wolfx".text = "Wolfx(Connecting)"
	$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("ffff00"))

func connect_fan():
	fan_attempts += 1
	if fan_attempts > 5:
		pass
	fan.connect_to_url(api_sources.eqUrls.fan_ws[0])
	$"../StatContainer/FanStudio".text = "FAN(Connecting)"
	$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ffff00"))

func connect_p2pq():
	p2pq.connect_to_url(api_sources.eqUrls.p2pquake_ws[0])
	$"../StatContainer/P2P".text = "P2P(Connecting)"
	$"../StatContainer/P2P".add_theme_color_override("font_color", Color("ffff00"))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_wolfx()
	connect_fan()
	#connect_p2pq()

func poll_wolfx():
	if $"../Reconnect Timer/Wolfx".time_left > 0: # Don't pull if connection lost
		return
	wolfx.poll()
	var state = wolfx.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../StatContainer/Wolfx".text = 'Wolfx'
		$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("00ff00"))
		while wolfx.get_available_packet_count():
			var packet = wolfx.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var message_type = json_message.type
			if message_type == "heartbeat":
				print("Heartbeat recieved from wolfx.")
			else:
				var msg = news_message_scene.instantiate()
				msg.clear_text()
				msg.add_text("Received from Wolfx")
				msg.add_text(message)
				$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				print("Received from wolfx: %s" % message) # placeholder for future wolfx websocket message handling
	elif state == WebSocketPeer.STATE_CLOSING:
		add_notification("Wolfx connection is closing!", 10)
	elif state == WebSocketPeer.STATE_CLOSED:
		$"../StatContainer/Wolfx".text = 'Wolfx(Disconnected)'
		$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("ff0000"))
		var code = wolfx.get_close_code()
		var reason = wolfx.get_close_reason()
		var text = "Wolfx WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1]
		print(text)
		add_notification("Connect to Wolfx Lost\n%s\nReconnect in 5s" % text, 5)
		$"../Reconnect Timer/Wolfx".start()


func poll_fan():
	if $"../Reconnect Timer/FanStudio".time_left > 0: # Don't pull if connection lost
		return
	fan.poll()
	var state = fan.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../StatContainer/FanStudio".text = "FAN"
		$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("00ff00"))
		while fan.get_available_packet_count():
			var packet = fan.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var message_type = json_message.type
			if message_type == "heartbeat":
				print("Heartbeat recieved from FanStudio.")
				fan.send("ping".to_utf8_buffer())
			elif message_type == "initial_all":
				pass # placeholder for more initial info
			elif message_type == "query_response":
				pass # not used
			elif message_type == "pong":
				#print("Server received ping")
				pass
			elif message_type == "update":
				# Fetch from data
				var data = json_message.Data
				var data_source = json_message.source
				if data_source == "weatheralarm": # 天气预警 Weather Alert
					var time = data.effective
					var title = data.headline
					var desc = data.description
					var msg = news_message_scene.instantiate()
					msg.clear_text()
					msg.add_text("中国气象局气象预警\nChina Meteorological Administration Weather Warning")
					msg.add_text("在%s\n%s" % [time, title])
					msg.add_text(desc)
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				elif data_source == "cenc": # 中国地震局地震速报 China Earthquake Networks Center Earthquake Report
					var shocktime = data.shockTime
					var location = data.placeName
					var latitude = data.latitude
					var longitude = data.longitude
					var magnitude = data.magnitude
					var depth = data.depth
					var msg = news_message_scene.instantiate()
					msg.clear_text()
					msg.add_text("中国地震局地震速报\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese")
					msg.add_text("%s\n在%s发生了地震" % [shocktime, location])
					msg.add_text("震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth])
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				elif data_source == "cea":
					var shocktime = data.shockTime
					var location = data.placeName
					var latitude = data.latitude
					var longitude = data.longitude
					var magnitude = data.magnitude
					var depth = data.depth
					var estint = data.epiIntensity
					$"../EEW-Popup-Window/EEW-Popup".set_header("紧急地震速报（中国地震预警网）")
					$"../EEW-Popup-Window/EEW-Popup".set_text("%s发生了地震  请注意强烈摇晃" % location)
					# Below is not cities affected, but some information
					$"../EEW-Popup-Window/EEW-Popup".set_affected_cities("M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime])
					$"../EEW-Popup-Window".show()
				elif data_source == "cwa-eew":
					var location = data.placeName
					var affected = PackedStringArray(data.locationDesc)
					$"../EEW-Popup-Window/EEW-Popup".set_header("紧急地震速报（台湾省气象署）")
					$"../EEW-Popup-Window/EEW-Popup".set_text("%s发生了地震  请注意强烈摇晃" % location)
					$"../EEW-Popup-Window/EEW-Popup".set_affected_cities(affected.join("  "))
					$"../EEW-Popup-Window".show()
				else:
					var msg = news_message_scene.instantiate()
					msg.clear_text()
					msg.add_text("Received from FanStudio\nSource: %s" % data_source)
					msg.add_text(message)
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					print("Received from fan: %s" % message) # placeholder for future fanstudio websocket message handling
			else:
				add_notification("Received from FanStudio\n%s" % message, 30)
				print("Received from fan: %s" % message) 
	elif state == WebSocketPeer.STATE_CLOSING:
		add_notification("FanStudio connection is closing!", 10)
	elif state == WebSocketPeer.STATE_CLOSED:
		$"../StatContainer/FanStudio".text = "FAN(Disconnected)"
		$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ff0000"))
		var code = fan.get_close_code()
		var reason = fan.get_close_reason()
		print("FanStudio WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		add_notification("Connect to FanStudio Lost\n" + ("FanStudio WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]) + "\nReconnect in 5s", 5)
		$"../Reconnect Timer/FanStudio".start()

func poll_p2pq():
	if $"../Reconnect Timer/P2P".time_left > 0: # Don't pull if connection lost
		return
	p2pq.poll()
	var state = p2pq.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../StatContainer/P2P".text = "P2P"
		$"../StatContainer/P2P".add_theme_color_override("font_color", Color("00ff00"))
		while p2pq.get_available_packet_count():
			var packet = p2pq.get_packet()
			var message = packet.get_string_from_utf8()
			#var msg = news_message_scene.instantiate()
			#msg.clear_text()
			#msg.add_text("Received from P2PQuake")
			#msg.add_text(message)
			#$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
			print("Received from p2pquake: %s" % message) # placeholder for future p2pquake websocket message handling
	elif state == WebSocketPeer.STATE_CLOSING:
		add_notification("P2PQuake connection is closing!", 10)
	elif state == WebSocketPeer.STATE_CLOSED:
		$"../StatContainer/P2P".text = "P2P(Disconnected)"
		$"../StatContainer/P2P".add_theme_color_override("font_color", Color("ff0000"))
		var code = p2pq.get_close_code()
		var reason = p2pq.get_close_reason()
		print("P2PQuake WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		add_notification("Connection to P2PQuake lost\n" + ("P2PQuake WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]) + "\nReconnect in 5s", 5)
		$"../Reconnect Timer/P2P".start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	poll_wolfx()
	poll_fan()
	#poll_p2pq()


func _on_wolfx_timeout() -> void:
	connect_wolfx()


func _on_fan_studio_timeout() -> void:
	connect_fan()


func _on_p2p_timeout() -> void:
	connect_p2pq()
