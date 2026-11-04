extends CharacterBody2D

const SPEED = 80.0
const MAX_HEALTH = 25
const ATTACK_DAMAGE = 5
const ATTACK_COOLDOWN = 0.8
const ATTACK_FRAME = 5
const STOP_DISTANCE = 12.0
const HURT_TIME = 0.15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var detection_range: Area2D = $DetectionRange
@onready var attack_range: Area2D = $AttackRange

var player = null
var health = MAX_HEALTH

var is_dead = false
var is_attacking = false
var can_attack = true
var damage_done = false
var is_hurt = false

func _ready():
    add_to_group("enemy")
    hurtbox.add_to_group("enemy_hurtbox")

    if not detection_range.body_entered.is_connected(_on_detection_range_body_entered):
        detection_range.body_entered.connect(_on_detection_range_body_entered)
    if not detection_range.body_exited.is_connected(_on_detection_range_body_exited):
        detection_range.body_exited.connect(_on_detection_range_body_exited)
    if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
        hurtbox.area_entered.connect(_on_hurtbox_area_entered)
    if not animated_sprite.frame_changed.is_connected(_on_animated_sprite_2d_frame_changed):
        animated_sprite.frame_changed.connect(_on_animated_sprite_2d_frame_changed)
    if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
        animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

    animated_sprite.play("idle")

func _physics_process(delta):
    if is_dead:
        return

    if is_hurt:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    if player == null or not is_instance_valid(player):
        player = null
        velocity = Vector2.ZERO
        if not is_attacking and animated_sprite.animation != "idle":
            animated_sprite.play("idle")
        move_and_slide()
        return

    var to_player = player.global_position - global_position
    var distance = to_player.length()

    if distance > 0.001:
        var direction = to_player.normalized()

        if direction.x > 0.05:
            animated_sprite.flip_h = false
        elif direction.x < -0.05:
            animated_sprite.flip_h = true

        if _player_in_attack_range():
            velocity = Vector2.ZERO

            if can_attack and not is_attacking:
                start_attack()
            elif not is_attacking and animated_sprite.animation != "idle":
                animated_sprite.play("idle")
        else:
            if not is_attacking:
                if distance > STOP_DISTANCE:
                    velocity = direction * SPEED
                    if animated_sprite.animation != "movement":
                        animated_sprite.play("movement")
                else:
                    velocity = Vector2.ZERO
                    if animated_sprite.animation != "idle":
                        animated_sprite.play("idle")
    else:
        velocity = Vector2.ZERO
        if not is_attacking and animated_sprite.animation != "idle":
            animated_sprite.play("idle")

    move_and_slide()

func _player_in_attack_range() -> bool:
    if player == null or not is_instance_valid(player):
        return false

    for body in attack_range.get_overlapping_bodies():
        if body == player:
            return true
    return false

func start_attack():
    if is_dead or is_hurt or is_attacking or not can_attack:
        return

    is_attacking = true
    can_attack = false
    damage_done = false
    velocity = Vector2.ZERO
    animated_sprite.stop()
    animated_sprite.play("attack")

func take_damage(amount: int):
    if is_dead:
        return

    health -= amount
    print("Enemy health:", health)

    if health <= 0:
        die()
    else:
        hurt()

func hurt():
    if is_dead:
        return

    is_hurt = true
    is_attacking = false
    can_attack = false
    damage_done = false
    velocity = Vector2.ZERO

    animated_sprite.stop()
    if animated_sprite.sprite_frames.has_animation("take hit"):
        animated_sprite.play("take hit")

    await get_tree().create_timer(HURT_TIME).timeout

    if not is_dead:
        is_hurt = false
        can_attack = true

func die():
    if is_dead:
        return

    is_dead = true
    is_hurt = false
    is_attacking = false
    can_attack = false
    player = null
    damage_done = false
    velocity = Vector2.ZERO

    detection_range.monitoring = false
    attack_range.monitoring = false
    hurtbox.monitoring = false
    hurtbox.monitorable = false

    animated_sprite.stop()
    animated_sprite.play("death")
    await animated_sprite.animation_finished
    queue_free()

func _on_detection_range_body_entered(body):
    if is_dead:
        return

    if body.is_in_group("player"):
        player = body

func _on_detection_range_body_exited(body):
    if body == player:
        player = null

func _on_hurtbox_area_entered(area: Area2D):
    if is_dead:
        return

    if area.is_in_group("player_attack"):
        take_damage(25)

func _on_animated_sprite_2d_frame_changed():
    if is_dead:
        return

    if is_attacking and animated_sprite.animation == "attack":
        if animated_sprite.frame == ATTACK_FRAME and not damage_done:
            for body in attack_range.get_overlapping_bodies():
                if body.is_in_group("player") and body.has_method("take_damage"):
                    body.take_damage(ATTACK_DAMAGE)
            damage_done = true

func _on_animated_sprite_2d_animation_finished():
    if is_dead:
        return

    if animated_sprite.animation == "attack":
        is_attacking = false
        await get_tree().create_timer(ATTACK_COOLDOWN).timeout
        if not is_dead and not is_hurt:
            can_attack = true
