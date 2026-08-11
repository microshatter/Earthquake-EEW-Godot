extends Node

@onready var api_sources = $"../API-sources"

var wolfx = WebSocketPeer.new()
var fan = WebSocketPeer.new()
var p2pq = WebSocketPeer.new()

var news_message_scene = preload("res://scenes/newswindow.tscn")

var fan_attempts = 0
var fan_url = 0
var wolfx_pinged = false
var pings = {
	"wolfx": 0,
	"fan": 0
}

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
		
func calculate_distance(lat1: float, long1: float, lat2: float, long2: float) -> float:
	# Earth's radius in kilometers
	var R: float = 6371.0

	# Convert degrees to radians
	var lat1_rad: float = deg_to_rad(lat1)
	var long1_rad: float = deg_to_rad(long1)
	var lat2_rad: float = deg_to_rad(lat2)
	var long2_rad: float = deg_to_rad(long2)

	# Differences in coordinates
	var dlat: float = lat2_rad - lat1_rad
	var dlong: float = long2_rad - long1_rad

	# Haversine formula
	var a: float = sin(dlat / 2) ** 2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlong / 2) ** 2
	var c: float = 2 * atan2(sqrt(a), sqrt(1 - a))

	return R * c

# Distance Calculation
func get_distance_from_source(latitude, longtitude):
	var opt = $"..".load_option()
	var lat = opt.latitude
	var long = opt.longitude
	return calculate_distance(lat, long, latitude, longtitude)

# Helper functions for calculate earthquake informations
func magnitude_to_intensity(magnitude: float, depth: float) -> Dictionary:
	# Estimates the maximum (epicentral) intensity from magnitude and depth,
	# returning BOTH scales in one dictionary:
	#   "shindo"  → JMA 震度 0–7 (e.g. 5.5 = 5強)
	#   "chinese" → Chinese 烈度 0–12
	# ⚠️ Simplified empirical model for educational use — same caveats as
	# calculate_local_intensity(): ±1 unit uncertainty, not for life safety.

	# Epicentral JMA intensity for a shallow event, calibrated to:
	#   M4 → 2.5, M5 → 4, M6 → 5.5, M7 → 7
	var shindo := 1.5 * magnitude - 3.5

	# Depth attenuation: no penalty for focuses above 10 km; below that, each
	# factor-of-10 increase in depth costs roughly 1 intensity unit.
	if depth > 10.0:
		shindo -= log(depth / 10.0) / log(10.0)

	shindo = clamp(shindo, 0.0, 7.0)
	var chinese := jma_to_chinese(shindo)

	return {"shindo": shindo, "chinese": chinese}

# ⚠️ WARNING: This is a SIMPLIFIED empirical model for educational use.
# Uncertainty: ±1.0 intensity units.
# Do NOT use for life-safety decisions or official reporting.
# For production: Use official JMA/CENC real-time systems.
func calculate_local_intensity(distance: float, maxIntensity: float, depth: float, soilType: String = "rock") -> float:
	var hypocentral_distance := sqrt(pow(distance, 2) + pow(depth, 2))
	var site_boost := 0.0
	match soilType.to_lower():
		"soil":
			site_boost = 0.5
		"soft_soil":
			site_boost = 1.0
		_:
			site_boost = 0.0

	var beta := 1.5
	
	var intensity := maxIntensity
	if hypocentral_distance > 1.0:
		intensity = maxIntensity - beta * log(hypocentral_distance) / log(10.0) + site_boost
	return clamp(intensity, 0.0, 7.0)

func chinese_to_jma(chinese_intensity: float) -> float:
	# Approximate conversion from the Chinese 烈度 scale (0–12) to the JMA
	# scale (0–7). Rough calibration: 烈度 VI≈5, VII≈5強, VIII≈6弱, IX≈6強, X≈7.

	var jma := 0.0
	if chinese_intensity <= 0.0:
		return 0.0
	elif chinese_intensity <= 3.0:
		jma = chinese_intensity * 0.8
	elif chinese_intensity <= 5.0:
		jma = 1.5 + (chinese_intensity - 3.0) * 0.9
	elif chinese_intensity <= 8.0:
		jma = 3.5 + (chinese_intensity - 5.0) * 0.7
	elif chinese_intensity <= 10.0:
		jma = 5.5 + (chinese_intensity - 8.0) * 0.6
	else:
		jma = 7.0
	var value := float(chinese_intensity)
	return clamp(jma, 0.0, 7.0)

