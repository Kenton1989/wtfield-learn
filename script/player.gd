extends CharacterBody2D
class_name Player

const BULLET = preload("res://scene/bullet.tscn")

const NORMAL_ANIMETION_PREFIX := &"normal"
const ARMED_ANIMETION_PREFIX := &"armed"
const DEFAULT_FIRE_SPEED := 1.0
const DEFAULT_MOVE_SPEED := 1.0


@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var fire_timer: Timer = $FireTimer
@onready var armed_effect_sprite: AnimatedSprite2D = $ArmedEffectSprite
@onready var invincible_timer: Timer = $InvincibleTimer

@export var base_move_speed: float = 120.0
@export var base_fire_interval: float = 0.18
@export var gun_length: float = 10.0

@export var invincible_duration: float = 1


var player_mode := PickUpConfig.PlayerMode.NORMAL

var move_direction := Vector2.ZERO
var fire_direction := Vector2.ZERO
var face_direction := Vector2.RIGHT

var fire_mode:= PickUpConfig.FireMode.STRAIGHT
var next_bullet_direction := Vector2.RIGHT
var straight_fire_speed: float = DEFAULT_FIRE_SPEED
var sprial_fire_speed: float = DEFAULT_FIRE_SPEED
var fire_countdown: float = 0.0

var current_health: float = 5

var move_speed: float = DEFAULT_MOVE_SPEED

var buff_timers := {}


func _ready() -> void:
	fire_mode = PickUpConfig.FireMode.STRAIGHT

	fire_timer.one_shot = true
	fire_timer.stop()
	
	invincible_timer.wait_time = invincible_duration
	invincible_timer.timeout.connect(_on_invincible_timeout)

	_update_body_animation()
	_update_armed_effect()

func _physics_process(_delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var fire_input := Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")

	move_direction = move_input.normalized()
	fire_direction = fire_input.normalized()
	if fire_direction != Vector2.ZERO:
		face_direction = fire_direction
	elif move_direction != Vector2.ZERO:
		face_direction = move_direction

	velocity = move_direction * _get_move_speed()
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
		PickUpConfig.FireMode.STRAIGHT:
			has_fire_bullets = _fire_straight(fire_direction)
		PickUpConfig.FireMode.SPIRAL:
			has_fire_bullets = _fire_spiral()

	if has_fire_bullets:
		fire_timer.start(_get_fire_interval())

func apply_damage(amount: float) -> bool:
	if amount <= 0: return false
	if current_health <= 0: return false
	if _is_invincible(): return false

	current_health -= amount
	if current_health > 0:
		invincible_timer.start()
		GlobalShader.set_blink_enabled(body_sprite.material, true)
	else:
		queue_free()

	return true

func _is_invincible() -> bool:
	return !invincible_timer.is_stopped()

func _on_invincible_timeout():
	GlobalShader.set_blink_enabled(body_sprite.material, false)
	
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

func apply_pickup(config: PickUpConfig) -> bool:
	var old_fire_interval = _get_fire_interval()

	match config.pickup_type:
		PickUpConfig.PickUpType.FIRE_MODE:
			sprial_fire_speed = config.fire_speed_mult
			fire_mode = config.fire_mode
		PickUpConfig.PickUpType.FIRE_BOOST:
			straight_fire_speed = config.fire_speed_mult
		PickUpConfig.PickUpType.MOVE_BOOST:
			move_speed = config.move_speed_mult
		_:
			return false

	var new_fire_interval = _get_fire_interval()

	_get_buff_timer(config.pickup_type).start(config.duration)
	
	if new_fire_interval != old_fire_interval:
		_refresh_fire_timer()

	return true

func _get_buff_timer(type: PickUpConfig.PickUpType) -> Timer:
	if !buff_timers.has(type):
		buff_timers[type] = _new_buff_timer(type)
	return buff_timers[type] as Timer

func _new_buff_timer(type: PickUpConfig.PickUpType) -> Timer:
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(func(): _undo_buff(type))
	return timer

func _undo_buff(type: PickUpConfig.PickUpType) -> void:
	match type:
		PickUpConfig.PickUpType.FIRE_MODE:
			sprial_fire_speed = DEFAULT_FIRE_SPEED
			fire_mode = PickUpConfig.FireMode.STRAIGHT
			next_bullet_direction = Vector2.RIGHT
		PickUpConfig.PickUpType.FIRE_BOOST:
			straight_fire_speed = DEFAULT_FIRE_SPEED
		PickUpConfig.PickUpType.MOVE_BOOST:
			move_speed = DEFAULT_MOVE_SPEED

func _refresh_fire_timer() -> void:
	var fire_interval = _get_fire_interval() 
	if fire_interval < fire_timer.time_left:
		fire_timer.start(fire_interval)
	else:
		fire_timer.wait_time = fire_interval

func _get_is_armed() -> bool:
	return player_mode == PickUpConfig.PlayerMode.ARMED || fire_mode == PickUpConfig.FireMode.SPIRAL

func _get_fire_interval() -> float:
	return maxf(base_fire_interval / _get_fire_speed(), 0.01)

func _get_move_speed() -> float:
	return maxf(base_move_speed * move_speed, 0.01)

func _get_fire_speed() -> float:
	match fire_mode:
		PickUpConfig.FireMode.STRAIGHT:
			return straight_fire_speed
		PickUpConfig.FireMode.SPIRAL:
			return sprial_fire_speed
	return DEFAULT_FIRE_SPEED

func _vector_to_facing_suffix(direction: Vector2) -> StringName:
	if abs(direction.x) >= abs(direction.y):
		return &"right" if direction.x >= 0 else &"left"

	return &"up" if direction.y < 0 else &"down"
