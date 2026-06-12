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

func _set_timeout(timer: Timer, timeout: float, callback: Callable):
	if timeout <= 0:
		callback.call()
		return

	timer.timeout.connect(callback)
	timer.wait_time = timeout
	timer.one_shot = true
	timer.start()

func _ready() -> void:
	if config == null:
		push_error("PickUp config is missing")
		return

	item_sprite.texture = config.icon_texture

	_set_timeout(lifetime_timer, expiry_time, _on_lifetime_end)

	var stable_duration = maxf(expiry_time - blink_before_expiry, 0);
	_set_timeout(stable_display_timer, stable_duration, _on_stable_time_end)
	
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node2D):
	if config == null:
		return

	var player = body as Player
	if player == null:
		return
	
	if player.apply_pickup(config):
		queue_free()

func _on_lifetime_end():
	queue_free()

func _on_stable_time_end():
	_set_blink_enabled(true)

func _set_blink_enabled(enabled: bool) -> void:
	var item_material = item_sprite.material as ShaderMaterial;
	if item_material != null:
		item_material.set_shader_parameter(SHADER_PARAM_BLINK_ENABLED, enabled)
	else:
		push_warning("missing item material")
