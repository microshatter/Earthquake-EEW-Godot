class_name TravelTimeTable
extends RefCounted

## P/S travel-time lookup for EEW countdowns, backed by the pre-staged tables
## in res://assets/data/travelTime/.
##
##   jma2001.json      authoritative, 0-2000 km, 0-700 km deep
##   ak135_stub.json   placeholder,   0-10000 km
##
## Grids are row-major with NON-UNIFORM axes (2/5/10 km steps):
##   p_times_s[i][j] = P seconds at depths_km[i], distances_km[j]
## Lookup is bilinear over the bracketing cell. Past 2000 km the far table is
## used and shifted so the value stays continuous at the seam.
##
##   TravelTimeTable.load_tables()
##   var t := TravelTimeTable.travel_times(depth_km, distance_km)  # (P, S)
##
## WARNING: ak135_stub.json is a constant-velocity straight-ray model
## (Vp=8.0, Vs=4.5 km/s), NOT real ak135. Replace it with an iaspei-tau
## generated table before release.
##
## If a table is missing or malformed, lookups return -1.0 so callers can keep
## using the legacy constant-velocity estimate.

const MAIN_PATH := "res://assets/data/travelTime/jma2001.json"
const FAR_PATH := "res://assets/data/travelTime/ak135_stub.json"

## Longest distance covered by the authoritative table.
const SEAM_DISTANCE_KM := 2000.0

static var _loaded := false
static var _error := ""
static var _main: Dictionary = {}
static var _far: Dictionary = {}

# --- Loading ---------------------------------------------------------------

## Parse both tables. Returns true when the authoritative table is usable.
## Call once (autoload / main._ready); repeated calls are no-ops.
static func load_tables(main_path: String = MAIN_PATH, far_path: String = FAR_PATH) -> bool:
	if _loaded:
		return is_ready()
	_main = _load_table(main_path)
	_far = _load_table(far_path)
	_loaded = true
	if _main.is_empty():
		_error = "main table unavailable: %s" % main_path
		push_error("TravelTimeTable: " + _error)
		return false
	if _far.is_empty():
		push_warning("TravelTimeTable: far table unavailable; distances past %d km are clamped"
			% int(SEAM_DISTANCE_KM))
	return true


static func is_ready() -> bool:
	return _loaded and not _main.is_empty()


## Diagnostics / About-page text.
static func describe() -> String:
	if not is_ready():
		return "TravelTimeTable: not loaded (%s)" % (_error if _error else "call load_tables()")
	var out := PackedStringArray()
	out.append("main: %s  %dx%d  [%s]" % [_main.name, _main.n_depth, _main.n_dist, _main.source])
	if _far.is_empty():
		out.append("far : (missing)")
	else:
		out.append("far : %s  %dx%d  [%s]" % [_far.name, _far.n_depth, _far.n_dist, _far.source])
	return "\n".join(out)

# --- Lookups ---------------------------------------------------------------

## P travel time in seconds, or -1.0 when the tables are unavailable.
static func p_time(depth_km: float, distance_km: float) -> float:
	if not is_ready():
		return -1.0
	return _lookup(depth_km, distance_km).x


## S travel time in seconds, or -1.0 when the tables are unavailable.
static func s_time(depth_km: float, distance_km: float) -> float:
	if not is_ready():
		return -1.0
	return _lookup(depth_km, distance_km).y


## Both arrivals as Vector2(P seconds, S seconds); Vector2(-1, -1) if no tables.
static func travel_times(depth_km: float, distance_km: float) -> Vector2:
	if not is_ready():
		return Vector2(-1.0, -1.0)
	return _lookup(depth_km, distance_km)


static func _lookup(depth_km: float, distance_km: float) -> Vector2:
	if is_nan(depth_km) or is_nan(distance_km):
		return Vector2(-1.0, -1.0)

	var max_depth: float = _main.depths[_main.n_depth - 1]
	var depth := clampf(depth_km, 0.0, max_depth)
	var dist := maxf(distance_km, 0.0)

	if dist <= SEAM_DISTANCE_KM:
		return Vector2(
			_sample(_main, depth, dist, true),
			_sample(_main, depth, dist, false))

	if _far.is_empty():
		return Vector2(
			_sample(_main, depth, SEAM_DISTANCE_KM, true),
			_sample(_main, depth, SEAM_DISTANCE_KM, false))

	# Past the authoritative horizon: take the far table, shifted by the
	# main-minus-far difference measured exactly at the seam for this depth,
	# so the countdown stays continuous in value.
	return Vector2(
		_sample(_far, depth, dist, true) + _seam_offset(depth, true),
		_sample(_far, depth, dist, false) + _seam_offset(depth, false))


