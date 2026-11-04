extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const ATTACK_DAMAGE = 25
const ATTACK_COOLDOWN = 0.15
const HURT_TIME = 0.2
const INVINCIBLE_TIME = 0.35
const MAX_HEALTH = 100

@onready var deathscreen: Control = $"../Deathscreen/Deathscreen"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $AttackRange
@onready var ui = get_parent().get_node_or_null("UI")

var health = MAX_HEALTH
var is_attacking = false
var is_hurt = false
var is_dead = false
var can_attack = true
var invincible = false

func _ready():
    add_to_group("player")
    update_attack_range_position()
    deathscreen.hide()

    if ui != null:
        ui.set_health(health, MAX_HEALTH)
    else:
        print("PLAYER ERROR: UI node not found")

func _physics_process(delta: float) -> void :
    if is_dead:
        return

    if global_position.y > 500:
        die()

    if not is_on_floor():
        velocity += get_gravity() * delta

    var direction: = Input.get_axis("left", "right")

    if direction > 0:
        animated_sprite.flip_h = false
        update_attack_range_position()
    elif direction < 0:
        animated_sprite.flip_h = true
        update_attack_range_position()

    if Input.is_action_just_pressed("attack") and can_attack and not is_attacking and not is_hurt:
        attack()

    if Input.is_action_just_pressed("jump") and is_on_floor() and not is_hurt:
        velocity.y = JUMP_VELOCITY

    if is_attacking or is_hurt:
        velocity.x = 0
        move_and_slide()
        return

    if not is_on_floor():
        if velocity.y < 0:
            animated_sprite.play("jump up")
        else:
            animated_sprite.play("jump down")
    else:
        if direction == 0:
            animated_sprite.play("idle")
        else:
            animated_sprite.play("movement")

    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    move_and_slide()

func attack() -> void :
    if is_dead or is_hurt or is_attacking or not can_attack:
        return

    can_attack = false
    is_attacking = true
    velocity.x = 0

    animated_sprite.stop()
    animated_sprite.play("attack")

    var hit_done = false

    while animated_sprite.is_playing():
        if animated_sprite.animation == "attack" and animated_sprite.frame >= 2 and not hit_done:
            hit_done = true

            for area in attack_range.get_overlapping_areas():
                if area.name == "HurtBox":
                    var enemy = area.get_parent()
                    if enemy != null and enemy.is_in_group("enemy") and enemy.has_method("take_damage"):
                        enemy.take_damage(ATTACK_DAMAGE)

        await get_tree().process_frame

    is_attacking = false

    await get_tree().create_timer(ATTACK_COOLDOWN).timeout
    if not is_dead:
        can_attack = true

func update_attack_range_position() -> void :
    var offset = 30.0
    if animated_sprite.flip_h:
        attack_range.position.x = - abs(offset)
    else:
        attack_range.position.x = abs(offset)

func take_damage(amount: int) -> void :
    if is_dead or invincible:
        return

    health -= amount
    health = clamp(health, 0, MAX_HEALTH)

    if ui != null:
        ui.set_health(health, MAX_HEALTH)

    print("Player health:", health)

    if health <= 0:
        die()
    else:
        hurt()

func heal(amount: int) -> void :
    if is_dead:
        return

    health += amount
    health = clamp(health, 0, MAX_HEALTH)

    if ui != null:
        ui.set_health(health, MAX_HEALTH)

    print("Player healed:", amount, "Current health:", health)

func hurt() -> void :
    if is_dead:
        return

    invincible = true
    is_hurt = true
    is_attacking = false
    can_attack = true
    velocity.x = 0

    animated_sprite.stop()
    animated_sprite.play("take hit")

    await get_tree().create_timer(HURT_TIME).timeout

    if not is_dead:
        is_hurt = false

    await get_tree().create_timer(INVINCIBLE_TIME).timeout

    if not is_dead:
        invincible = false

func die() -> void :
    is_dead = true
    is_hurt = false
    is_attacking = false
    can_attack = false
    invincible = true
    velocity = Vector2.ZERO

    animated_sprite.stop()
    deathscreen.show()
    animated_sprite.play("death")

    await animated_sprite.animation_finished
    await get_tree().create_timer(1.0).timeout

    get_tree().reload_current_scene()
