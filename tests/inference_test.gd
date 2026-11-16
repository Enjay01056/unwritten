extends SceneTree

const INFERENCE_MODEL = preload("res://scripts/inference_model.gd")
const RESULT_ID := "inference_boat_testimony_01"
const BOAT_ID := "clue_boat_01"
const ABISA_ID := "clue_abisa_01"
const PORT_ID := "clue_port_01"
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _test_model() -> bool:
	var owned: Array[String] = [BOAT_ID, ABISA_ID, PORT_ID]
	var original_owned := owned.duplicate()
	for order in [[BOAT_ID, ABISA_ID], [ABISA_ID, BOAT_ID]]:
		var model = INFERENCE_MODEL.new()
		_check(model.load_data() == OK, "추론 JSON을 로드해야 합니다.")
		_check(model.acquired_inference_ids.is_empty(), "새 실행의 추론 목록은 비어 있어야 합니다.")
		_check(not model.can_combine(owned), "빈 슬롯에서는 조합할 수 없어야 합니다.")
		var none_owned: Array[String] = []
		_check(not model.select_clue(BOAT_ID, none_owned), "미획득 단서 선택을 차단해야 합니다.")
		_check(model.message == model.messages["unowned"], "미획득 안내가 필요합니다.")
		_check(model.slots == [{}, {}], "차단된 선택은 슬롯을 변경하면 안 됩니다.")
		_check(model.select_clue(order[0], owned), "획득한 단서를 슬롯 A에 배치해야 합니다.")
		_check(not model.select_clue(order[0], owned), "같은 단서를 중복 배치할 수 없어야 합니다.")
		_check(model.slots[1].is_empty(), "중복 배치 차단 후 B는 비어 있어야 합니다.")
		_check(model.combine(owned).is_empty(), "불완전한 슬롯으로 추론을 만들면 안 됩니다.")
		_check(model.select_clue(order[1], owned), "두 번째 단서를 배치해야 합니다.")
		_check(not model.select_clue(PORT_ID, owned), "가득 찬 슬롯에 추가 배치하면 안 됩니다.")
		_check(model.can_combine(owned), "서로 다른 보유 단서 두 개로 조합할 수 있어야 합니다.")
		_check(model.combine(owned) == RESULT_ID, "A+B와 B+A 모두 지정된 추론을 생성해야 합니다.")
		_check(model.acquired_inference_ids == [RESULT_ID], "추론을 별도 목록에 획득해야 합니다.")
		_check(model.definitions[RESULT_ID]["prototype_only"], "추론은 검증용 임시 콘텐츠여야 합니다.")
		_check(model.combine(owned) == RESULT_ID, "같은 조합은 같은 결과를 반환해야 합니다.")
		_check(model.acquired_inference_ids.size() == 1, "추론이 중복 획득되면 안 됩니다.")
		_check(model.message == model.messages["already_owned"], "이미 획득한 결과임을 안내해야 합니다.")
		model.clear_slot(0)
		_check(model.slots[0].is_empty() and not model.slots[1].is_empty(), "슬롯별 해제는 다른 슬롯을 보존해야 합니다.")
		model.reset_slots()
		_check(model.slots == [{}, {}], "초기화는 두 슬롯을 모두 비워야 합니다.")
		model.select_clue(BOAT_ID, owned)
		model.select_clue(PORT_ID, owned)
		_check(model.combine(owned).is_empty(), "등록되지 않은 조합은 추론을 만들면 안 됩니다.")
		_check(model.message == model.messages["invalid"], "잘못된 조합에는 안내 메시지를 표시해야 합니다.")
		_check(model.acquired_inference_ids == [RESULT_ID], "실패나 초기화는 기존 추론을 없애면 안 됩니다.")
		_check(owned == original_owned, "성공·실패 조합 모두 단서를 소비하면 안 됩니다.")
		# UI를 거치지 않고 잘못된 슬롯 상태를 주입해도 실행 시 소유권을 재검사합니다.
		model.slots[0] = {"kind": "clue", "id": BOAT_ID}
		model.slots[1] = {"kind": "clue", "id": ABISA_ID}
		_check(model.combine(none_owned).is_empty(), "조합 실행 시에도 미획득 단서를 차단해야 합니다.")
		model.slots[1] = {"kind": "clue", "id": BOAT_ID}
		_check(not model.can_combine(owned), "동일 단서 두 개의 비정상 슬롯도 차단해야 합니다.")
	return true


