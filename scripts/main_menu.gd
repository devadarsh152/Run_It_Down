extends Control

@export_file("*.tscn") var first_level_path: String




func _ready():
    const MENU_MUSIC = preload("res://Assets/MainMenuMusic.mp3")
    Music.play_music(MENU_MUSIC)
    $CenterContainer / VBoxContainer / StartButton.pressed.connect(_on_start_pressed)
    $CenterContainer / VBoxContainer / QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
    get_tree().change_scene_to_file(first_level_path)

func _on_quit_pressed():
    get_tree().quit()
