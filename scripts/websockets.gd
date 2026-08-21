extends Node


var wolfx = WebSocketPeer.new()
var fan = WebSocketPeer.new()
var p2pq = WebSocketPeer.new()
var whews = WebSocketPeer.new()

var news_message_scene = preload("res://scenes/newswindow.tscn")

var wolfx_pinged = false
var fan_pinged = false
var p2p_pinged = false
var whews_pinged = false

var fan_attempts = 0
var fan_url = 0
var fan_is_authorized = false
var fan_key_sent = false
var fan_key_invalid = false

var whews_is_authorized = false
var whews_key_sent = false
var whews_key_invalid = false
var whews_last_invalid_key = ""
var whews_current_key = ""

var pings = {
	"wolfx": 0,
	"fan": 0,
	"p2p": 0,
	"whews": 0
}

var recieved_pinged = {
	"wolfx": false,
	"fan": false,
	"p2p": false,
	"whews": false
}

var recieved_time = {
	"wolfx": 0,
	"fan": 0,
	"p2p": 0,
	"whews": 0
}

func return_ping_time_recieved(service="wolfx"):
	var diff = recieved_time.get(service, 0.0) - pings.get(service, 0.0)
	if diff > 0:
		return "%d ms" % diff
	else:
		return "--- ms"

signal wolfx_pong()
signal fanstudio_pong()
signal p2pquake_pong()
signal whews_pong()

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

# Distance Calculation
func get_distance_from_source(latitude, longtitude):
	var opt = Utils.load_option()
	var lat = opt.latitude
	var long = opt.longitude
	return Utils.calculate_distance(lat, long, latitude, longtitude)

func add_notification(message, sec=5):
	var msg = news_message_scene.instantiate()
	msg.clear_text()
	msg.add_text(message)
	$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
	msg.start_different_hidden_timer(sec)

func send_eew(header, title, desc, distance = 0, intensity = 0):
	$"../EEW-Popup-Window/EEW-Popup".set_header(header)
	$"../EEW-Popup-Window/EEW-Popup".set_text(title)
	$"../EEW-Popup-Window/EEW-Popup".set_affected_cities(desc)
	$"../EEW-Popup-Window/EEW-Popup".set_local_eq_info(distance, intensity)
	$"../EEW-Popup-Window".show()

func print_eew(header, title, desc, reportnum):
	print("=====%s(Report #%s)=====" % [header, reportnum])
	print(title)
	print(desc)
	print("========================")

func connect_wolfx():
	wolfx.connect_to_url(API_URLs.eqUrls.wolfx_ws[0])
	wolfx_pinged = false
	$"../StatContainer/Wolfx".text = "Wolfx(Connecting)"
	$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("ffff00"))
	$"Wolfx-Ping".start()

func connect_fan():
	fan_attempts += 1
	if fan_attempts > 5:
		fan_url += 1
		if fan_url >= len(API_URLs.eqUrls.fan_ws):
			fan_url = 0
		print("Switching to " + API_URLs.eqUrls.fan_ws[fan_url])
	fan_pinged = false
	fan_is_authorized = false
	fan_key_sent = false
	fan_key_invalid = false
	if len(Utils.load_option().get("fanapi", "")) <= 0:
		add_notification("You don't have FAN Studio API key entered! Most of the data source are restricted!", 30)
	fan.connect_to_url(API_URLs.eqUrls.fan_ws[fan_url])
	$"../StatContainer/FanStudio".text = "FAN%s(Connecting)" % fan_con_type()
	$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ffff00"))
	$"FanStudio-Ping".start()

