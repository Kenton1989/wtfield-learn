extends CharacterBody2D
class_name Enemy

enum EnemyStatus {
	NORMAL,
	DIE,
	EXPLODE
}

@export var config: EnemyConfig
@export var hurt_blink_duration: float = 0.2
@export var max_explode_attack_count: int = 16

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var body_collision_shape: CollisionShape2D = $BodyCollisionShape
@onready var touch_damage_area: Area2D = $TouchDamageArea
@onready var damage_collision_shape: CollisionShape2D = $TouchDamageArea/DamageCollisionShape
@onready var attack_cooldown_timer: Timer = $TouchDamageArea/AttackCooldownTimer
@onready var damaged_effect_timer: Timer = $TouchDamageArea/DamagedEffectTimer
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision_shape: CollisionShape2D = $ExplosionArea/ExplosionCollisionShape


var current_health: float = 1
var current_status: EnemyStatus = EnemyStatus.NORMAL
var player_to_attack: Player = null
@export var player_to_seek: Player = null

func setup(config: EnemyConfig, player_to_seek: Player):
	self.config = config
	self.player_to_seek = player_to_seek
	_apply_config()

func _ready():
	touch_damage_area.body_entered.connect(_on_body_entered)
	touch_damage_area.body_exited.connect(_on_body_exited)
	touch_damage_area.area_entered.connect(_on_area_entered)
	body_sprite.animation_finished.connect(_on_body_animation_finished)
	damaged_effect_timer.timeout.connect(_on_damaged_effect_timeout)
	attack_cooldown_timer.timeout.connect(_try_attack_player)
	_apply_config()

func _physics_process(_delta: float) -> void:
	if current_status != EnemyStatus.NORMAL:		
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_to_seek == null && !is_instance_valid(player_to_seek):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var move_direction := global_position.direction_to(player_to_seek.global_position)
	velocity = move_direction * config.move_speed
	_update_animation_direction(move_direction)
	move_and_slide()
	

func _apply_config():
	if config == null:
		return

	body_sprite.sprite_frames = config.enemy_sprite
	_safe_play(body_sprite, config.move_animation_name)
	_setup_body_radius(config.collision_radius)
	_setup_explosion(config)

	current_health = config.max_health

	attack_cooldown_timer.wait_time = config.touch_damage_interval
	damaged_effect_timer.wait_time = hurt_blink_duration

func _safe_play(sprite: AnimatedSprite2D, animationName: StringName) -> bool:
	if sprite.sprite_frames == null:
		push_warning("missing sprite_frames")
		return false

	if !sprite.sprite_frames.has_animation(animationName):
		push_warning("missing sprite name: %s" % animationName)
		return false

	sprite.play(animationName)
	return true

func _update_animation_direction(direction: Vector2) -> void:
	if is_zero_approx(direction.y):
		return

	body_sprite.flip_h = direction.x < 0

func _setup_body_radius(radius: float):
	var body_shape = body_collision_shape.shape as CircleShape2D
	if body_shape != null:
		body_shape.radius = radius

	var damage_shape = damage_collision_shape.shape as CircleShape2D
	if damage_shape != null:
		damage_shape.radius = radius

func _setup_explosion(config: EnemyConfig):
	if !config.is_explosive:
		explosion_area.monitoring = false
		explosion_area.monitorable = false
		explosion_collision_shape.disabled = true
		return

	var explosion_shape = explosion_collision_shape.shape as CircleShape2D
	if explosion_shape != null:
		explosion_shape.radius = config.explosion_radius

func _on_body_entered(body: Node2D):
	var player = body as Player
	if player == null: return

	player_to_attack = player
	_try_attack_player()

func _on_body_exited(body: Node2D):
	player_to_attack = null

func _try_attack_player() -> bool:
	if !attack_cooldown_timer.is_stopped():
		return false
	
	var result = _attack_player(player_to_attack, config.touch_damage)
	if result:
		attack_cooldown_timer.start()

	return result

func _attack_player(player: Player, damage: float) -> bool:
	if player == null:
		return false
	if not is_instance_valid(player):
		return false
	return player.apply_damage(damage)

func _attack_enemy(enemy: Enemy, damage: float) -> bool:
	if enemy == null:
		return false
	if not is_instance_valid(enemy):
		return false
	return enemy.apply_damage(damage)

func _on_area_entered(area: Area2D):
	var bullet := area as Bullet
	if bullet == null:
		return

	if apply_damage(bullet.damage):
		bullet.queue_free()

func _on_body_animation_finished():
	if current_status == EnemyStatus.DIE:
		if config.is_explosive:
			_explode()
		else:
			queue_free()
		return

	if current_status == EnemyStatus.EXPLODE:
		queue_free()
		return

func _on_damaged_effect_timeout():
	GlobalShader.set_blink_enabled(body_sprite.material, false)

func apply_damage(amount: float) -> bool:
	if current_status != EnemyStatus.NORMAL:
		return false
	if amount <= 0:
		return false
	if current_health <= 0:
		return false

	current_health -= amount
	if current_health <= 0:
		_die()
	else:
		if damaged_effect_timer.is_stopped():
			GlobalShader.set_blink_enabled(body_sprite.material, true)
		damaged_effect_timer.start()
	return true

func _die():
	current_status = EnemyStatus.DIE

	_safe_play(body_sprite, config.die_animation_name)
	GlobalShader.set_blink_enabled(body_sprite.material, false)

	body_collision_shape.set_deferred(&"disabled", true)
	touch_damage_area.set_deferred(&"monitoring", false)
	touch_damage_area.set_deferred(&"monitorable", false)
	damage_collision_shape.set_deferred(&"disabled", true)
	attack_cooldown_timer.stop()
	damaged_effect_timer.stop()


func _explode():
	current_status = EnemyStatus.EXPLODE

	_apply_explode_damage()
	_safe_play(body_sprite, config.explode_animation_name)

func _apply_explode_damage():
	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return

	var query := PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.shape = explosion_collision_shape.shape
	query.transform = explosion_collision_shape.global_transform
	query.collision_mask = explosion_area.collision_mask
	query.exclude = [get_rid()]
	var collision := space_state.intersect_shape(query, max_explode_attack_count)

	push_warning("get %d collision" % collision.size())
	var colliders := collision.map(func(c): return c["collider"]) as Array
	colliders.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
	var unique_colliders = colliders.reduce(func(acc: Array, value: Object):
		if value != null && (acc.size() == 0 || acc[-1].get_instance_id() != value.get_instance_id()):
			acc.append(value)
		return acc
	, [])

	for collider in unique_colliders:
		if collider == self:
			continue

		var player = collider as Player
		if player != null:
			_attack_player(player, config.explosion_damage)
			continue

		var enemy = collider as Enemy
		if enemy != null:
			push_warning("get attacked enemy %s" % enemy.config.display_name)
			_attack_enemy(enemy, config.explosion_damage)
			continue
		
	
