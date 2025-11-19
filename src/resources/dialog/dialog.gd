extends Resource

class_name Dialog

@export var dialogs = {}

func load_from_json(file_path):
	var data = FileAccess.get_file_as_string(file_path)
	var parsed_data = JSON.parse_string(data)
	
	if parsed_data:
		dialogs = parsed_data
	else:
		print("Lỗi load dữ liệu dialog", parsed_data)

func get_npc_dialog(npc_id):
	if npc_id in dialogs:
		return dialogs[npc_id]["trees"]
	else:
		return []