func connect_whews():
	var key = Utils.load_option().get("whewsapi", "")
	if len(key) <= 0:
		$"../StatContainer/WHEWS".text = "WHEWS(Unauthorized)"
		$"../StatContainer/WHEWS".add_theme_color_override("font_color", Color("ff0000"))
		return
	elif key == whews_last_invalid_key:
		$"../StatContainer/WHEWS".text = "WHEWS(Invalid)"
		$"../StatContainer/WHEWS".add_theme_color_override("font_color", Color("ff0000"))
		return
	whews_pinged = false
	whews_is_authorized = false
	whews_key_sent = false
	whews_key_invalid = false
	whews_current_key = key
	whews.connect_to_url(API_URLs.eqUrls.whews_ws[0] + "?token=%s" % key)
	$"../StatContainer/WHEWS".text = "WHEWS(Connecting)"
	$"../StatContainer/WHEWS".add_theme_color_override("font_color", Color("ffff00"))
	$"WHEWS-Ping".start()

func connect_p2pq():
	p2pq.connect_to_url(API_URLs.eqUrls.p2pquake_ws[0])
	p2p_pinged = false
	#p2pq.connect_to_url("ws://localhost:3000/_ws")
	$"../StatContainer/P2P".text = "P2P(Connecting)"
	$"../StatContainer/P2P".add_theme_color_override("font_color", Color("ffff00"))
	$"P2P-Ping".start()

func send_wolfx_ping():
	wolfx.send_text("ping")
	pings.set("wolfx", Time.get_ticks_msec())
	recieved_pinged.set("wolfx", false)
	$"Wolfx-Ping".start()

func send_fan_ping():
	fan.send_text("ping")
	pings.set("fan", Time.get_ticks_msec())
	recieved_pinged.set("fan", false)
	$"FanStudio-Ping".start()

func send_whews_ping():
	whews.send_text("ping")
	pings.set("whews", Time.get_ticks_msec())
	recieved_pinged.set("whews", false)
	$"WHEWS-Ping".start()

func send_p2p_ping():
	p2pq.send_text("ping")
	pings.set("p2p", Time.get_ticks_msec())
	recieved_pinged.set("p2p", false)
	$"P2P-Ping".start()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_wolfx()
	connect_fan()
	connect_p2pq()
	connect_whews()
	# send_eew("EEW Test", "Just a test btw", "test ".repeat(60), 730, Utils.calculate_local_intensity_magnitude(730, 5.9, 10))

