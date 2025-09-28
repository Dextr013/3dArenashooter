[gdscript]
extends Node

signal update_wave(wave_number: int)

@export var enemy_scene: PackedScene
@export var time_between_waves: float = 10.0
@export var spawn_interval: float = 1.5
@export var initial_wave_size: int = 4
@export var wave_multiplier: float = 1.4

var main_scene: Node
var player: Node3D
var arena: Node3D
var current_wave: int = 0
var enemies_remaining: int = 0
var spawn_points: Array[Node3D] = []

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
    main_scene = get_tree().current_scene
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    if player:
        _initialize_spawn_points()
        _start_next_wave()

func set_player(node: Node3D) -> void:
    player = node
    if player and spawn_points.is_empty():
        _initialize_spawn_points()
        _start_next_wave()

func _initialize_spawn_points() -> void:
    arena = main_scene.get_node("Environment")
    spawn_points = arena.get_node("SpawnPoints").get_children()

func _start_next_wave() -> void:
    current_wave += 1
    enemies_remaining = int(round(initial_wave_size * pow(wave_multiplier, current_wave - 1)))
    spawn_timer.wait_time = spawn_interval
    spawn_timer.start()
    _emit_wave_event()

func _on_spawn_timer_timeout() -> void:
    if enemies_remaining <= 0:
        spawn_timer.stop()
        await get_tree().create_timer(time_between_waves).timeout
        _start_next_wave()
        return

    _spawn_enemy()
    enemies_remaining -= 1

func _spawn_enemy() -> void:
    if spawn_points.is_empty() or not enemy_scene:
        return

    var spawn_point: Node3D = spawn_points.pick_random()
    var enemy = enemy_scene.instantiate()
    enemy.global_transform.origin = spawn_point.global_transform.origin
    enemy.set_target(player)
    enemy.tree_exited.connect(_on_enemy_killed)
    main_scene.add_child(enemy)

func _on_enemy_killed() -> void:
    var living = _get_living_enemies()
    if living == 0 and enemies_remaining <= 0:
        spawn_timer.stop()
        await get_tree().create_timer(time_between_waves).timeout
        _start_next_wave()

func _get_living_enemies() -> int:
    var count := 0
    for child in main_scene.get_children():
        if child is CharacterBody3D and child.has_method("apply_damage"):
            if not child.is_queued_for_deletion():
                count += 1
    return count

func _emit_wave_event() -> void:
    emit_signal("update_wave", current_wave)