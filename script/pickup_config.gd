extends Resource
class_name PickUpConfig

enum PickUpType {
	NONE,
	MOVE_BOOST,
	FIRE_BOOST,
	FIRE_MODE,
}

enum PlayerMode {
	NONE,
	NORMAL,
	ARMED,
}

enum FireMode {
	NONE,
	STRAIGHT,
	SPIRAL,
}

@export_group("General")
@export var pickup_type := PickUpType.NONE
@export var display_name := "pickup item"
@export_range(0, 1000, 0.1, "or_greater") var drop_weight: float = 1.0

@export_group("Buff")
@export_range(0, 120, 1, "or_greater") var duration: float = 10
@export_range(0.1, 5, 0.1, "or_greater") var fire_speed_mult: float = 1
@export_range(0.1, 5, 0.1, "or_greater") var move_speed_mult: float = 1

@export_group("Player")
@export var player_mode := PlayerMode.NONE
@export var fire_mode := FireMode.NONE

@export_group("Display")
@export var icon_texture: Texture2D
