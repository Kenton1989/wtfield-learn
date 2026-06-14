extends Area2D
class_name PickUp

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
	GlobalShader.set_blink_enabled(item_sprite.material, true)
