[gdscript]
extends Node3D

@export var default_weapon: PackedScene
@export var fire_rate: float = 0.1

var active_weapon: Node3D
var socket: Node3D
var fire_pressed := false
var fire_timer := 0.0

func _ready() -> void:
    socket = get_node("Socket")
    if not default_weapon:
        default_weapon = preload("res://scenes/weapons/Blaster.tscn")
    _spawn_weapon(default_weapon)

func _process(delta: float) -> void:
    if not active_weapon:
        return

    if fire_pressed:
        fire_timer -= delta
        if fire_timer <= 0.0:
            fire_timer = fire_rate
            active_weapon.call("fire")

func trigger_fire(pressed: bool) -> void:
    fire_pressed = pressed
    if not pressed:
        fire_timer = 0.0

func trigger_reload() -> void:
    if active_weapon:
        active_weapon.call("reload")

func _spawn_weapon(scene: PackedScene) -> void:
    if active_weapon:
        active_weapon.queue_free()
    active_weapon = scene.instantiate()
    socket.add_child(active_weapon)