func poll_wolfx():
	if $"../Reconnect Timer/Wolfx".time_left > 0: # Don't pull if connection lost
		return
	wolfx.poll()
	var state = wolfx.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../StatContainer/Wolfx".text = 'Wolfx(%s)' % return_ping_time_recieved("wolfx")
		$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("00ff00"))
		if not wolfx_pinged:
			send_wolfx_ping()
			wolfx_pinged = true
		while wolfx.get_available_packet_count():
			var packet = wolfx.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var message_type = json_message.type
			match message_type:
				"heartbeat":
					print("Heartbeat recieved from wolfx.")
				"pong":
					print("Wolfx pong recieved!")
					wolfx_pong.emit()
				"jma_eew":
					var title = json_message.Title
					var location = json_message.Hypocenter
					var latitude = json_message.Latitude
					var longitude = json_message.Longitude
					var distance = get_distance_from_source(latitude, longitude)
					var magnitude = json_message.get("Magunitude", json_message.get("Magnitude", 0.0))
					var depth = json_message.Depth
					if depth == null:
						depth = 0
					var warnarea = json_message.WarnArea
					var wa_str: Array[String] = []
					for i in warnarea:
						wa_str.append(i.Chiiki)
					var w: String
					if len(warnarea) > 0:
						w = "  ".join(wa_str)
					else:
						w = "警報区域はありません"
					var local_intensity = Utils.calculate_local_intensity_magnitude(distance, magnitude, depth)
					send_eew(title, "%sで地震 M%.1f 強い揺れに警戒" % [location, magnitude], w, distance, local_intensity)
					print_eew(title, "%sで地震 強い揺れに警戒" % location, w, json_message.Serial)
				"jma_eqlist":
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
					msg.set_text(PackedStringArray([
						"日本地震%s" % title,
						"%s\n%sに地震が発生しました。" % [eqtime, location]
					]))
					if len(tsunami_info) > 0:
						msg.add_text(tsunami_info)
					msg.add_text("地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth])
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				"cenc_eew", "cq_eew", "fj_eew", "sc_eew":
					var shocktime = json_message.OriginTime
					var location = json_message.HypoCenter
					var latitude = json_message.Latitude
					var longitude = json_message.Longitude
					var distance = get_distance_from_source(latitude, longitude)
					var magnitude = json_message.get("Magunitude", json_message.get("Magnitude", 0.0))
					var depth = json_message.get("Depth")
					if depth == null:
						depth = 0
					var estint = json_message.MaxIntensity
					var local_intensity = Utils.calculate_local_intensity_magnitude(distance, magnitude, depth)
					var eew_header = "Wolfx紧急地震速报（中国地震预警网）"
					var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
					var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
					send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
					print_eew(eew_header, eew_title, eew_desc, json_message.ReportNum)
				"cenc_eqlist":
					var data = json_message["No1"]
					var shocktime = data.time
					var location = data.location
					var latitude = data.latitude
					var longitude = data.longitude
					var magnitude = data.magnitude
					var depth = data.depth
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"中国地震局地震情报(Wolfx)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese",
						"%s\n在%s发生了地震" % [shocktime, location],
						"震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth]
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				_:
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"Received from Wolfx\ntype: %s" % message_type,
						message
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					print("Received from wolfx: %s" % message) # placeholder for future wolfx websocket message handling

	elif state == WebSocketPeer.STATE_CLOSING:
		$"../StatContainer/Wolfx".text = 'Wolfx(Closing)'
		$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("ff8000"))
	elif state == WebSocketPeer.STATE_CLOSED:
		if $"Wolfx-Ping".time_left > 0:
			$"Wolfx-Ping".stop()
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
		fan_attempts = 0
		var key = Utils.load_option().get("fanapi", "")
		if not fan_is_authorized:
			if len(key) > 0 and not fan_key_sent and not fan_key_invalid and Utils.FAN_STUDIO_APP_ID != null:
				var auth_payload = {
					"type": 'auth',
					"appId": Utils.FAN_STUDIO_APP_ID,
					"key": key
				}
				fan.send_text(JSON.stringify(auth_payload))
				fan_key_sent = true
			elif fan_key_sent:
				$"../StatContainer/FanStudio".text = "FAN%s(Authorizing)(%s)" % [fan_con_type(), return_ping_time_recieved("fan")]
				$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ffff00"))
			else:
				$"../StatContainer/FanStudio".text = "FAN%s(Unauthorized)(%s)" % [fan_con_type(), return_ping_time_recieved("fan")]
				$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ff8000"))
		else:
			$"../StatContainer/FanStudio".text = "FAN%s(%s)" % [fan_con_type(), return_ping_time_recieved("fan")]
			$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("00ff00"))
		if not fan_pinged:
			send_fan_ping()
			fan_pinged = true
		while fan.get_available_packet_count():
			var packet = fan.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var message_type = json_message.type
			match message_type:
				"heartbeat":
					print("Heartbeat recieved from FAN Studio.")
				"initial_all":
					print(message)
				"pong":
					print("FAN Studio Server received ping")
					fanstudio_pong.emit()
				"query_response":
					pass
				"auth_required":
					if len(key) > 0 and not fan_key_sent and not fan_key_invalid:
						fan.send_text(key)
				"auth_success":
					fan_is_authorized = true
					add_notification("FAN Studio API authorize success!")
				"auth_fail":
					fan_key_invalid = true
					var err_message = json_message.get("message")
					if err_message:
						add_notification("FAN Studio API authorize failed：%s" % err_message)
					else:
						add_notification("FAN Studio API authorize failed. Please check your API key")
				"update":
					# Fetch from data
					var data = json_message.Data
					var data_source = json_message.source
					match data_source:
						"weatheralarm":
							var time = data.effective
							var title = data.headline
							var desc = data.description
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"中国气象局气象预警(FAN Studio)\nChina Meteorological Administration Weather Warning",
								"在%s\n%s" % [time, title],
								desc
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
						"cenc":
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"中国地震局地震情报(FAN Studio)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese",
								"%s\n在%s发生了地震" % [shocktime, location],
								"震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth]
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
						"cea":
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							if depth == null:
								depth = 0
							var estint = data.epiIntensity
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = Utils.calculate_local_intensity_magnitude(distance, magnitude, depth)
							var eew_header = "紧急地震速报（中国地震预警网）"
							var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
							var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
							send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
						"cwa-eew":
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = Utils.calculate_local_intensity_magnitude(distance, magnitude, depth)
							var affected = PackedStringArray(data.locationDesc)
							var eew_header = "紧急地震速报（台湾省气象署）"
							var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
							var eew_desc = affected.join("  ")
							send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
						_:
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"Received from FAN Studio\nSource: %s" % data_source,
								JSON.stringify(data)
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							print("Received from %s(FAN Studio): %s" % [data_source, JSON.stringify(data)])
				_:
					add_notification("Received from FAN Studio\n%s" % message, 30)
					print("Received from fan: %s" % message)
	elif state == WebSocketPeer.STATE_CLOSING:
		$"../StatContainer/FanStudio".text = "FAN%s(Disconnected)" % fan_con_type()
		$"../StatContainer/FanStudio".add_theme_color_override("font_color", Color("ff8000"))
	elif state == WebSocketPeer.STATE_CLOSED:
		if $"FanStudio-Ping".time_left > 0:
			$"FanStudio-Ping".stop()
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

