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
var whews_cea_token = ""

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

func print_eew(header, title, desc, reportnum):
	print("=====%s(Report #%s)=====" % [header, reportnum])
	print(title)
	print(desc)
	print("========================")

func connect_wolfx():
	wolfx.connect_to_url(API_URLs.eqUrls.wolfx_ws[0])
	wolfx_pinged = false
	$"../stats/HBox/StatContainer/sources/Wolfx".text = "Wolfx(Connecting)"
	$"../stats/HBox/StatContainer/sources/Wolfx".add_theme_color_override("font_color", Color("ffff00"))
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
	$"../stats/HBox/StatContainer/sources/FanStudio".text = "FAN%s(Connecting)" % fan_con_type()
	$"../stats/HBox/StatContainer/sources/FanStudio".add_theme_color_override("font_color", Color("ffff00"))
	$"FanStudio-Ping".start()

func connect_whews():
	var key = Utils.load_option().get("whewsapi", "")
	if len(key) <= 0:
		whews_key_invalid = true
		$"../stats/HBox/StatContainer/sources/WHEWS".text = "WHEWS(Unauthorized)"
		$"../stats/HBox/StatContainer/sources/WHEWS".add_theme_color_override("font_color", Color("ff0000"))
		return
	elif key == whews_last_invalid_key:
		whews_key_invalid = true
		$"../stats/HBox/StatContainer/sources/WHEWS".text = "WHEWS(Invalid)"
		$"../stats/HBox/StatContainer/sources/WHEWS".add_theme_color_override("font_color", Color("ff0000"))
		return
	whews.inbound_buffer_size = 8388608
	whews.outbound_buffer_size = 8388608
	whews_pinged = false
	whews_is_authorized = false
	whews_key_sent = false
	whews_key_invalid = false
	whews_current_key = key
	whews.connect_to_url(API_URLs.eqUrls.whews_ws[0] + "?token=%s" % key)
	$"../stats/HBox/StatContainer/sources/WHEWS".text = "WHEWS(Connecting)"
	$"../stats/HBox/StatContainer/sources/WHEWS".add_theme_color_override("font_color", Color("ffff00"))
	$"WHEWS-Ping".start()

func connect_p2pq():
	p2pq.connect_to_url(API_URLs.eqUrls.p2pquake_ws[0])
	p2p_pinged = false
	#p2pq.connect_to_url("ws://localhost:3000/_ws")
	$"../stats/HBox/StatContainer/sources/P2P".text = "P2P(Connecting)"
	$"../stats/HBox/StatContainer/sources/P2P".add_theme_color_override("font_color", Color("ffff00"))
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

