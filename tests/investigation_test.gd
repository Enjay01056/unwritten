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
	scene.free()
	await _test_multiple_targets()
	print("조사 프로토타입 입력·데이터 검사: 실패 %d개" % failures)
	quit(0 if failures == 0 else 1)


func _test_multiple_targets() -> void:
	var expected := {
		"boat": {
			"node": "Boat", "position": Vector2(600, 340),
			"clue_id": "clue_boat_01", "name": "오래된 목선",
			"category": "uncategorized",
			"description": "영산포 포구에서 발견한 오래된 목선. 현재 조사 중인 왜곡 현상과 관련이 있을 수 있다.",
			"text": "오래된 목선이다. 배 안쪽에 무언가 남아 있다."
		},
		"abisa": {
			"node": "Abisa", "position": Vector2(200, 340),
			"clue_id": "clue_abisa_01", "name": "아비사의 증언",
			"category": "testimony",
			"description": "아비사는 아랑사가 배를 타고 떠난 뒤 돌아오지 않았다고 말한다. 그러나 그 이후의 상황은 명확하게 기억하지 못한다.",
			"text": "아랑사라는 사람을 찾고 있습니다. 배를 타고 떠나는 것을 보았는데, 그 이후의 일은 잘 기억나지 않습니다."
		},
		"port": {
			"node": "Port", "position": Vector2(1050, 370),
			"clue_id": "clue_port_01", "name": "포구의 흔적",
			"category": "observation",
			"description": "영산포 포구에서 발견한 오래된 흔적. 현재로서는 무엇을 의미하는지 판단하기 어렵다.",
			"text": "포구 바닥에서 오래된 흔적이 발견된다. 자세한 의미는 아직 알 수 없다."
		}
	}
	# 새 씬으로 시작해 세 대상의 모든 조사 순서를 실제 GUI 입력으로 검사합니다.
	var orders := [
		["boat", "abisa", "port"], ["boat", "port", "abisa"],
		["abisa", "boat", "port"], ["abisa", "port", "boat"],
		["port", "boat", "abisa"], ["port", "abisa", "boat"]
	]
	for order in orders:
		var scene = load("res://main.tscn").instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		_check(scene.target_definitions.size() == 3, "세 조사 대상 데이터를 로드해야 합니다.")
		_check(scene.clue_definitions.size() == 3, "서로 다른 단서 ID 세 개를 로드해야 합니다.")
		_check(get_nodes_in_group("investigation_targets").size() == 3, "씬에 조사 대상 세 개가 있어야 합니다.")
		_check(not scene.clue_definitions["clue_boat_01"].has("category"), "기존 목선의 분류 없는 스키마를 유지해야 합니다.")
		_check(scene.target_definitions["port"].get("prototype_only", false), "포구의 흔적은 임시 콘텐츠여야 합니다.")
		var expected_ids: Array[String] = []
		for target_id in order:
			var item: Dictionary = expected[target_id]
			_check(scene.target_definitions[target_id]["clue_id"] == item["clue_id"], "대상과 단서의 데이터 연결이 일치해야 합니다.")
			await _move_mouse(item["position"])
			for other_id in expected:
				var target = scene.get_node("Interface/Screen/" + expected[other_id]["node"])
				_check(target.is_hovered == (other_id == target_id), "각 대상의 호버는 독립적이어야 합니다.")
				if other_id != target_id:
					var current = scene.get_node("Interface/Screen/" + item["node"])
					_check(not current.get_global_rect().intersects(target.get_global_rect()), "조사 대상끼리 겹치면 안 됩니다.")
			await _click(item["position"])
			expected_ids.append(item["clue_id"])
			_check(scene.acquired_clue_ids == expected_ids, "조사 순서와 관계없이 각 단서를 획득해야 합니다.")
			_check(scene.investigation_text.text == item["text"], "각 대상의 지정된 조사 문구를 표시해야 합니다.")
			_check(scene.get_clue_category(item["clue_id"]) == item["category"], "선택적 단서 분류를 처리해야 합니다.")
			await _click(item["position"])
			_check(scene.acquired_clue_ids == expected_ids, "각 대상의 반복 조사로 단서가 중복되면 안 됩니다.")
			_check(scene.investigation_text.text == item["text"], "획득 후에도 재조사가 가능해야 합니다.")
		await _move_mouse(Vector2(100, 200))
		for target in get_nodes_in_group("investigation_targets"):
			_check(not target.is_hovered, "대상 이탈 시 모든 강조가 해제되어야 합니다.")
		await _click(Vector2(1100, 65))
		await process_frame
		await process_frame
		var entries = scene.clue_entries
		_check(scene.clue_toggle.text == "단서 목록 (3)", "목록 버튼은 단서 세 개를 표시해야 합니다.")
		_check(entries.get_child_count() == 6, "이름과 설명을 포함한 단서 세 개만 표시해야 합니다.")
		for index in range(order.size()):
			var item: Dictionary = expected[order[index]]
			var name_label: Label = entries.get_child(index * 2)
			var description: Label = entries.get_child(index * 2 + 1)
			_check(name_label.text == item["name"], "모든 단서 이름이 정확해야 합니다.")
			_check(description.text == item["description"], "모든 단서 설명이 정확해야 합니다.")
			_check(name_label.get_meta("category") == item["category"], "목록은 해당 단서 분류를 유지해야 합니다.")
			_check(description.get_line_count() > 1, "각 설명은 줄바꿈되어야 합니다.")
			_check(description.size.x <= 326.0, "각 설명은 내부 폭을 넘지 않아야 합니다.")
			_check(description.size.y >= description.get_minimum_size().y, "설명 텍스트 높이가 잘리지 않아야 합니다.")
		var scroll: ScrollContainer = scene.get_node("Interface/Screen/CluePanel/Padding/Layout/Scroll")
		_check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "세 단서 목록을 세로로 스크롤할 수 있어야 합니다.")
		scroll.scroll_vertical = 10000
		await process_frame
		var last_description: Label = entries.get_child(5)
		_check(last_description.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1.0, "스크롤하면 마지막 설명의 끝까지 볼 수 있어야 합니다.")
		await _click(Vector2(1050, 515))
		_check(not scene.clue_panel.visible, "세 단서 획득 후에도 목록을 닫을 수 있어야 합니다.")
		scene.free()
		await process_frame
	print("다중 조사 대상 검사: 전체 6가지 조사 순서 완료")
