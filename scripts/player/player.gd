[gdscript]
extends CharacterBody3D

signal health_changed(current: float, max: float)
signal died

@export var mouse_sensitivity: float = 0.15
@export var speed: float = 8.0
@export var acceleration: float = 10.0
@export var air_control: float = 3.0
@export var jump_velocity: float = 6.5
@export var dash_force: float = 14.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var max_health: float = 100.0

@onready var camera_root: Node3D = $CameraRoot
@onready var weapon_manager: Node3D = $WeaponManager
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@onready var animation_tree: AnimationTree = $Body/Pivot/AnimationTree
@onready var animation_state = animation_tree["parameters/playback"]

var look_rotation := Vector2.ZERO
var vertical_velocity := 0.0
var dash_cooldown := 0.0
var health: float
var mobile_move_input := Vector2.ZERO

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    animation_tree.active = true
    animation_state.travel("Idle")
    health = max_health
    emit_signal("health_changed", health, max_health)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("fire"):
        weapon_manager.call("trigger_fire", true)
    elif event.is_action_released("fire"):
        weapon_manager.call("trigger_fire", false)
    elif event.is_action_pressed("reload"):
        weapon_manager.call("trigger_reload")

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _apply_look(event.relative)
    elif event is InputEventScreenDrag:
        _apply_look(event.relative * 0.5)

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("pause"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

    dash_cooldown = max(dash_cooldown - delta, 0.0)

func _physics_process(delta: float) -> void:
    var direction := Vector3.ZERO
    var forward := -transform.basis.z
    var right := transform.basis.x

    if Input.is_action_pressed("move_forward"):
        direction += forward
    if Input.is_action_pressed("move_backward"):
        direction -= forward
    if Input.is_action_pressed("move_left"):
        direction -= right
    if Input.is_action_pressed("move_right"):
        direction += right

    if mobile_move_input.length() > 0.05:
        direction += (forward * mobile_move_input.y) + (right * mobile_move_input.x)

    direction = direction.normalized()

    if not is_on_floor():
        vertical_velocity -= gravity * delta
    else:
        vertical_velocity = 0.0

    if Input.is_action_just_pressed("jump") and is_on_floor():
        vertical_velocity = jump_velocity
        animation_state.travel("Jump")

    if Input.is_action_just_pressed("dash") and dash_cooldown == 0.0:
        var dash_dir := direction if direction != Vector3.ZERO else forward
        velocity += dash_dir.normalized() * dash_force
        dash_cooldown = 1.0

    var target_velocity := direction * speed
    var lerp_rate := acceleration if is_on_floor() else air_control
    velocity.x = lerp(velocity.x, target_velocity.x, lerp_rate * delta)
    velocity.z = lerp(velocity.z, target_velocity.z, lerp_rate * delta)
    velocity.y = vertical_velocity

    move_and_slide()

    if is_on_floor():
        if direction.length() > 0.1:
            animation_state.travel("Run")
            _play_footstep()
        else:
            animation_state.travel("Idle")

func _apply_look(relative: Vector2) -> void:
    look_rotation.x = clamp(look_rotation.x - relative.y * mouse_sensitivity * 0.01, deg_to_rad(-85), deg_to_rad(85))
    look_rotation.y -= relative.x * mouse_sensitivity * 0.01
    camera_root.rotation.x = look_rotation.x
    rotation.y = look_rotation.y

func _play_footstep() -> void:
    if not footstep_player.playing:
        footstep_player.pitch_scale = randf_range(0.95, 1.05)
        footstep_player.play()

func trigger_damage(amount: float) -> void:
    health -= amount
    emit_signal("health_changed", health, max_health)
    if health <= 0.0:
        emit_signal("died")
        if get_parent().has_method("player_died"):
            get_parent().player_died()

func heal(amount: float) -> void:
    health = clamp(health + amount, 0.0, max_health)
    emit_signal("health_changed", health, max_health)

func set_mobile_move(direction: Vector2) -> void:
    mobile_move_input = direction

func mobile_fire(pressed: bool) -> void:
    weapon_manager.call("trigger_fire", pressed)

func mobile_jump() -> void:
    if is_on_floor():
        vertical_velocity = jump_velocity

func mobile_reload() -> void:
    weapon_manager.call("trigger_reload")