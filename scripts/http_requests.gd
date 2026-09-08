extends Node

var jma_url = "https://api.wolfx.jp/jma_eqlist.json"
var cenc_url = "https://api.wolfx.jp/cenc_eqlist.json"
var usgs_url = API_URLs.eqUrls.get("usgsEqlist_http")

func request_wolfx():
	$Wolfx_JMA_EQ.request(jma_url)
	$Wolfx_CENC_EQ.request(cenc_url)

func _on_wolfx_jma_eq_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return
	var json_message = JSON.parse_string(body.get_string_from_utf8())
	for i in range(1, 51):
		var noid = "No%d" % i
		var data = json_message.get(noid)
		if data == null:
			continue
		var id = data.get("EventID")
		var eqtime_full = data.get("time_full")
		var location = data.get("location")
		var depth = data.get("depth")
		var magnitude = data.get("magnitude")
		var intensity = data.get("shindo")
		$"../stats/HBox/eqHistory".add_history(intensity, 0, location, eqtime_full, float(magnitude), float(depth), "JMA", 9, id)
	print("Wolfx JMA requested and analyze complete")
	$Wolfx_JMA_EQ/Interval.start()


func _on_wolfx_cenc_eq_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return
	var json_message = JSON.parse_string(body.get_string_from_utf8())
	for i in range(1, 51):
		var noid = "No%d" % i
		var data = json_message.get(noid)
		if data == null:
			continue
		var id = data.EventID
		var shocktime = data.time
		var location = data.location
		var magnitude = data.magnitude
		var depth = data.depth
		var intensity = float(data.intensity)
		$"../stats/HBox/eqHistory".add_history(intensity, 1, location, shocktime, float(magnitude), float(depth), "CENC", 8, id)
	print("Wolfx CENC requested and analyze complete")
	$Wolfx_CENC_EQ/Interval.start()
