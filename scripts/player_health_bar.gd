extends CanvasLayer

@onready var health_bar: TextureProgressBar = $Control / HealthBar


func _ready():
    if health_bar == null:
        print("UI ERROR: HealthBar node not found")

func set_health(current_health, max_health):
    if health_bar == null:
        return

    health_bar.max_value = max_health
    health_bar.value = current_health
