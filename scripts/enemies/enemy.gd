[gdscript]
extends CharacterBody3D

@export var speed: float = 5.5
@export var acceleration: float = 6.0
@export var health: float = 60.0
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.2

@onready var nav_agent: NavigationAgent3D = $NavigationAgent
@onready var hit_area: Area3D = $HitArea
@onready var death_sfx: AudioStreamPlayer3D = $DeathSFX

var target: Node3D
var attack_cooldown := 0.0
var is_dead := false

func _ready() -> void:
    hit_area.body_entered.connect(_on_hit_body_entered)
    hit_area.body_exited.connect(_on_hit_body_exited)
    nav_agent.max_speed = speed

func set_target(node: Node3D) -> void:
    target = node
    if target:
        nav_agent.target_position = target.global_transform.origin

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    if target:
        nav_agent.target_position = target.global_transform.origin

    var next_path := nav_agent.get_next_path_position()
    var direction := (next_path - global_transform.origin)
    direction.y = 0
    if direction.length() > 0.01:
        direction = direction.normalized()
        velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
        velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
        look_at(next_path, Vector3.UP)
    else:
        velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
        velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

    velocity.y = 0
    move_and_slide()

    if attack_cooldown > 0.0:
        attack_cooldown -= delta

func apply_damage(amount: float) -> void:
    if is_dead:
        return
    health -= amount
    if health <= 0.0:
        _die()

func _die() -> void:
    is_dead = true
    death_sfx.play()
    call_deferred("queue_free")

func _on_hit_body_entered(body: Node) -> void:
    if body.has_method("trigger_damage"):
        _attack_target(body)

func _on_hit_body_exited(body: Node) -> void:
    pass

func _attack_target(body: Node) -> void:
    if attack_cooldown <= 0.0:
        body.trigger_damage(attack_damage)
        attack_cooldown = attack_interval