[gdscript]
extends Area3D

@export var speed: float = 60.0
@export var life_time: float = 4.0
@export var damage: float = 20.0

var velocity := Vector3.ZERO

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    await get_tree().create_timer(life_time).timeout
    queue_free()

func launch(direction: Vector3) -> void:
    velocity = direction

func _physics_process(delta: float) -> void:
    translate(velocity * delta)

func _on_body_entered(body: Node) -> void:
    if body.has_method("apply_damage"):
        body.apply_damage(damage)
    elif body.has_method("trigger_damage"):
        body.trigger_damage(damage)
    queue_free()