static func _seam_offset(depth: float, is_p: bool) -> float:
	return _sample(_main, depth, SEAM_DISTANCE_KM, is_p) \
		- _sample(_far, depth, SEAM_DISTANCE_KM, is_p)

# --- Interpolation ---------------------------------------------------------

static func _sample(table: Dictionary, depth: float, dist: float, is_p: bool) -> float:
	var depths: PackedFloat64Array = table.depths
	var dists: PackedFloat64Array = table.distances
	var data: PackedFloat64Array = table.p if is_p else table.s
	var n_dist: int = table.n_dist
	var n_depth: int = table.n_depth

	var rb := _bracket(depths, depth)
	var cb := _bracket(dists, dist)
	var r0 := int(rb.x)
	var c0 := int(cb.x)
	var r1 := mini(r0 + 1, n_depth - 1)
	var c1 := mini(c0 + 1, n_dist - 1)

	var top: float = lerpf(data[r0 * n_dist + c0], data[r0 * n_dist + c1], cb.y)
	var bot: float = lerpf(data[r1 * n_dist + c0], data[r1 * n_dist + c1], cb.y)
	return lerpf(top, bot, rb.y)


## Binary-search a non-uniform axis -> Vector2(lower index, fraction to next).
## Values outside the axis clamp to the nearest end sample.
static func _bracket(axis: PackedFloat64Array, x: float) -> Vector2:
	var n := axis.size()
	if n == 0:
		return Vector2.ZERO
	if x <= axis[0]:
		return Vector2(0.0, 0.0)
	if x >= axis[n - 1]:
		return Vector2(float(n - 1), 0.0)

	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if axis[mid] <= x:
			lo = mid
		else:
			hi = mid

	var span := axis[hi] - axis[lo]
	var frac := 0.0 if span <= 0.0 else (x - axis[lo]) / span
	return Vector2(float(lo), frac)

# --- Table loading ---------------------------------------------------------

static func _load_table(path: String) -> Dictionary:
	var parsed: Variant = Utils.load_json_file(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("TravelTimeTable: %s unusable (missing or not a JSON object)" % path)
		return {}
	var doc: Dictionary = parsed
	for key in ["depths_km", "distances_km", "p_times_s", "s_times_s"]:
		if not doc.has(key):
			push_error("TravelTimeTable: %s is missing '%s'" % [path, key])
			return {}

	var depths_raw: Array = doc["depths_km"]
	var dists_raw: Array = doc["distances_km"]
	var p_rows: Array = doc["p_times_s"]
	var s_rows: Array = doc["s_times_s"]
	var n_depth := depths_raw.size()
	var n_dist := dists_raw.size()
	if n_depth < 2 or n_dist < 2:
		push_error("TravelTimeTable: %s has a degenerate grid" % path)
		return {}
	if p_rows.size() != n_depth or s_rows.size() != n_depth:
		push_error("TravelTimeTable: %s depth/row count mismatch" % path)
		return {}

	var depths := PackedFloat64Array()
	depths.resize(n_depth)
	for i in n_depth:
		depths[i] = float(depths_raw[i])
	var dists := PackedFloat64Array()
	dists.resize(n_dist)
	for j in n_dist:
		dists[j] = float(dists_raw[j])
	if not _increasing(depths) or not _increasing(dists):
		push_error("TravelTimeTable: %s has an unsorted axis" % path)
		return {}

	var p_flat := PackedFloat64Array()
	var s_flat := PackedFloat64Array()
	p_flat.resize(n_depth * n_dist)
	s_flat.resize(n_depth * n_dist)
	for i in n_depth:
		var prow: Array = p_rows[i]
		var srow: Array = s_rows[i]
		if prow.size() != n_dist or srow.size() != n_dist:
			push_error("TravelTimeTable: %s row %d has the wrong width" % [path, i])
			return {}
		var base := i * n_dist
		for j in n_dist:
			p_flat[base + j] = float(prow[j])
			s_flat[base + j] = float(srow[j])

	return {
		"name": str(doc.get("name", path.get_file())),
		"source": str(doc.get("source", "")),
		"depths": depths,
		"distances": dists,
		"p": p_flat,
		"s": s_flat,
		"n_depth": n_depth,
		"n_dist": n_dist,
	}


static func _increasing(axis: PackedFloat64Array) -> bool:
	for i in range(1, axis.size()):
		if axis[i] <= axis[i - 1]:
			return false
	return true
