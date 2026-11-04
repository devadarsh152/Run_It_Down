extends Control

func _ready():
    hide()
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _input(event):
    if visible and event.is_action_pressed("Pause"):
        resume_game()
        get_viewport().set_input_as_handled()

func resume_game():
    hide()
    get_tree().paused = false

func _on_resume_button_pressed():
    resume_game()

func _on_main_menu_button_pressed():
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
