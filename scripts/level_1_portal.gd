extends Node2D

@onready var portal: Area2D = $portal
@onready var pause_menu: Control = $PauseMenu / PauseMenu

const LEVEL_MUSIC = preload("res://Assets/MainGameMusic.mp3")

func _ready():
    Music.play_music(LEVEL_MUSIC)


func _process(_delta):
    var enemies = get_tree().get_nodes_in_group("enemy")
    if enemies.size() == 0 and not portal.visible:
        portal.activate_portal()

func _unhandled_input(event):
    if event.is_action_pressed("Pause") and not get_tree().paused:
        get_tree().paused = true
        pause_menu.show()
        get_viewport().set_input_as_handled()
