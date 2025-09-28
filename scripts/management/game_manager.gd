[gdscript]
extends Node3D

@onready var player: Node3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var wave_manager: Node = $WaveManager

func _ready() -> void:
    if wave_manager.has_method("set_player"):
        wave_manager.set_player(player)
    if wave_manager.has_signal("update_wave"):
        wave_manager.connect("update_wave", Callable(hud, "update_wave"))
    player.connect("health_changed", Callable(hud, "on_player_health_changed"))
    player.connect("died", Callable(hud, "on_player_died"))

func player_died() -> void:
    hud.call("show_game_over")