func jma_to_chinese(jma_intensity: float) -> float:
	# Inverse of chinese_to_jma(): converts a JMA 0–7 intensity value back to
	# the Chinese 烈度 scale (0–12).
	var value: float = clamp(jma_intensity, 0.0, 7.0)
	var chinese := 0.0
	if value <= 2.4:
		chinese = value / 0.8
	elif value <= 3.3:
		chinese = 3.0 + (value - 1.5) / 0.9
	elif value <= 5.6:
		chinese = 5.0 + (value - 3.5) / 0.7
	elif value <= 6.7:
		chinese = 8.0 + (value - 5.5) / 0.6
	else:
		# Forward mapping saturates at 烈度 X → JMA 7, so stretch X–XII over 6.7–7.
		chinese = 10.0 + (value - 6.7) / 0.3 * 2.0
	return chinese

func parse_jma_string(intensity_str) -> float:
	# Converts a JMA intensity string (e.g. "5弱", "5強", "6弱", "6強", "7", "4")
	# to a continuous value on the JMA 0–7 scale (弱 → X.0, 強 → X.5).
	
	var value := 0.0
	
	# Extract numeric part using regex
	var regex := RegEx.new()
	regex.compile("\\d+")
	var result := regex.search(intensity_str)
	
	if result:
		value = float(result.get_string())
	else:
		return 0.0
	
	# Add 0.5 for 強 (strong)
	if "強" in intensity_str:
		value += 0.5
	# "弱" (weak) stays as-is
	
	return clamp(value, 0.0, 7.0)

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
	wolfx.connect_to_url(api_sources.eqUrls.wolfx_ws[0])
	$"../StatContainer/Wolfx".text = "Wolfx(Connecting)"
	$"../StatContainer/Wolfx".add_theme_color_override("font_color", Color("ffff00"))
	$"Wolfx-Ping".start()

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
	$"FanStudio-Ping".start()

