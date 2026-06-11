extends CharacterBody2D

const BULLET = preload("res://scene/bullet.tscn")

const NORMAL_ANIMETION_PREFIX := &"normal"
const ARMED_ANIMETION_PREFIX := &"armed"
const DEFAULT_FIRE_SPEED := 1.0
enum PlayerMode {
	NORMAL,
	ARMED
}
enum FireMode {
	STRAIGHT,
	SPIRAL
}


@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var fire_timer: Timer = $FireTimer
@onready var armed_effect_sprite: AnimatedSprite2D = $ArmedEffectSprite

@export var move_speed: float = 120.0
@export var fire_interval: float = 0.18
@export var gun_length: float = 10.0


var player_mode: PlayerMode = PlayerMode.NORMAL
var move_direction := Vector2.ZERO
var fire_direction := Vector2.ZERO
var face_direction := Vector2.RIGHT

var fire_mode: FireMode = FireMode.STRAIGHT
var next_bullet_direction := Vector2.RIGHT
var fire_speed: float = DEFAULT_FIRE_SPEED
var armed_fire_speed: float = DEFAULT_FIRE_SPEED
var sprial_fire_speed: float = 20

var fire_countdown: float = 0.0;

func _ready() -> void:
	fire_mode = FireMode.SPIRAL

	fire_timer.one_shot = true
	fire_timer.wait_time = 0.0
	_update_body_animation()
	_update_armed_effect()

func _physics_process(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var fire_input := Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")

	move_direction = move_input.normalized()
	fire_direction = fire_input.normalized()
	if fire_direction != Vector2.ZERO:
		face_direction = fire_direction
	elif move_direction != Vector2.ZERO:
		face_direction = move_direction

	velocity = move_direction * move_speed
	move_and_slide()

	_update_body_animation()
	_update_armed_effect()
	_fire_bullets()

func _update_body_animation() -> void:
	var animation_prefix = ARMED_ANIMETION_PREFIX if _get_is_armed() else NORMAL_ANIMETION_PREFIX
	var direction_suffix: StringName = _vector_to_facing_suffix(face_direction)

	var body_animation_name = StringName("%s_%s" % [animation_prefix, direction_suffix])
	
	if not body_sprite.sprite_frames.has_animation(body_animation_name):
		push_warning("missing player body animation: %s" % body_animation_name)
		return
	
	if body_sprite.animation != body_animation_name:
		body_sprite.play(body_animation_name)

func _update_armed_effect() -> void:
	var isArmedEffectVisible := _get_is_armed()

	if armed_effect_sprite.visible != isArmedEffectVisible:
		armed_effect_sprite.visible = isArmedEffectVisible
		if isArmedEffectVisible:
			armed_effect_sprite.play(&"default")
		else:
			armed_effect_sprite.stop()

func _fire_bullets() -> void:
	if !fire_timer.is_stopped():
		return

	var has_fire_bullets := false
	match fire_mode:
		FireMode.STRAIGHT:
			has_fire_bullets = _fire_straight(fire_direction)
		FireMode.SPIRAL:
			has_fire_bullets = _fire_spiral()

	if has_fire_bullets:
		fire_timer.start(_get_fire_interval())

func _fire_straight(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	return _spawn_bullet(direction)

const SPIRAL_SETP := PI / 12.0
func _fire_spiral() -> bool:
	var direction = next_bullet_direction
	next_bullet_direction = direction.rotated(SPIRAL_SETP)

	var bullet1 := _spawn_bullet(direction)
	var bullet2 := _spawn_bullet(direction.rotated(PI))

	return bullet1 || bullet2

func _spawn_bullet(direction: Vector2) -> bool:
	var bullet = BULLET.instantiate() as Bullet
	if bullet == null:
		return false

	bullet.setup(direction)
	bullet.global_position = global_position + direction * gun_length

	var scene = get_tree().current_scene
	if scene == null:
		return false
	scene.add_child(bullet)

	return true

func _get_is_armed() -> bool:
	return player_mode == PlayerMode.ARMED || fire_mode == FireMode.SPIRAL

func _get_fire_interval() -> float:
	return maxf(fire_interval / _get_fire_speed(), 0.01)

func _get_fire_speed() -> float:
	var speed = DEFAULT_FIRE_SPEED
	if fire_mode == FireMode.SPIRAL:
		speed *= sprial_fire_speed
	return speed

func _vector_to_facing_suffix(direction: Vector2) -> StringName:
	if abs(direction.x) >= abs(direction.y):
		return &"right" if direction.x >= 0 else &"left"

	return &"up" if direction.y < 0 else &"down"
