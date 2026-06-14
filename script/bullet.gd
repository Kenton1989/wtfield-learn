extends Area2D
class_name Bullet

const WORLD_COLLISION_MASK := 1

@export var speed: float = 320
@export var max_lifetime: float = 2.0
@export var damage: float = 1

var direction: Vector2 = Vector2.RIGHT
var remaining_lifetime: float = 0.0

func setup(init_direction: Vector2) -> void:
	if (init_direction != Vector2.ZERO):
		direction = init_direction.normalized()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if _inside_world_body():
		queue_free()
		return

	remaining_lifetime = max_lifetime
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _inside_world_body():
		queue_free()
		return

	var current_position := global_position
	var next_position := current_position + direction * speed * delta

	if _will_hit_world(current_position, next_position):
		queue_free()
		return
	
	remaining_lifetime -= delta
	if remaining_lifetime <= 0:
		queue_free()
		return
	
	global_position = next_position

func _on_area_entered(area: Area2D):
	if area is Bullet:
		return

	queue_free()

func _will_hit_world(from_pos: Vector2, to_pos: Vector2):
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return false

	var query := PhysicsRayQueryParameters2D.create(
		from_pos,
		to_pos,
		WORLD_COLLISION_MASK
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var collision = space_state.intersect_ray(query)
	return not collision.is_empty()

func _inside_world_body():
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return false

	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = WORLD_COLLISION_MASK
	query.position = position
	
	var collision = space_state.intersect_point(query)
	return not collision.is_empty()
