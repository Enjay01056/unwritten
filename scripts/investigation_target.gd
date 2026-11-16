extends Button

@export var target_id: String = "boat"
@export var target_texture: Texture2D
@export_enum("boat", "npc", "trace") var placeholder_kind: String = "boat"
var is_hovered: bool = false


func _ready() -> void:
	# 실제 이미지가 준비되면 target_texture만 지정해 임시 도형을 교체합니다.
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


func _set_hovered(value: bool) -> void:
	is_hovered = value
	queue_redraw()


func _draw() -> void:
	if target_texture != null:
		draw_texture_rect(target_texture, Rect2(Vector2.ZERO, size), false)
	elif placeholder_kind == "npc":
		draw_circle(Vector2(size.x * 0.5, size.y * 0.23), size.y * 0.16, Color("c4b096"))
		draw_rect(Rect2(size * Vector2(0.27, 0.44), size * Vector2(0.46, 0.48)), Color("718b88"))
	elif placeholder_kind == "trace":
		draw_rect(Rect2(size * Vector2(0.08, 0.15), size * Vector2(0.84, 0.72)), Color("526162"))
		for fraction in [0.30, 0.50, 0.70]:
			draw_line(size * Vector2(fraction, 0.30), size * Vector2(fraction - 0.12, 0.70), Color("c2b495"), 6.0)
	else:
		var hull := PackedVector2Array([
			Vector2(size.x * 0.04, size.y * 0.35),
			Vector2(size.x * 0.96, size.y * 0.35),
			Vector2(size.x * 0.80, size.y * 0.88),
			Vector2(size.x * 0.20, size.y * 0.88)
		])
		draw_colored_polygon(hull, Color("886345"))
		draw_rect(Rect2(size * Vector2(0.17, 0.20), size * Vector2(0.66, 0.18)), Color("b18b61"))
		for fraction in [0.47, 0.62, 0.76]:
			draw_line(Vector2(size.x * 0.22, size.y * fraction), Vector2(size.x * 0.78, size.y * fraction), Color("503f32"), 3.0)
	if is_hovered:
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color.WHITE, false, 3.0)
