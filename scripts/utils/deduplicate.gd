class_name Deduplicate
extends RefCounted

static var hash_list = PackedStringArray()

static func add_hash(hash_value: String):
	if not is_in_hash(hash_value):
		hash_list.append(hash_value)
		print("Added hash %s. Total count %d" % [hash_value, len(hash_list)])
	if len(hash_list) > 1000:
		hash_list = hash_list.slice(hash_list.size() - 1000)
		print(len(hash_list))

static func is_in_hash(hash_value: String):
	return hash_list.has(hash_value)
	