func poll_wolfx():
	if $"../Reconnect Timer/Wolfx".time_left > 0: # Don't pull if connection lost
		return
	wolfx.poll()
	var state = wolfx.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../stats/HBox/StatContainer/sources/Wolfx".text = 'Wolfx(%s)' % return_ping_time_recieved("wolfx")
		$"../stats/HBox/StatContainer/sources/Wolfx".add_theme_color_override("font_color", Color("00ff00"))
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
					var reports = json_message.get("Serial", 0)
					var isFinal = json_message.get("isFinal", false)
					var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
					$"../EEW-Popup-Window".send_eew(title, "%sで地震 M%.1f 強い揺れに警戒" % [location, magnitude], w, distance, local_intensity, reports, isFinal)
					print_eew(title, "%sで地震 強い揺れに警戒" % location, w, json_message.Serial)
				"jma_eqlist":
					var data = json_message["No1"]
					var id = data.EventID
					var title = data.Title
					var eqtime = data.time
					var eqtime_full = data.time_full
					var location = data.location
					var latitude = data.latitude
					var longitude = data.longitude
					var depth = data.depth
					var magnitude = data.magnitude
					var tsunami_info = data.info
					var intensity = data.shindo
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"日本地震%s" % title,
						"%s\n%sに地震が発生しました。" % [eqtime, location]
					]))
					if len(tsunami_info) > 0:
						msg.add_text(tsunami_info)
					msg.add_text("地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth])
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					$"../stats/HBox/eqHistory".add_history(intensity, 0, location, eqtime_full, float(magnitude), float(depth), "JMA", 9, id)
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
					var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
					var eew_header = "Wolfx紧急地震速报（中国地震预警网）"
					var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
					var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
					$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
					print_eew(eew_header, eew_title, eew_desc, json_message.ReportNum)
				"cwa_eew":
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
					var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
					var eew_header = "緊急地震速報（台灣氣象署）"
					var eew_title = "%s發生了地震 M%.1f 請注意強烈搖晃" % [location, magnitude]
					var eew_desc = "M%s | 預估最大震度：%s | 深度：%s | 緯度: %s | 經度: %s\n發生時間： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
					$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
					print_eew(eew_header, eew_title, eew_desc, json_message.ReportNum)
				"cenc_eqlist":
					var data = json_message["No1"]
					var id = data.EventID
					var shocktime = data.time
					var location = data.location
					var latitude = data.latitude
					var longitude = data.longitude
					var magnitude = data.magnitude
					var depth = data.depth
					var msg = news_message_scene.instantiate()
					var intensity = float(data.intensity)
					msg.set_text(PackedStringArray([
						"中国地震局地震情报(Wolfx)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese",
						"%s\n在%s发生了地震" % [shocktime, location],
						"震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth]
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					$"../stats/HBox/eqHistory".add_history(intensity, 1, location, shocktime, float(magnitude), float(depth), "CENC", 8, id)
				_:
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"Received from Wolfx\ntype: %s" % message_type,
						message
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					print("Received from wolfx: %s" % message) # placeholder for future wolfx websocket message handling

	elif state == WebSocketPeer.STATE_CLOSING:
		$"../stats/HBox/StatContainer/sources/Wolfx".text = 'Wolfx(Closing)'
		$"../stats/HBox/StatContainer/sources/Wolfx".add_theme_color_override("font_color", Color("ff8000"))
	elif state == WebSocketPeer.STATE_CLOSED:
		if $"Wolfx-Ping".time_left > 0:
			$"Wolfx-Ping".stop()
		$"../stats/HBox/StatContainer/sources/Wolfx".text = 'Wolfx(Disconnected)'
		$"../stats/HBox/StatContainer/sources/Wolfx".add_theme_color_override("font_color", Color("ff0000"))
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
				$"../stats/HBox/StatContainer/sources/FanStudio".text = "FAN%s(Authorizing)(%s)" % [fan_con_type(), return_ping_time_recieved("fan")]
				$"../stats/HBox/StatContainer/sources/FanStudio".add_theme_color_override("font_color", Color("ffff00"))
			else:
				$"../stats/HBox/StatContainer/sources/FanStudio".text = "FAN%s(Unauthorized)(%s)" % [fan_con_type(), return_ping_time_recieved("fan")]
				$"../stats/HBox/StatContainer/sources/FanStudio".add_theme_color_override("font_color", Color("ff8000"))
		else:
			$"../stats/HBox/StatContainer/sources/FanStudio".text = "FAN%s(%s)" % [fan_con_type(), return_ping_time_recieved("fan")]
			$"../stats/HBox/StatContainer/sources/FanStudio".add_theme_color_override("font_color", Color("00ff00"))
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
							Utils.send_system_notification("%s(%s)" % [title, time], desc)
							# var msg = news_message_scene.instantiate()
							# msg.set_text(PackedStringArray([
							# 	"中国气象局气象预警(FAN Studio)\nChina Meteorological Administration Weather Warning",
							# 	"在%s\n%s" % [time, title],
							# 	desc
							# ]))
							# $"../Flipping-Text-Window/VBoxContainer".add_child(msg)
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
							var reports = data.get("updates")
							if depth == null:
								depth = 0
							var estint = data.epiIntensity
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var eew_header = "紧急地震速报（中国地震预警网）"
							var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
							var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity, reports)
						"cwa-eew":
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var affected = PackedStringArray(data.locationDesc)
							var eew_header = "緊急地震速報（台灣氣象署）"
							var eew_title = "%s發生了地震 M%.1f 請注意強烈搖晃" % [location, magnitude]
							var eew_desc = "  ".join(affected)
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
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
		$"../stats/HBox/StatContainer/sources/FanStudio".text = "FAN%s(Disconnected)" % fan_con_type()
		$"../stats/HBox/StatContainer/sources/FanStudio".add_theme_color_override("font_color", Color("ff8000"))
	elif state == WebSocketPeer.STATE_CLOSED:
		if $"FanStudio-Ping".time_left > 0:
			$"FanStudio-Ping".stop()
		$"../stats/HBox/StatContainer/sources/FanStudio".text = "FAN%s(Disconnected)" % fan_con_type()
		$"../stats/HBox/StatContainer/sources/FanStudio".add_theme_color_override("font_color", Color("ff0000"))
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
		$"../stats/HBox/StatContainer/sources/WHEWS".text = "WHEWS(%s)" % return_ping_time_recieved("whews")
		$"../stats/HBox/StatContainer/sources/WHEWS".add_theme_color_override("font_color", Color("00ff00"))
		if not whews_pinged:
			send_whews_ping()
			whews_pinged = true
		while whews.get_available_packet_count():
			var packet = whews.get_packet()
			var message = packet.get_string_from_utf8()
			var json_message = JSON.parse_string(message)
			var json_type = typeof(json_message)
			if json_type == TYPE_ARRAY:
				for d in json_message:
					var message_type = d.get("type")
					var data = d.get("Data", {})
					var data_source = d.get("source", data.get("source"))
					var hash_value = d.get("md5", "")
					if len(hash_value) > 0:
						if Deduplicate.is_in_hash(hash_value):
							print("Duplicate entry ignored for %s with hash %s" % [data_source, hash_value])
							continue
						Deduplicate.add_hash(hash_value)
						var id = data.get("id", "")
						var shocktime = data.get("shockTime", "")
						var location = data.get("placeName")
						var latitude = data.get("latitude")
						var longitude = data.get("longitude")
						var magnitude = data.get("magnitude")
						var depth = data.get("depth", 0.0)
						if depth == null:
							depth = 0.0
						if magnitude != null:
							var intensity = data.get("maxIntensity", IntensityServices.calculate_estimated_intensity(magnitude, 0, depth, longitude))
							if data_source == "kma" and typeof(intensity) == TYPE_STRING:
								intensity = IntensityServices.kma_scale_to_intensity(data.get("maxIntensity"))
							if data_source == "jma" or data_source == "cwa":
								$"../stats/HBox/eqHistory".add_history(intensity, 0, location, shocktime, magnitude, depth, data_source, (9 if data_source == "jma" else 8), id)
							elif data_source.ends_with("eew") or data_source.begins_with("cea"):
								pass
							else:
								$"../stats/HBox/eqHistory".add_history(float(intensity), 1, location, shocktime, magnitude, depth, data_source, 8, id)
			elif json_type == TYPE_DICTIONARY:
				var message_type = json_message.get("type")
				var data = json_message.get("Data", json_message.get("data", {}))
				var data_source = json_message.get("source", data.get("source"))
				var hash_value = json_message.get("md5", "")
				if len(hash_value) > 0:
					if Deduplicate.is_in_hash(hash_value):
						print("Duplicate entry ignored")
						continue
					Deduplicate.add_hash(hash_value)
				if data_source != null:
					match data_source:
						"weatheralarm":
							var time = data.effective
							var title = data.headline
							var desc = data.description
							Utils.send_system_notification("%s(%s)" % [title, time], desc)
							# var msg = news_message_scene.instantiate()
							# msg.set_text(PackedStringArray([
							# 	"中国气象局气象预警(WHEWS)\nChina Meteorological Administration Weather Warning",
							# 	"在%s\n%s" % [time, title],
							# 	desc
							# ]))
							# $"../Flipping-Text-Window/VBoxContainer".add_child(msg)
						"jma_eew":
							var title = "緊急地震速報(%s)" % data.infoTypeName
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var distance = get_distance_from_source(latitude, longitude)
							var magnitude = data.get("magnitude", 0.0)
							var depth = data.depth
							if depth == null:
								depth = 0
							var warnarea = data.warningAreas
							var wa_str: Array[String] = []
							for i in warnarea:
								wa_str.append(i.name)
							var w: String
							if len(warnarea) > 0:
								w = "  ".join(wa_str)
							else:
								w = "警報区域はありません"
							var reports = data.get("updates", 0)
							var final_report = data.get("final", false)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							$"../EEW-Popup-Window".send_eew(title, "%sで地震 M%.1f 強い揺れに警戒" % [location, magnitude], w, distance, local_intensity, reports, final_report)
							print_eew(title, "%sで地震 強い揺れに警戒" % location, w, data.updates)
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
							var reports = data.get("updates", 0)
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var eew_header = "紧急地震速报（中国地震预警网）"
							var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
							var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity, reports)
						"cea-pr":
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							if depth == null:
								depth = 0
							var estint = data.epiIntensity
							var province = data.province
							var reports = data.get("updates", 0)
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var eew_header = "紧急地震速报（中国%s地震预警网）" % province
							var eew_title = "%s发生了地震 M%.1f 请注意强烈摇晃" % [location, magnitude]
							var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity, reports)
						"sa_eew":
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
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var eew_header = "EARTHQUAKE EARLY WARNING(ShakeAlert)"
							var eew_title = "Earthquake happening in %s  M%.1f  Please be aware of strong shaking" % [location, magnitude]
							var eew_desc = "M%s | Max Intensity：%s | Depth：%s | Latitude: %s | Longitude: %s\nShock Time： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
						"cwa_eew":
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							if depth == null:
								depth = 0
							var estint = data.epiIntensity
							var reports = data.get("updates", 0)
							var final_report = data.get("final", false)
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var eew_header = "緊急地震速報（台灣氣象署）"
							var eew_title = "%s發生了地震 M%.1f 請注意強烈搖晃" % [location, magnitude]
							var eew_desc = "M%s | 預估最大震度：%s | 深度：%s | 緯度: %s | 經度: %s\n發生時間： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity, reports, final_report)
						"kma_eew":
							var location = data.placeNameKo
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							if depth == null:
								depth = 0
							var warnarea = data.maxAreasZh
							var w: String
							if len(warnarea) > 0:
								w = "  ".join(warnarea)
							else:
								w = "警報区域はありません"
							var distance = get_distance_from_source(latitude, longitude)
							var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
							var eew_header = "緊急地震速報（KMA）"
							var eew_title = "%sで地震 M%.1f 強い揺れに警戒" % [location, magnitude]
							var eew_desc = w
							$"../EEW-Popup-Window".send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
						"cenc":
							var id = data.get("id", "")
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var intensity = IntensityServices.calculate_estimated_intensity(magnitude, 0, depth, longitude)
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"中国地震局地震情报\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese",
								"%s\n在%s发生了地震" % [shocktime, location],
								"震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth]
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							$"../stats/HBox/eqHistory".add_history(intensity, 1, location, shocktime, magnitude, depth, data_source, 8, id)
						"jma":
							var id = data.get("id", "")
							var title = data.title
							var eqtime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var depth = data.depth
							var magnitude = data.magnitude
							var intensity = data.maxIntensity
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"日本地震%s" % title,
								"%s\n%sに地震が発生しました。" % [eqtime, location]
							]))
							msg.add_text("地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth])
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							$"../stats/HBox/eqHistory".add_history(intensity, 0, location, eqtime, magnitude, depth, data_source, 9, id)
						"cwa":
							var id = data.get("id", "")
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var intensity = data.maxIntensity
							#if magnitude >= Utils.load_option().get("minmagnitude", 0.0):
							var msg = news_message_scene.instantiate()
							msg.set_text(PackedStringArray([
								"台灣氣象署地震情报",
								"In %s\nAn earthquake happans in %s" % [shocktime, location],
								"Hypocenter: %s | Latitude: %s | Longitude: %s\nM%s | Depth: %s km" % [location, latitude, longitude, magnitude, depth]
							]))
							$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							$"../stats/HBox/eqHistory".add_history(intensity, 0, location, shocktime, magnitude, depth, data_source, 8, id)
						"kma": 
							var id = data.get("id", "")
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var intensity = IntensityServices.kma_scale_to_intensity(data.get("maxIntensity"))
							if magnitude >= Utils.load_option().get("minmagnitude", 0.0):
								var msg = news_message_scene.instantiate()
								msg.set_text(PackedStringArray([
									"%s地震情报" % data_source.to_upper(),
									"In %s\nAn earthquake happans in %s" % [shocktime, location],
									"Hypocenter: %s | Latitude: %s | Longitude: %s\nM%s | Depth: %s km" % [location, latitude, longitude, magnitude, depth]
								]))
								$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							else:
								print("Earthquake happaned in %s with magnitude %s. (%s)" % [location, magnitude, data_source.to_upper()])
							$"../stats/HBox/eqHistory".add_history(intensity, 1, location, shocktime, magnitude, depth, data_source, 8, id)
						"usgs", "bmkg", "geonet", "tmd", "usp", "gfz", "ingv", "emsc", "hko", "bcsf", "nrcan", "mmd", "phivolcs", "sgc", "ga", "cenais", "gsras", "bgs", "scsn", "noa", "afad", "sed", "ssw", "ssn", "ipma":
							var id = data.get("id", "")
							var shocktime = data.shockTime
							var location = data.placeName
							var latitude = data.latitude
							var longitude = data.longitude
							var magnitude = data.magnitude
							var depth = data.depth
							var intensity = float(data.get("maxIntensity", IntensityServices.calculate_estimated_intensity(magnitude, 0, depth, longitude)))
							if magnitude >= Utils.load_option().get("minmagnitude", 0.0):
								var msg = news_message_scene.instantiate()
								msg.set_text(PackedStringArray([
									"Earthquake Information From %s" % data_source.to_upper(),
									"In %s\nAn earthquake happans in %s" % [shocktime, location],
									"Hypocenter: %s | Latitude: %s | Longitude: %s\nM%s | Depth: %s km" % [location, latitude, longitude, magnitude, depth]
								]))
								$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
							else:
								print("Earthquake happaned in %s with magnitude %s. (%s)" % [location, magnitude, data_source.to_upper()])
							$"../stats/HBox/eqHistory".add_history(intensity, 1, location, shocktime, magnitude, depth, data_source, 8, id)
						"va":
							print("%s don't recieve message but via print: %s" % [data_source.to_upper(), JSON.stringify(data)])
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
						"hello":
							var op = Utils.load_option()
							var app_id = op.get("whewsceaid", "")
							var secret = op.get("whewsceasecret", "")
							if len(secret) > 0 and len(secret) > 0:
								var auth_payload = {
									"type": "auth",
									"data": {
										"appId": app_id,
										"appSecret": secret
									}
								}
								whews.send_text(JSON.stringify(auth_payload))
							else:
								add_notification("Set a key for whews to recieve CEA and CEA-pr")
						"auth_ok":
							whews_cea_token = data.get("accessToken")
							$"WHEWS-CEA-Auth".start(data.get("expiresIn", 600) - 60)
							print("WHEWS CEA Auth success")
						"auth_fail":
							var code = data.get("code")
							var reason = data.get("message")
							add_notification("Auth failed with code %s: %s" % [code, reason])
						"error":
							add_notification("WHEWS ERROR: %s" % message, 120)
							print("WHEWS ERROR:  %s" % message)
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
		$"../stats/HBox/StatContainer/sources/WHEWS".text = "WHEWS(Disconnected)"
		$"../stats/HBox/StatContainer/sources/WHEWS".add_theme_color_override("font_color", Color("ff0000"))
		var code = whews.get_close_code()
		var reason = whews.get_close_reason()
		print("WHEWS WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		if code == 4401:
			whews_last_invalid_key = whews_current_key
			whews_key_invalid = true
			add_notification("WHEWS Authentication failed! Please check your API key, and restart the program!", INT32_MAX)
		else:
			add_notification("Connection to WHEWS lost\n" + ("WHEWS WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]) + "\nReconnect in 5s", 5)
		$"../Reconnect Timer/WHEWS".start()

func poll_p2pq():
	if $"../Reconnect Timer/P2P".time_left > 0: # Don't pull if connection lost
		return
	p2pq.poll()
	var state = p2pq.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		$"../stats/HBox/StatContainer/sources/P2P".text = "P2P(%s)" % return_ping_time_recieved("p2p")
		$"../stats/HBox/StatContainer/sources/P2P".add_theme_color_override("font_color", Color("00ff00"))
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
					var id = json_message.get("id", "")
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
					var intensity = IntensityServices.p2p_scale_to_shindo(eq.get("maxScale", 0))
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						title,
						"%s\n%sに地震が発生しました。" % [eqtime, location],
						"津波：%s\n海外津波：%s" % [tsunami_info, foreign_info],
						"地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth]
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					$"../stats/HBox/eqHistory".add_history(intensity, 0, location, eqtime, magnitude, depth, "JMA", 9, id)
				552:
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"Received from P2PQuake",
						message
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					print("Received from p2pquake: %s" % message)
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
					var local_intensity = IntensityServices.calculate_estimated_intensity(magnitude, distance, depth, longitude)
					$"../EEW-Popup-Window".send_eew(title, "%sで地震 M%.1f 強い揺れに警戒" % [location, magnitude], w, distance, local_intensity)
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
		if $"P2P-Ping".time_left > 0:
			$"P2P-Ping".stop()
		$"../stats/HBox/StatContainer/sources/P2P".text = "P2P(Disconnected)"
		$"../stats/HBox/StatContainer/sources/P2P".add_theme_color_override("font_color", Color("ff0000"))
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


func _on_wolfx_timeout() -> void:
	connect_wolfx()


func _on_fan_studio_timeout() -> void:
	connect_fan()


func _on_p2p_timeout() -> void:
	connect_p2pq()


func _on_whews_timeout() -> void:
	connect_whews()


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


func _on_p_2p_ping_timeout() -> void:
	if recieved_pinged.get("p2p", false):
		send_p2p_ping()
	else:
		p2pq.close(1000, "Connection Time Out")
		p2pq = WebSocketPeer.new()

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


func _on_whewscea_auth_timeout() -> void:
	var refresh_payload = {
		"type": "refresh",
		"data": {"accessToken": whews_cea_token}
	}
	whews.send_text(JSON.stringify(refresh_payload))
