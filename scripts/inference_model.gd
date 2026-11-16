extends RefCounted

var definitions: Dictionary = {}
var rules: Array = []
var messages: Dictionary = {}
var acquired_inference_ids: Array[String] = []
# 입력 종류와 ID를 함께 보관해 향후 추론+단서 규칙도 표현할 수 있습니다.
var slots: Array[Dictionary] = [{}, {}]
var message: String = ""


func load_data(path: String = "res://data/inference.json") -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return ERR_PARSE_ERROR
	var data: Dictionary = json.data
	if not data.get("inferences") is Dictionary or not data.get("rules") is Array or not data.get("messages") is Dictionary:
		return ERR_INVALID_DATA
	definitions = data["inferences"]
	rules = data["rules"]
	messages = data["messages"]
	message = messages["ready"]
	return OK


func select_clue(clue_id: String, owned_clue_ids: Array[String]) -> bool:
	if not owned_clue_ids.has(clue_id):
		message = messages["unowned"]
		return false
	var input := {"kind": "clue", "id": clue_id}
	if slots.has(input):
		message = messages["duplicate_input"]
		return false
	for index in range(slots.size()):
		if slots[index].is_empty():
			slots[index] = input
			message = messages["selected"]
			return true
	message = messages["full"]
	return false


func clear_slot(index: int) -> void:
	if index >= 0 and index < slots.size():
		slots[index] = {}
		message = messages["cleared"]


func reset_slots() -> void:
	slots = [{}, {}]
	message = messages["cleared"]


func can_combine(owned_clue_ids: Array[String]) -> bool:
	if slots[0].is_empty() or slots[1].is_empty() or slots[0] == slots[1]:
		return false
	for input in slots:
		if not _is_owned(input, owned_clue_ids):
			return false
	return true


func _is_owned(input: Dictionary, owned_clue_ids: Array[String]) -> bool:
	match input.get("kind", ""):
		"clue":
			return owned_clue_ids.has(input.get("id", ""))
		"inference":
			return acquired_inference_ids.has(input.get("id", ""))
	return false


func combine(owned_clue_ids: Array[String]) -> String:
	if not can_combine(owned_clue_ids):
		message = messages["incomplete"]
		return ""
	for rule in rules:
		var inputs: Array = rule.get("inputs", [])
		if inputs.size() != 2:
			continue
		if (slots[0] == inputs[0] and slots[1] == inputs[1]) or (slots[0] == inputs[1] and slots[1] == inputs[0]):
			var result_id: String = rule["result_id"]
			if not definitions.has(result_id):
				continue
			if acquired_inference_ids.has(result_id):
				message = messages["already_owned"]
				return result_id
			acquired_inference_ids.append(result_id)
			message = messages["created"]
			return result_id
	message = messages["invalid"]
	return ""
