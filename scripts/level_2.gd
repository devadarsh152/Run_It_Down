extends Node2D

@onready var pause_menu: Control = $PauseMenu / PauseMenu
@onready var winscreen: Control = $CanvasLayer / winscreen


const LEVEL_MUSIC = preload("res://Assets/MainGameMusic.mp3")

var has_won = false

func _ready():
    Music.play_music(LEVEL_MUSIC)
    winscreen.hide()

func _process(_delta):
    if has_won:
        return




func _on_house_body_entered(body: Node2D) -> void:
    var enemies = get_tree().get_nodes_in_group("enemy")
    if body.is_in_group("player") and enemies.size()==0:
        winscreen.show()
        
