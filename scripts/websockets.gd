extends Node

@onready var api_sources = $"../API-sources"

var wolfx = WebSocketPeer.new()
var fan = WebSocketPeer.new()
var p2pq = WebSocketPeer.new()

var news_message_scene = preload("res://scenes/newswindow.tscn")

var fan_attempts = 0
var fan_url = 0
var wolfx_pinged = false

func fan_con_type(full = false):
	var t
	if full:
		t = "[Backup URL]"
	else:
		t = "[B]"
	if fan_url == 1:
		return t
	else:
		return ""

func add_notification(message, sec=5):
	var msg = news_message_scene.instantiate()
	msg.clear_text()
	msg.add_text(message)
	$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
	msg.start_different_hidden_timer(sec)
	
func send_eew(header, title, desc):
	$"../EEW-Popup-Window/EEW-Popup".set_header(header)
	$"../EEW-Popup-Window/EEW-Popup".set_text(title)
	$"../EEW-Popup-Window/EEW-Popup".set_affected_cities(desc)
	$"../EEW-Popup-Window".show()

func print_eew(header, title, desc, reportnum):
	print("=====%s(Report #%s)=====" % [header, reportnum])
	print(title)
	print(desc)
	print("========================")

func connect_wolfx():
	wolfx.connect_to_url(api_sources.eqUrls.wolfx_ws[0])
	$"../StatContainer/Wolfx".text = "Wolfx(Connecting)"
	$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("ffff00"))

func connect_fan():
	fan_attempts += 1
	if fan_attempts > 5:
		fan_url += 1
		if fan_url >= len(api_sources.eqUrls.fan_ws):
			fan_url = 0
		print("Switching to " + api_sources.eqUrls.fan_ws[fan_url])
	fan.connect_to_url(api_sources.eqUrls.fan_ws[fan_url])
	$"../StatContainer/FanStudio".text = "FAN%s(Connecting)" % fan_con_type()
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
				wolfx.send_text("ping")
			elif message_type == "pong":
				pass
			elif message_type == "jma_eew":
				var msg = news_message_scene.instantiate()
				var title = json_message.Title
				var location = json_message.Hypocenter
				var warnarea = json_message.WarnArea
				var wa_str: Array[String] = []
				for i in warnarea:
					wa_str.append(i.Chiiki)
				var w: String
				if len(warnarea) > 0:
					w = "  ".join(wa_str)
				else:
					w = "No warn areas"
				send_eew(title, "%sで地震 強い揺れに警戒" % location, w)
				print_eew(title, "%sで地震 強い揺れに警戒" % location, w, json_message.Serial)
			elif message_type == "jma_eqlist":
				var data = json_message["No1"]
				var title = data.Title
				var eqtime = data.time
				var location = data.location
				var latitude = data.latitude
				var longitude = data.longitude
				var depth = data.depth
				var magnitude = data.magnitude
				var tsunami_info = data.info
				var msg = news_message_scene.instantiate()
				msg.clear_text()
				msg.add_text("日本地震%s" % title)
				msg.add_text("%s\n%sに地震が発生しました。" % [eqtime, location])
				if len(tsunami_info) > 0:
					msg.add_text(tsunami_info)
				msg.add_text("地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth])
				$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
			elif message_type == "cenc_eew":
				var shocktime = json_message.OriginTime
				var location = json_message.HypoCenter
				var latitude = json_message.Latitude
				var longitude = json_message.Longitude
				var magnitude = json_message.Magnitude
				var depth = json_message.Depth
				var estint = json_message.MaxIntensity
				var eew_header = "Wolfx紧急地震速报（中国地震预警网）"
				var eew_title = "%s发生了地震  请注意强烈摇晃" % location
				var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
				send_eew(eew_header, eew_title, eew_desc)
				print_eew(eew_header, eew_title, eew_desc, json_message.ReportNum)
			elif message_type == "cenc_eqlist":
				var data = json_message["No1"]
				var shocktime = data.time
				var location = data.location
				var latitude = data.latitude
				var longitude = data.longitude
				var magnitude = data.magnitude
				var depth = data.depth
				var msg = news_message_scene.instantiate()
				msg.clear_text()
				msg.add_text("中国地震局地震情报(FAN Studio)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese")
				msg.add_text("%s\n在%s发生了地震" % [shocktime, location])
				msg.add_text("震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth])
				$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
			else:
				var msg = news_message_scene.instantiate()
				msg.clear_text()
				msg.add_text("Received from Wolfx\ntype: %s" % message_type)
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
		$"../StatContainer/FanStudio".text = "FAN%s" % fan_con_type()
		$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("00ff00"))
		fan_attempts = 0
		while fan.get_available_packet_count():
			var packet = fan.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var message_type = json_message.type
			if message_type == "heartbeat":
				print("Heartbeat recieved from FAN Studio.")
				fan.send_text("ping")
			elif message_type == "initial_all":
				pass # placeholder for more initial info
				print(message)
			elif message_type == "query_response":
				pass # not used
			elif message_type == "pong":
				#print("Server received ping")
				pass
			elif message_type == "auth_required":
				if len($"../Options/Options/VBoxContainer/Settings/FanApi/LineEdit".text) > 0:
					fan.send_text($"../Options/Options/VBoxContainer/Settings/FanApi/LineEdit".text) # No authencation key obtained
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
					msg.add_text("中国气象局气象预警(FAN Studio)\nChina Meteorological Administration Weather Warning")
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
					msg.add_text("中国地震局地震情报(FAN Studio)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese")
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
					var eew_header = "紧急地震速报（中国地震预警网）"
					var eew_title = "%s发生了地震  请注意强烈摇晃" % location
					var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
					send_eew(eew_header, eew_title, eew_desc)
				elif data_source == "cwa-eew":
					var location = data.placeName
					var affected = PackedStringArray(data.locationDesc)
					var eew_header = "紧急地震速报（台湾省气象署）"
					var eew_title = "%s发生了地震  请注意强烈摇晃" % location
					var eew_desc = affected.join("  ")
					send_eew(eew_header, eew_title, eew_desc)
				else:
					var msg = news_message_scene.instantiate()
					msg.clear_text()
					msg.add_text("Received from FAN Studio\nSource: %s" % data_source)
					msg.add_text(JSON.stringify(data))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					print("Received from %s(FAN Studio): %s" % [data_source, JSON.stringify(data)]) 
					
			else:
				add_notification("Received from FAN Studio\n%s" % message, 30)
				print("Received from fan: %s" % message) 
	elif state == WebSocketPeer.STATE_CLOSING:
		add_notification("FAN Studio connection is closing!", 10)
	elif state == WebSocketPeer.STATE_CLOSED:
		$"../StatContainer/FanStudio".text = "FAN%s(Disconnected)" % fan_con_type()
		$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ff0000"))
		var code = fan.get_close_code()
		var reason = fan.get_close_reason()
		print("FAN Studio WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		if code == 1008:
			add_notification("Max IP connection reached for FAN Studio%s.\nWait for a minute to try again\n%s" % [fan_con_type(true), reason], 60)
			fan_attempts -= 1
			$"../Reconnect Timer/FanStudio".start(60)
		else:
			add_notification(("Connect to FAN Studio%s Lost\n" % fan_con_type(true)) + ("FAN Studio WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]) + "\nReconnect in 5s", 5)
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
			var msg = news_message_scene.instantiate()
			msg.clear_text()
			msg.add_text("Received from P2PQuake")
			msg.add_text(message)
			$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
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