func poll_whews():
	if $"../Reconnect Timer/WHEWS".time_left > 0: # Don't pull if connection lost
		return
	elif whews_key_invalid:
		return
	whews.poll()
	var state = whews.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../StatContainer/WHEWS".text = "WHEWS(%s)" % return_ping_time_recieved("whews")
		$"../StatContainer/WHEWS".add_theme_color_override("font_color", Color("00ff00"))
		if not whews_pinged:
			send_whews_ping()
			whews_pinged = true
		while whews.get_available_packet_count():
			var packet = whews.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var json_type = typeof(json_message)
			if json_type == TYPE_ARRAY:
				print(message)
			elif json_type == TYPE_DICTIONARY:
				var message_type = json_message.get("type")
				var data = json_message.get("Data", {})
				var data_source = json_message.get("source", data.get("source"))
				if data_source != null:
					match data_source:
						"weatheralarm":
							var time = data.effective
							var title = data.headline
							var desc = data.description
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"中国气象局气象预警(WHEWS)\nChina Meteorological Administration Weather Warning",
								"在%s\n%s" % [time, title],
								desc
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
						"cenc":
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"中国地震局地震情报(FAN Studio)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese",
								"%s\n在%s发生了地震" % [shocktime, location],
								"震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth]
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
						_:
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"Received from WHEWS\nSource: %s" % data_source,
								JSON.stringify(data)
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							print("Received from %s(WHEWS): %s" % [data_source, JSON.stringify(data)])
				else:
					match message_type:
						"pong":
							print("WHEWS Server received ping")
							whews_pong.emit()
						"heartbeat":
							print("Heartbeat recieved from WHEWS.")
						_:
							add_notification("Received from WHEWS\n%s" % message, 300)
							print("Received from WHEWS: %s" % message)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		if $"WHEWS-Ping".time_left > 0:
			$"WHEWS-Ping".stop()
		$"../StatContainer/WHEWS".text = "WHEWS(Disconnected)"
		$"../StatContainer/WHEWS".add_theme_color_override("font_color", Color("ff0000"))
		var code = whews.get_close_code()
		var reason = whews.get_close_reason()
		print("WHEWS WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		if code == 4401:
			whews_last_invalid_key = whews_current_key
			whews_key_invalid = true

func poll_p2pq():
	if $"../Reconnect Timer/P2P".time_left > 0: # Don't pull if connection lost
		return
	p2pq.poll()
	var state = p2pq.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../StatContainer/P2P".text = "P2P(%s)" % return_ping_time_recieved("p2p")
		$"../StatContainer/P2P".add_theme_color_override("font_color", Color("00ff00"))
		if not p2p_pinged:
			send_p2p_ping()
			p2p_pinged = true
		while p2pq.get_available_packet_count():
			var packet = p2pq.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var message_type = int(json_message.code)
			match message_type:
				551:
					var eq = json_message.earthquake
					var hypocenter = eq.hypocenter
					var depth = hypocenter.depth
					var latitude = hypocenter.latitude
					var longitude = hypocenter.longitude
					var magnitude = hypocenter.magnitude
					var title = "日本地震情報"
					var eqtime = eq.time
					var location = hypocenter.name
					var tsunami_info = eq.domesticTsunami
					var foreign_info = eq.foreignTsunami
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						title,
						"%s\n%sに地震が発生しました。" % [eqtime, location],
						"津波：%s\n海外津波：%s" % [tsunami_info, foreign_info],
						"地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth]
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				552:
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"Received from P2PQuake",
						message
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
				555, 561, 9611:
					pass
				556:
					var eq = json_message.earthquake
					var hypocenter = eq.hypocenter
					var depth = hypocenter.depth
					var latitude = hypocenter.latitude
					var longitude = hypocenter.longitude
					var distance = get_distance_from_source(latitude, longitude)
					var magnitude = hypocenter.magnitude
					var location = hypocenter.name
					var title = "緊急地震速報"
					var w = "警報区域はありません"
					var local_intensity = Utils.calculate_local_intensity_magnitude(distance, magnitude, depth)
					send_eew(title, "%sで地震 M%.1f 強い揺れに警戒" % [location, magnitude], w, distance, local_intensity)
					print_eew(title, "%sで地震 強い揺れに警戒" % location, w, json_message.Serial)
				_:
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"Received from P2PQuake",
						message
					]))
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
	poll_p2pq()
	poll_whews()
	$"../StatContainer/wolfx-timer".text = "(%d)" % $"Wolfx-Ping".time_left
	$"../StatContainer/fanstudio-timer".text = "(%d)" % $"FanStudio-Ping".time_left
	$"../StatContainer/Label2".text = "(%d)" % $"P2P-Ping".time_left