func _click(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await process_frame


func _test_ui() -> bool:
	root.size = Vector2i(1280, 720)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var screen = scene.get_node("Interface/Screen")
	var board = scene.inference_board
	await _click(screen.get_node("InferenceToggle"))
	_check(board.visible, "추론 보드 버튼으로 보드를 열 수 있어야 합니다.")
	_check(board.combine_button.disabled, "초기 조합 버튼은 비활성 상태여야 합니다.")
	await _click(board.get_node("Padding/Layout/Header/Close"))
	_check(not board.visible, "보드 닫기 버튼이 동작해야 합니다.")
	for target in ["Boat", "Abisa", "Port"]:
		await _click(screen.get_node(target))
	_check(scene.acquired_clue_ids.size() == 3, "기존 조사 입력으로 단서 세 개를 수집해야 합니다.")
	await _click(scene.clue_toggle)
	await process_frame
	await process_frame
	# 단서 목록은 이름·설명 쌍을 유지하며 이름만 선택 입력을 받습니다.
	await _click(scene.clue_entries.get_child(0))
	_check(board.visible and board.model.slots[0].get("id") == BOAT_ID, "단서 이름 클릭으로 A에 배치하고 보드를 열어야 합니다.")
	await _click(scene.clue_entries.get_child(0))
	_check(board.model.slots[1].is_empty(), "UI에서도 같은 단서의 중복 배치를 막아야 합니다.")
	await _click(scene.clue_entries.get_child(2))
	_check(board.model.slots[1].get("id") == ABISA_ID, "두 번째 이름 클릭으로 B에 배치해야 합니다.")
	_check(not board.combine_button.disabled, "두 슬롯이 채워지면 조합 버튼이 활성화되어야 합니다.")
	_check(not board.get_global_rect().intersects(scene.clue_panel.get_global_rect()), "보드와 단서 목록이 겹치면 안 됩니다.")
	for target in ["Boat", "Abisa", "Port"]:
		_check(not board.get_global_rect().intersects(screen.get_node(target).get_global_rect()), "보드가 조사 대상을 가리면 안 됩니다.")
	_check(board.get_global_rect().end.x <= 850.0 and board.get_global_rect().end.y <= 245.0, "슬롯 텍스트가 채워져도 보드는 지정 영역을 유지해야 합니다.")
	await _click(board.combine_button)
	_check(board.model.acquired_inference_ids == [RESULT_ID], "GUI 조합 버튼으로 추론을 획득해야 합니다.")
	_check(scene.acquired_clue_ids.size() == 3 and scene.clue_entries.get_child_count() == 6, "추론은 단서와 섞이지 않아야 합니다.")
	var texts: Array[String] = []
	for label in board.results.get_children():
		texts.append(label.text)
	_check(texts.has("[추론·임시] 목선과 증언의 연관성"), "추론 이름은 일반 단서와 구별되어야 합니다.")
	_check(texts.has("아비사의 증언과 포구에서 발견한 목선 사이에 연관성이 있을 가능성이 있다. 추가 조사가 필요하다."), "결과 설명을 목록에 표시해야 합니다.")
	await _click(board.combine_button)
	_check(board.model.acquired_inference_ids.size() == 1, "GUI 반복 조합도 추론을 중복 획득하면 안 됩니다.")
	await _click(board.slot_a)
	_check(board.model.slots[0].is_empty() and not board.model.slots[1].is_empty(), "슬롯 A 클릭 해제가 동작해야 합니다.")
	await _click(board.slot_b)
	_check(board.model.slots[1].is_empty(), "슬롯 B 클릭 해제가 동작해야 합니다.")
	await _click(scene.clue_entries.get_child(2))
	await _click(scene.clue_entries.get_child(0))
	await _click(board.combine_button)
	_check(board.model.acquired_inference_ids == [RESULT_ID], "GUI 역순 조합도 동일 결과를 유지해야 합니다.")
	await _click(board.get_node("Padding/Layout/Body/Controls/Actions/Reset"))
	_check(board.model.slots == [{}, {}] and board.combine_button.disabled, "GUI 초기화는 두 슬롯을 비우고 버튼을 비활성화해야 합니다.")
	await _click(scene.clue_entries.get_child(0))
	var clue_scroll: ScrollContainer = scene.get_node("Interface/Screen/CluePanel/Padding/Layout/Scroll")
	clue_scroll.ensure_control_visible(scene.clue_entries.get_child(4))
	await process_frame
	await process_frame
	await _click(scene.clue_entries.get_child(4))
	await _click(board.combine_button)
	_check(board.results.get_child(0).text == board.model.messages["invalid"], "실패한 조합의 안내 문구가 실제 UI에 표시되어야 합니다.")
	_check(scene.acquired_clue_ids.size() == 3 and board.model.acquired_inference_ids == [RESULT_ID], "실패한 GUI 조합도 단서와 기존 추론을 보존해야 합니다.")
	await _click(board.get_node("Padding/Layout/Body/Controls/Actions/Reset"))
	var scroll: ScrollContainer = board.get_node("Padding/Layout/Body/Scroll")
	await process_frame
	await process_frame
	scroll.scroll_vertical = 10000
	await process_frame
	var last: Label = board.results.get_child(board.results.get_child_count() - 1)
	_check(last.get_line_count() > 1, "추론 설명은 줄바꿈되어야 합니다.")
	_check(last.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1.0, "스크롤로 추론 설명 끝까지 확인할 수 있어야 합니다.")
	await _click(screen.get_node("InferenceToggle"))
	_check(not board.visible, "보드 버튼으로 다시 닫을 수 있어야 합니다.")
	await _click(screen.get_node("InferenceToggle"))
	_check(board.model.acquired_inference_ids == [RESULT_ID], "보드를 닫고 열어도 획득한 추론을 유지해야 합니다.")
	scene.free()
	return true


func _run() -> void:
	_check(_test_model() == true, "추론 모델 검사가 오류 없이 끝까지 완료되어야 합니다.")
	var ui_completed = await _test_ui()
	_check(ui_completed == true, "추론 UI 검사가 오류 없이 끝까지 완료되어야 합니다.")
	print("추론 모델·GUI 입력 검사: 실패 %d개" % failures)
	quit(0 if failures == 0 else 1)
