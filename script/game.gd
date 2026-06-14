extends Node2D

@onready var enemy_spawn_point_container: Node2D = $EnemySpawnPointContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var player: Player = $Player
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer


@export var ENEMY = preload("uid://bxrbrb8dobvpv")
@export var enemy_configs: Array[EnemyConfig] = [
	preload("uid://fbnlags1rkfr"),
	preload("uid://dqqnuj3nv8c47"),
	preload("uid://c3sfl22q5q5nv"),
	preload("uid://dxl150jyurldb"),
]

@export_group("Enemy Spawning")
@export_range(0, 10, 1, "or_greater") var init_enemy_spawn_count: int = 2
@export_range(0, 10, 1, "or_greater") var enemy_spawn_count_per_round: int = 1
@export_range(0, 10, 0.1, "or_greater") var init_enemy_spawn_interval: float = 2.0
@export_range(0, 10, 0.1, "or_greater") var final_enemy_spawn_interval: float = 0.6
@export_range(0, 200, 1, "or_greater") var enemy_spawn_accelaration_duration: float = 60
@export_range(0, 100, 1, "or_greater") var max_enemy_count: int = 16

var spawn_points: Array[Marker2D] = []
var valid_enemy_configs: Array[EnemyConfig] = []
var time_elapsed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	_cache_enemy_spawn_points()
	_cache_enemy_configs()
	_setup_enemy_spawn_timer()
	_spawn_init_enemy()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time_elapsed += delta
	_try_spawn_enemy()

func _cache_enemy_spawn_points():
	for node in enemy_spawn_point_container.get_children():
		if node is Marker2D:
			spawn_points.append(node)

func _cache_enemy_configs():
	for config in enemy_configs:
		if config is EnemyConfig:
			valid_enemy_configs.append(config)

func _is_ready_to_spawn() -> bool:
	return (
		!spawn_points.is_empty() &&
		!valid_enemy_configs.is_empty() &&
		is_instance_valid(player) &&
		_get_enemy_count() < max_enemy_count
	)

func _get_enemy_count() -> int:
	return enemy_container.get_children().filter(
		func (n): return n is Enemy
	).size()

func _setup_enemy_spawn_timer():
	enemy_spawn_timer.one_shot = true
	enemy_spawn_timer.timeout.connect(_try_spawn_enemy)
	enemy_spawn_timer.start(init_enemy_spawn_interval)

func _spawn_init_enemy():
	var spawn_count = min(
		init_enemy_spawn_count,
		max_enemy_count - _get_enemy_count()
	)

	for i in range(0, enemy_spawn_count_per_round):
		_spawn_enemy()

func _try_spawn_enemy():
	if !enemy_spawn_timer.is_stopped():
		return
	if !_is_ready_to_spawn():
		return

	var spawn_count = min(
		enemy_spawn_count_per_round,
		max_enemy_count - _get_enemy_count()
	)
	for i in range(0, enemy_spawn_count_per_round):
		_spawn_enemy()

	var latest_spawn_interval = lerpf(
		init_enemy_spawn_interval,
		final_enemy_spawn_interval,
		time_elapsed / enemy_spawn_accelaration_duration
	)
	enemy_spawn_timer.start(latest_spawn_interval)

func _spawn_enemy():
	var enemy_config: EnemyConfig = valid_enemy_configs.pick_random()
	var spawn_point: Marker2D = spawn_points.pick_random()

	var enemy = ENEMY.instantiate() as Enemy

	enemy.setup(enemy_config, player)
	enemy.global_position = spawn_point.global_position

	enemy_container.add_child(enemy)
