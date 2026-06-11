extends Area2D
class_name PickUp

const SHADER_PARAM_BLINK_ENABLED := &"blink_enabled"

@export var config: PickUpConfig
@export_range(0, 30, 0.1, "or_greater") var expiry_time: float = 5
@export_range(0, 10, 0.1, "or_greater") var blink_before_expiry: float = 1.5

@onready var stable_display_timer: Timer = $StableDisplayTimer
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var item_sprite: Sprite2D = $ItemSprite

var is_disappearing: bool = false

func _ready() -> void:
	if config == null:
		push_error("PickUp config is missing")
		return

	lifetime_timer.timeout.connect(_on_lifetime_end)
	lifetime_timer.wait_time = expiry_time
	lifetime_timer.one_shot = true
	lifetime_timer.start()

	stable_display_timer.timeout.connect(_on_stable_time_end)
	stable_display_timer.wait_time = maxf(expiry_time - blink_before_expiry, 0);
	stable_display_timer.one_shot = true
	stable_display_timer.start()

	item_sprite.texture = config.icon_texture

func _process(_delta: float) -> void:
	pass

func _on_lifetime_end():
	queue_free()

func _on_stable_time_end():
	_set_blink_enabled(true)

func _set_blink_enabled(enabled: bool) -> void:
	var item_material = item_sprite.material as ShaderMaterial;
	if item_material != null:
		item_material.set_shader_parameter(SHADER_PARAM_BLINK_ENABLED, enabled)
		push_warning("set blinking to %b" % enabled)
	else:
		push_warning("no_material")
