class_name Utils
extends RefCounted

static func calculate_distance(lat1: float, long1: float, lat2: float, long2: float) -> float:
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
	
static func magnitude_to_intensity(magnitude: float, depth: float) -> Dictionary:
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

	var van_shindo = shindo
	var chinese := jma_to_chinese(shindo)
	shindo = clamp(shindo, 0.0, 7.0)

	return {"shindo": shindo, "chinese": chinese, "og_shindo": van_shindo}

static func chinese_to_jma(chinese_intensity: float) -> float:
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

static func jma_to_chinese(jma_intensity: float) -> float:
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

static func parse_jma_string(intensity_str) -> float:
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


# ⚠️ WARNING: This is a SIMPLIFIED empirical model for educational use.
# Uncertainty: ±1.0 intensity units.
# Do NOT use for life-safety decisions or official reporting.
# For production: Use official JMA/CENC real-time systems.
static func calculate_local_intensity(distance: float, maxIntensity: float, depth: float, soilType: String = "rock") -> float:
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

static func calculate_local_intensity_magnitude(distance: float, magnitude: float, depth: float) -> float:
	# Estimates the local JMA intensity (0–7) at the user's location from
	# magnitude and depth only, for feeds that don't report an intensity value.
	# Composes magnitude_to_intensity() (epicentral intensity from M & depth)
	# with the same log-distance attenuation as calculate_local_intensity().
	# ⚠️ Same simplified empirical model — ±1 unit uncertainty, educational use only.
	var epicentral := magnitude_to_intensity(magnitude, depth)
	return calculate_local_intensity(distance, epicentral.og_shindo, depth)
