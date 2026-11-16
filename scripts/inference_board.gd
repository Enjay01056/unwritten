extends PanelContainer

const INFERENCE_MODEL = preload("res://scripts/inference_model.gd")

var model = INFERENCE_MODEL.new()
var investigation: Node2D

@onready var slot_a: Button = $Padding/Layout/Body/Controls/Slots/SlotA
@onready var slot_b: Button = $Padding/Layout/Body/Controls/Slots/SlotB
@onready var combine_button: Button = $Padding/Layout/Body/Controls/Actions/Combine
@onready var results: VBoxContainer = $Padding/Layout/Body/Scroll/Results


func setup(source: Node2D) -> void:
	investigation = source
	if model.load_data() != OK:
		push_error("추론 데이터 파일을 불러올 수 없습니다.")
		return
	slot_a.pressed.connect(_clear_slot.bind(0))
	slot_b.pressed.connect(_clear_slot.bind(1))
	combine_button.pressed.connect(_combine)
	$Padding/Layout/Body/Controls/Actions/Reset.pressed.connect(_reset)
	$Padding/Layout/Header/Close.pressed.connect(hide)
	refresh()


func select_clue(clue_id: String) -> void:
	show()
	model.select_clue(clue_id, investigation.acquired_clue_ids)
	refresh()


func _clear_slot(index: int) -> void:
	model.clear_slot(index)
	refresh()


func _reset() -> void:
	model.reset_slots()
	refresh()


func _combine() -> void:
	model.combine(investigation.acquired_clue_ids)
	refresh()


func refresh() -> void:
	# 새 조작의 안내가 이전 스크롤 위치 아래에 숨지 않게 합니다.
	$Padding/Layout/Body/Scroll.set_deferred("scroll_vertical", 0)
	for index in range(2):
		var button: Button = slot_a if index == 0 else slot_b
		var input: Dictionary = model.slots[index]
		var slot_name := "A" if index == 0 else "B"
		button.text = "슬롯 %s: 비어 있음" % slot_name
		if not input.is_empty():
			button.text = "%s: %s (해제)" % [slot_name, investigation.clue_definitions[input["id"]]["name"]]
	combine_button.disabled = not model.can_combine(investigation.acquired_clue_ids)
	for child in results.get_children():
		results.remove_child(child)
		child.queue_free()
	_add_result_label(model.message)
	_add_result_label("추론 결과 (%d) · 일반 단서와 별도 관리" % model.acquired_inference_ids.size())
	if model.acquired_inference_ids.is_empty():
		_add_result_label("아직 생성된 추론이 없습니다.")
	for inference_id in model.acquired_inference_ids:
		var definition: Dictionary = model.definitions[inference_id]
		_add_result_label("[추론·임시] " + definition["name"])
		_add_result_label(definition["description"])


func _add_result_label(content: String) -> void:
	var label := Label.new()
	label.text = content
	label.custom_minimum_size.x = 320.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("line_spacing", 4)
	results.add_child(label)
