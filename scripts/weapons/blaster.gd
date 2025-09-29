[gdscript]
extends Node3D

@export var projectile_scene: PackedScene = preload("res://scenes/weapons/Projectile.tscn")
@export var muzzle_flash_scene: PackedScene = preload("res://scenes/weapons/MuzzleFlash.tscn")
@export var damage: float = 20.0
@export var fire_force: float = 40.0

@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_sfx: AudioStreamPlayer3D = $ShootSFX
@onready var reload_sfx: AudioStreamPlayer3D = $ReloadSFX
@onready var explosion_sfx: AudioStreamPlayer3D = $ExplosionSFX

var ammo: int = 30
var max_ammo: int = 30
var reload_time: float = 1.2
var reloading := false

func fire() -> void:
    if reloading or ammo <= 0:
        return

    ammo -= 1
    _spawn_projectile()
    _play_shoot_effects()

    if ammo <= 0:
        reload()

func reload() -> void:
    if reloading or ammo == max_ammo:
        return

    reloading = true
    reload_sfx.play()
    await get_tree().create_timer(reload_time).timeout
    ammo = max_ammo
    reloading = false

func _spawn_projectile() -> void:
    if not projectile_scene:
        return

    var projectile = projectile_scene.instantiate()
    projectile.global_transform = muzzle.global_transform
    projectile.damage = damage
    get_tree().current_scene.add_child(projectile)
    projectile.launch(muzzle.global_transform.basis.z * -fire_force)

func _play_shoot_effects() -> void:
    if muzzle_flash_scene:
        var flash = muzzle_flash_scene.instantiate()
        flash.global_transform = muzzle.global_transform
        get_tree().current_scene.add_child(flash)
    shoot_sfx.pitch_scale = randf_range(0.95, 1.05)
    shoot_sfx.play()