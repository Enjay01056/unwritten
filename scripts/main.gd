extends Node2D

const DATA_PATH := "res://data/investigation.json"

var clue_definitions: Dictionary = {}
var target_definitions: Dictionary = {}
# 보유 상태는 콘텐츠 정의와 분리하며, 이번 단계에서는 메모리에만 유지합니다.
var acquired_clue_ids: Array[String] = []

@onready var investigation_text: Label = $Interface/Screen/InvestigationPanel/Text
@onready var clue_panel: PanelContainer = $Interface/Screen/CluePanel
@onready var clue_entries: VBoxContainer = $Interface/Screen/CluePanel/Padding/Layout/Scroll/Entries
@onready var clue_toggle: Button = $Interface/Screen/ClueToggle


func _ready() -> void:
	_load_data()
	for target in get_tree().get_nodes_in_group("investigation_targets"):
		target.pressed.connect(_investigate.bind(target.target_id))
	clue_toggle.pressed.connect(_toggle_clues)
	$Interface/Screen/CluePanel/Padding/Layout/Close.pressed.connect(clue_panel.hide)
	_refresh_clues()


func _load_data() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("조사 데이터 파일을 열 수 없습니다: " + DATA_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		push_error("조사 데이터 JSON 형식이 올바르지 않습니다.")
		return
	var data: Dictionary = json.data
	if not data.get("clues") is Dictionary or not data.get("targets") is Dictionary:
		push_error("조사 데이터에 단서 또는 대상 정의가 없습니다.")
		return
	clue_definitions = data["clues"]
	target_definitions = data["targets"]


func _investigate(target_id: String) -> void:
	if not target_definitions.has(target_id):
		push_error("정의되지 않은 조사 대상: " + target_id)
		return
	var target: Dictionary = target_definitions[target_id]
	investigation_text.text = target["inspection_text"]
	var clue_id: String = target["clue_id"]
	if clue_definitions.has(clue_id) and not acquired_clue_ids.has(clue_id):
		acquired_clue_ids.append(clue_id)
		_refresh_clues()


func _toggle_clues() -> void:
	clue_panel.visible = not clue_panel.visible


func _refresh_clues() -> void:
	for child in clue_entries.get_children():
		clue_entries.remove_child(child)
		child.queue_free()
	clue_toggle.text = "단서 목록 (%d)" % acquired_clue_ids.size()
	if acquired_clue_ids.is_empty():
		_add_clue_label("아직 획득한 단서가 없습니다. 포구의 목선을 조사해 보세요.")
		return
	for clue_id in acquired_clue_ids:
		var clue: Dictionary = clue_definitions[clue_id]
		_add_clue_label(clue["name"], 24)
		_add_clue_label(clue["description"])


func _add_clue_label(content: String, font_size: int = 20) -> void:
	var label := Label.new()
	label.text = content
	# 자동 줄바꿈의 기준 폭을 보장하고, 긴 설명의 행간을 확보합니다.
	label.custom_minimum_size.x = 280.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("line_spacing", 6)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clue_entries.add_child(label)
