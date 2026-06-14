extends Resource
class_name EnemyConfig

const PICKUP_FIRE_BOOST = preload("uid://d2a0tfdyeodki")
const PICKUP_MOVE_BOOST = preload("uid://uvlhd1ubaykj")
const PICKUP_SPRIAL_MODE = preload("uid://p4aqr7mgqn4g")

@export_group("General")
@export var display_name: String = "enemy"

@export_group("Ability")
@export_range(1, 100, 1, "or_greater") var move_speed: float = 20
@export_range(1, 10, 1, "or_greater") var max_health: float = 3
@export_range(1, 50, 0.1, "or_greater") var collision_radius: float = 6
@export_range(1, 10, 1, "or_greater") var touch_damage: float = 1
@export_range(0.01, 5, 0.01, "or_greater") var touch_damage_interval: float = 0.5

@export var is_explosive: bool = false
@export_range(1, 100, 1, "or_greater") var explosion_radius: float = 10
@export_range(1, 10, 1, "or_greater") var explosion_damage: float = 2

@export_group("Reward")
@export_range(0, 1, 0.01, "or_greater") var reward_droprate: float = 0.2
@export var rewards: Array[PickUpConfig] = [
	PICKUP_FIRE_BOOST,
	PICKUP_MOVE_BOOST,
	PICKUP_SPRIAL_MODE
]

@export_group("Animation")
@export var enemy_sprite: SpriteFrames
@export var move_animation_name: StringName = &"move"
@export var die_animation_name: StringName = &"die"
@export var explode_animation_name: StringName = &"explode"
