extends Area2D

@export_file("*.tscn") var next_level: String
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var used: = false

func _ready():
    visible = false
    monitoring = false
    body_entered.connect(_on_body_entered)
    animated_sprite.play("idle")

func activate_portal():
    visible = true
    monitoring = true

func _on_body_entered(body):
    print("Something entered portal: ", body.name)

    if used:
        return

    if body.is_in_group("player"):
        used = true
        set_deferred("monitoring", false)

        if collision_shape:
            collision_shape.set_deferred("disabled", true)

        print("Loading level: ", next_level)
        call_deferred("_load_next_level")

func _load_next_level():
    get_tree().change_scene_to_file(next_level)
