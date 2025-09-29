[gdscript]
extends CanvasLayer

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var mobile_overlay: Control = $MobileOverlay
@onready var fire_button: Button = $MobileOverlay/FireButton
@onready var jump_button: Button = $MobileOverlay/JumpButton
@onready var reload_button: Button = $MobileOverlay/ReloadButton
@onready var joystick: TextureRect = $MobileOverlay/Joystick
@onready var game_over: ColorRect = $GameOver

var joystick_touch_index := -1
var joystick_start_pos := Vector2.ZERO
var joystick_radius := 120.0
var player_ref: Node

func _ready() -> void:
    fire_button.pressed.connect(_on_fire_button_pressed)
    fire_button.released.connect(_on_fire_button_released)
    jump_button.pressed.connect(_on_jump_button_pressed)
    reload_button.pressed.connect(_on_reload_button_pressed)

    var main = get_tree().current_scene
    player_ref = main.get_node("Player")
    if player_ref:
        player_ref.connect("health_changed", Callable(self, "update_health"))
        player_ref.connect("died", Callable(self, "on_player_died"))

    _configure_platform_ui()

func _configure_platform_ui() -> void:
    mobile_overlay.visible = OS.has_feature("mobile")

func update_health(current: float, max_health: float) -> void:
    health_bar.max_value = max_health
    health_bar.value = max(current, 0)

func update_wave(wave: int) -> void:
    wave_label.text = "Wave: %d" % wave

func on_player_health_changed(current: float, max_health: float) -> void:
    update_health(current, max_health)

func on_player_died() -> void:
    show_game_over()

func show_game_over() -> void:
    game_over.visible = true

func _on_fire_button_pressed() -> void:
    if player_ref:
        player_ref.mobile_fire(true)

func _on_fire_button_released() -> void:
    if player_ref:
        player_ref.mobile_fire(false)

func _on_jump_button_pressed() -> void:
    if player_ref:
        player_ref.mobile_jump()

func _on_reload_button_pressed() -> void:
    if player_ref:
        player_ref.mobile_reload()

func _unhandled_input(event: InputEvent) -> void:
    if not mobile_overlay.visible:
        return

    if event is InputEventScreenTouch:
        if event.pressed and joystick_touch_index == -1 and event.position.x < get_viewport_rect().size.x * 0.5:
            joystick_touch_index = event.index
            joystick_start_pos = event.position
        elif not event.pressed and event.index == joystick_touch_index:
            joystick_touch_index = -1
            joystick.texture = joystick.texture
            if player_ref:
                player_ref.set_mobile_move(Vector2.ZERO)

    elif event is InputEventScreenDrag and event.index == joystick_touch_index:
        var delta := event.position - joystick_start_pos
        if delta.length() > joystick_radius:
            delta = delta.normalized() * joystick_radius
        var normalized := delta / joystick_radius
        if player_ref:
            player_ref.set_mobile_move(Vector2(normalized.x, -normalized.y))