func _on_wolfx_timeout() -> void:
	connect_wolfx()


func _on_fan_studio_timeout() -> void:
	connect_fan()


func _on_p2p_timeout() -> void:
	connect_p2pq()


func _on_wolfx_ping_timeout() -> void:
	if recieved_pinged.get("wolfx", false):
		send_wolfx_ping()
	else:
		wolfx.close(1000, "Connection Time Out")
		wolfx = WebSocketPeer.new()


func _on_fan_studio_ping_timeout() -> void:
	if recieved_pinged.get("fan", false):
		send_fan_ping()
	else:
		fan.close(1000, "Connection Time Out")
		fan = WebSocketPeer.new()


func _on_whews_ping_timeout() -> void:
	if recieved_pinged.get("whews", false):
		send_whews_ping()
	else:
		whews.close(1000, "Connection Time Out")
		whews = WebSocketPeer.new()


func _on_wolfx_pong() -> void:
	recieved_pinged.set("wolfx", true)
	recieved_time.set("wolfx", Time.get_ticks_msec())


func _on_fanstudio_pong() -> void:
	recieved_pinged.set("fan", true)
	recieved_time.set("fan", Time.get_ticks_msec())


func _on_p_2_pquake_pong() -> void:
	recieved_pinged.set("p2p", true)
	recieved_time.set("p2p", Time.get_ticks_msec())


func _on_whews_pong() -> void:
	recieved_pinged.set("whews", true)
	recieved_time.set("whews", Time.get_ticks_msec())
