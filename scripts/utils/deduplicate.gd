class_name Deduplicate
extends RefCounted

static var hash_list = PackedStringArray()
static var MAX_HASH_LIMIT: int = 5000

static func add_hash(hash_value: String):
	if not is_in_hash(hash_value):
		hash_list.append(hash_value)
		print("Added hash %s. Total count %d" % [hash_value, len(hash_list)])
	if len(hash_list) > MAX_HASH_LIMIT:
		hash_list = hash_list.slice(hash_list.size() - MAX_HASH_LIMIT)
		print(len(hash_list))

static func is_in_hash(hash_value: String):
	return hash_list.has(hash_value)
	
