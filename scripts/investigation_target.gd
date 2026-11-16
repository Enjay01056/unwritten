extends Button

@export var target_id: String = "boat"
@export var target_texture: Texture2D
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
