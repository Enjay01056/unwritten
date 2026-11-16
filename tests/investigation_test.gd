extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _move_mouse(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	root.push_input(event)
	await process_frame


func _click(position: Vector2) -> void:
	await _move_mouse(position)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var boat = scene.get_node("Interface/Screen/Boat")
	var panel = scene.get_node("Interface/Screen/CluePanel")
	var entries = scene.get_node("Interface/Screen/CluePanel/Padding/Layout/Scroll/Entries")
	_check(scene.acquired_clue_ids.is_empty(), "시작 시 단서는 없어야 합니다.")
	await _click(Vector2(1100, 65))
	_check(panel.visible, "목록 버튼 클릭 시 목록이 열려야 합니다.")
	_check(entries.get_child(0).text.contains("아직 획득한 단서가 없습니다"), "빈 목록 안내가 필요합니다.")
	await _click(Vector2(1050, 515))
	_check(not panel.visible, "닫기 버튼이 목록을 닫아야 합니다.")
	await _move_mouse(Vector2(600, 340))
	_check(boat.is_hovered, "목선 진입 시 호버가 활성화되어야 합니다.")
	await _click(Vector2(600, 340))
	_check(scene.acquired_clue_ids == ["clue_boat_01"], "첫 클릭 시 지정된 단서를 획득해야 합니다.")
	_check(scene.investigation_text.text == "오래된 목선이다. 배 안쪽에 무언가 남아 있다.", "조사 문구가 일치해야 합니다.")
	await _click(Vector2(600, 340))
	_check(scene.acquired_clue_ids.size() == 1, "반복 클릭으로 단서가 중복되어서는 안 됩니다.")
	await _move_mouse(Vector2(100, 200))
	_check(not boat.is_hovered, "목선 이탈 시 호버가 해제되어야 합니다.")
	await _click(Vector2(1100, 65))
	_check(panel.visible, "획득 후에도 목록을 열 수 있어야 합니다.")
	_check(entries.get_child_count() == 2, "목록에 이름과 설명이 하나씩 있어야 합니다.")
	var definition: Dictionary = scene.clue_definitions["clue_boat_01"]
	_check(entries.get_child(0).text == definition["name"], "목록 이름이 JSON 정의와 일치해야 합니다.")
	_check(entries.get_child(1).text == definition["description"], "목록 설명이 JSON 정의와 일치해야 합니다.")
	# 컨테이너가 새 라벨의 폭과 높이를 배치할 때까지 기다립니다.
	await process_frame
	await process_frame
	var description: Label = entries.get_child(1)
	_check(description.get_line_count() > 1, "긴 단서 설명은 여러 줄로 표시되어야 합니다.")
	_check(description.size.x <= 326.0, "설명이 패널의 내부 폭을 넘지 않아야 합니다.")
	_check(description.size.y >= description.get_minimum_size().y, "설명 높이는 전체 텍스트를 수용해야 합니다.")
	_check(description.global_position.x >= panel.global_position.x + 18.0, "목록 왼쪽 여백이 확보되어야 합니다.")
	_check(description.get_theme_constant("line_spacing") == 6, "설명에 지정된 행간이 적용되어야 합니다.")
	await _click(Vector2(1100, 65))
	_check(not panel.visible, "목록 버튼을 다시 누르면 닫혀야 합니다.")
	print("조사 프로토타입 입력·데이터 검사: 실패 %d개" % failures)
	quit(0 if failures == 0 else 1)
