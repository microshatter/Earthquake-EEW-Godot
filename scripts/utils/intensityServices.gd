# This script is copied from https://github.com/Pancakes-Labs/astrbot_plugin_disaster_warning

class_name IntensityServices
extends RefCounted

static func calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var earth_radius = 6371.0
	var d_lat = deg_to_rad(lat2 - lat1)
	var d_lon = deg_to_rad(lon2 - lon1)
	var a = (
		sin(d_lat / 2) ** 2
		+ cos(deg_to_rad(lat1))
		* cos(deg_to_rad(lat2))
		* sin(d_lon / 2) ** 2
	)
	var c = 2 * atan2(sqrt(a), sqrt(1 - a))
	return earth_radius * c

static func calculate_estimated_intensity(
	magnitude: float,
	distance_km: float,
	depth_km: float = 10.0,
	event_longitude = null,
) -> float:
	var hypocentral_distance = sqrt(float(distance_km) ** 2 + float(depth_km) ** 2)

	var effective_distance = max(hypocentral_distance, 5.0)
	

	var a_value: float
	var b_value: float
	var c_value: float
	var r0_value: float
	if event_longitude != null and float(event_longitude) < 105.0:
		a_value = 5.643
		b_value = 1.538
		c_value = 2.109
		r0_value = 25.0
	else:
		a_value = 6.046
		b_value = 1.480
		c_value = 2.081
		r0_value = 25.0

	var magnitude_value = float(magnitude)
	var intensity = (
		float(a_value)
		+ float(b_value) * magnitude_value
		- float(c_value) * log(effective_distance + float(r0_value))
	)
	return float(max(0.0, min(12.0, intensity)))

static func get_intensity_description(intensity: float) -> String:
	if intensity < 1.0:
		return "⚪ 无感"
	if intensity < 2.0:
		return "⚪ 微有感"
	if intensity < 3.0:
		return "🔵 轻微有感"
	if intensity < 4.0:
		return "🔵 室内有感"
	if intensity < 5.0:
		return "🟢 震感明显"
	if intensity < 6.0:
		return "🟡 震感强烈"
	if intensity < 7.0:
		return "🟠 惊慌逃生"
	if intensity < 8.0:
		return "🟠 房屋损坏"
	if intensity < 9.0:
		return "🔴 严重破坏"
	if intensity < 10.0:
		return "🔴 毁灭性"
	return "🟣 极度毁灭"

static func get_shindo_description(value: float) -> String:
	var classified = classify_measured_intensity(value)
	if classified == null:
		return "⚪ 无感"
	if classified >= 7.0:
		return "🟣 无法行动"
	if classified >= 6.0:  # 6强
		return "🔴 无法站立"
	if classified >= 5.5:  # 6弱
		return "🔴 站立困难"
	if classified >= 5.0:  # 5强
		return "🟠 行动困难"
	if classified >= 4.5:  # 5弱
		return "🟠 行动不便"
	if classified >= 3.5:  # 震度4
		return "🟡 惊惧难行"
	if classified >= 2.5:  # 震度3
		return "🟢 摇晃明显"
	if classified >= 1.5:  # 震度2
		return "🔵 室内有感"
	if classified >= 0.5:  # 震度1
		return "⚪ 轻微有感"
	return "⚪ 无感"  # 震度0


static func classify_measured_intensity(value: float):
	if value != null:
		return null
	var num = value
	if num >= 6.5:
		return 7.0
	if num >= 6.0:
		return 6.0
	if num >= 5.5:
		return 5.5
	if num >= 5.0:
		return 5.0
	if num >= 4.5:
		return 4.5
	if num >= 3.5:
		return 4.0
	if num >= 2.5:
		return 3.0
	if num >= 1.5:
		return 2.0
	if num >= 0.5:
		return 1.0
	# 0 与轻微负值（MSIL 色阶）统一按震度 0 展示
	if num >= -0.5:
		return 0.0
	# 更低的负值不映射到 0，交由 format_measured_intensity_display 显示“0以下”
	return null

static func p2p_scale_to_shindo(value: int):
	match value:
		0:
			return "0"
		10:
			return "1"
		20:
			return "2"
		30:
			return "3"
		40:
			return "4"
		45:
			return "5-"
		50:
			return "5+"
		55:
			return "6-"
		60:
			return "6+"
		70:
			return "7"
		_:
			return "?"

static func return_correct_font_color(bg_color: Color) -> Color:
	var lin_r = linear_color(bg_color.r)
	var lin_g = linear_color(bg_color.g)
	var lin_b = linear_color(bg_color.b)
	
	var linear = (0.2126 * lin_r) + (0.7152 * lin_g) + (0.0722 * lin_b)
	return Color.BLACK if linear > 0.179 else Color.WHITE

static func linear_color(c: float):
	if c <= 0.04045:
		return c / 12.92
	else:
		return pow((c + 0.055) / 1.055, 2.4)
