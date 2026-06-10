extends CharacterBody2D

const BULLET = preload("res://scene/bullet.tscn")

const NORMAL_ANIMETION_PREFIX := &"normal"

@onready var body_sprite: AnimatedSprite2D = $BodySprite

@export var move_speed: float = 120.0
@export var fire_interval: float = 0.2
@export var gun_length: float = 5.0

var face_direction_name: StringName = &"right"
var face_direction := Vector2.RIGHT
var fire_countdown: float = 0.0;

func _ready() -> void:
	_update_animation()

func _physics_process(delta: float) -> void:
	var move_direction := Vector2.ZERO
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if move_input != Vector2.ZERO:
		face_direction_name = _vector_to_facing_suffix(move_input)
		move_direction = move_input.normalized()
		face_direction = move_direction

	_update_animation()

	if fire_countdown <= 0.0:
		fire_countdown = fire_interval

		var bullet := BULLET.instantiate()
		bullet.setup(face_direction)
		bullet.global_position = global_position + face_direction * gun_length
		add_sibling(bullet)
	else:
		fire_countdown -= delta

	velocity = move_direction * move_speed
	move_and_slide()

func _update_animation() -> void:
	var body_animation_name = StringName("%s_%s" % [NORMAL_ANIMETION_PREFIX, face_direction_name])
	
	if not body_sprite.sprite_frames.has_animation(body_animation_name):
		push_warning("missing player body animation: %s" % body_animation_name)
		return
	
	if body_sprite.animation != body_animation_name:
		body_sprite.play(body_animation_name)
	

func _vector_to_facing_suffix(move_input: Vector2) -> StringName:
	if abs(move_input.x) >= abs(move_input.y):
		return &"right" if move_input.x >= 0 else &"left"

	return &"up" if move_input.y < 0 else &"down"