func connect_p2pq():
	p2pq.connect_to_url(api_sources.eqUrls.p2pquake_ws[0])
	#p2pq.connect_to_url("ws://localhost:3000/_ws")
	$"../StatContainer/P2P".text = "P2P(Connecting)"
	$"../StatContainer/P2P".add_theme_color_override("font_color", Color("ffff00"))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_wolfx()
	#connect_fan()
	connect_p2pq()
	#send_eew("EEW Test", "Just a test btw", "test ".repeat(60), 3000, calculate_local_intensity(730, chinese_to_jma(9), 10))

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
				print("Heartbeat recieved from wolfx. Reset wolfx ping counter to 0")
				$"Wolfx-Ping".start()
				wolfx.send_text("ping")
			elif message_type == "pong":
				print("Wolfx pong recieved!")
				$"Wolfx-Ping".start()
			elif message_type == "jma_eew":
				var title = json_message.Title
				var location = json_message.Hypocenter
				var latitude = json_message.Latitude
				var longitude = json_message.Longitude
				var distance = get_distance_from_source(latitude, longitude)
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
				var maxint = parse_jma_string(json_message.MaxIntensity)
				var local_intensity = calculate_local_intensity(distance, maxint, depth)
				send_eew(title, "%sで地震 強い揺れに警戒" % location, w, distance, local_intensity)
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
				msg.set_text(PackedStringArray([
					"日本地震%s" % title,
					"%s\n%sに地震が発生しました。" % [eqtime, location]
				]))
				if len(tsunami_info) > 0:
					msg.add_text(tsunami_info)
				msg.add_text("地震発生場所：%s | 緯度：%s | 経度：%s\nマグニチュード%s | 震源の深さ：%s" % [location, latitude, longitude, magnitude, depth])
				$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
			elif message_type == "cenc_eew":
				var shocktime = json_message.OriginTime
				var location = json_message.HypoCenter
				var latitude = json_message.Latitude
				var longitude = json_message.Longitude
				var distance = get_distance_from_source(latitude, longitude)
				var magnitude = json_message.Magnitude
				var depth = json_message.Depth
				if depth == null:
					depth = 0
				var estint = json_message.MaxIntensity
				var local_intensity = calculate_local_intensity(distance, chinese_to_jma(estint), depth)
				var eew_header = "Wolfx紧急地震速报（中国地震预警网）"
				var eew_title = "%s发生了地震  请注意强烈摇晃" % location
				var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
				send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
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
				msg.set_text(PackedStringArray([
					"中国地震局地震情报(Wolfx)\nChina Earthquake Networks Center Earthquake Report\n以下内容将使用中文 The follow content will using Chinese",
					"%s\n在%s发生了地震" % [shocktime, location],
					"震源: %s | 纬度: %s | 经度: %s\nM%s | 深度: %s" % [location, latitude, longitude, magnitude, depth]
				]))
				$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
			else:
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
				$"FanStudio-Ping".start()
				fan.send_text('ping')
			elif message_type == "initial_all":
				pass # placeholder for more initial info
				print(message)
			elif message_type == "query_response":
				pass # not used
			elif message_type == "pong":
				print("FAN Studio Server received ping")
				$"FanStudio-Ping".start()
				pass
			elif message_type == "auth_required":
				if len($"../Options/Options/VBoxContainer/Settings/FanApi/LineEdit".text) > 0:
					fan.send_text($"../Options/Options/VBoxContainer/Settings/FanApi/LineEdit".text) # No authencation key obtained
			elif message_type == "update":
				# Fetch from data
				var data = json_message.Data
				var data_source = json_message.source
				if data_source == "weatheralarm": # 天气预警 Weather Alert
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
				elif data_source == "cenc": # 中国地震局地震速报 China Earthquake Networks Center Earthquake Report
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
				elif data_source == "cea":
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
					var local_intensity = calculate_local_intensity(distance, chinese_to_jma(estint), depth)
					var eew_header = "紧急地震速报（中国地震预警网）"
					var eew_title = "%s发生了地震  请注意强烈摇晃" % location
					var eew_desc = "M%s | 预估最大烈度：%s | 深度：%s | 纬度: %s | 经度: %s\n发生时间： %s" % [magnitude, estint, depth, latitude, longitude, shocktime]
					send_eew(eew_header, eew_title, eew_desc, distance, local_intensity)
				elif data_source == "cwa-eew":
					var location = data.placeName
					var affected = PackedStringArray(data.locationDesc)
					var eew_header = "紧急地震速报（台湾省气象署）"
					var eew_title = "%s发生了地震  请注意强烈摇晃" % location
					var eew_desc = affected.join("  ")
					send_eew(eew_header, eew_title, eew_desc)
				else:
					var msg = news_message_scene.instantiate()
					msg.set_text(PackedStringArray([
						"Received from FAN Studio\nSource: %s" % data_source,
						JSON.stringify(data)
					]))
					$"../Flipping-Text-Window/VBoxContainer".add_child(msg)
					print("Received from %s(FAN Studio): %s" % [data_source, JSON.stringify(data)]) 
					
			else:
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
	#poll_fan()
	poll_p2pq()
	$"../StatContainer/wolfx-timer".text = "(%d)" % $"Wolfx-Ping".time_left
	$"../StatContainer/fanstudio-timer".text = "(%d)" % $"FanStudio-Ping".time_left


func _on_wolfx_timeout() -> void:
	connect_wolfx()


func _on_fan_studio_timeout() -> void:
	connect_fan()


func _on_p2p_timeout() -> void:
	connect_p2pq()


func _on_wolfx_ping_timeout() -> void:
	wolfx.close(1000, "Connection Time Out")
	wolfx = WebSocketPeer.new()


func _on_fan_studio_ping_timeout() -> void:
	fan.close(1000, "Connection Time Out")
	fan = WebSocketPeer.new()
