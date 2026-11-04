extends CharacterBody2D

const SPEED = 90.0
const ATTACK_DAMAGE = 20
const ATTACK_COOLDOWN = 0.4

const MAX_HEALTH = 125

const SHIELD_DURATION = 1.0
const SHIELD_COOLDOWN = 2.5
const SHIELD_CHANCE = 0.4
const ATTACK_HIT_FRAME = 6
const HURT_TIME = 0.2
const ATTACK_OFFSET = 30.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var attack_range: Area2D = $AttackRange
@onready var detection_range: Area2D = $DetectionRange

var player = null
var health = MAX_HEALTH

var can_attack = true
var is_attacking = false
var is_hurt = false
var is_dead = false
var is_shielding = false
var can_shield = true

func _ready():
    add_to_group("enemy")
    update_attack_range_position()

    detection_range.body_entered.connect(_on_detection_range_body_entered)
    detection_range.body_exited.connect(_on_detection_range_body_exited)

    hurtbox.add_to_group("enemy_hurtbox")
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void :
    if is_dead:
        return

    if not is_on_floor():
        velocity += get_gravity() * delta

    if is_hurt:
        velocity.x = 0
        move_and_slide()
        return

    if is_shielding:
        velocity.x = 0
        if animated_sprite.animation != "shield":
            animated_sprite.play("shield")
        move_and_slide()
        return

    if player == null or not is_instance_valid(player):
        player = null
        velocity.x = 0
        if not is_attacking and animated_sprite.animation != "idle":
            animated_sprite.play("idle")
        move_and_slide()
        return

    if player.global_position.x > global_position.x:
        animated_sprite.flip_h = false
    else:
        animated_sprite.flip_h = true

    update_attack_range_position()

    if is_attacking:
        velocity.x = 0
        move_and_slide()
        return

    if can_shield and should_use_shield():
        start_shield()
        move_and_slide()
        return

    if player_in_attack_range():
        velocity.x = 0
        if can_attack:
            attack()
    else:
        var direction = sign(player.global_position.x - global_position.x)
        velocity.x = direction * SPEED
        if animated_sprite.animation != "movement":
            animated_sprite.play("movement")

    move_and_slide()

func update_attack_range_position() -> void :
    if animated_sprite.flip_h:
        attack_range.position.x = - abs(ATTACK_OFFSET)
    else:
        attack_range.position.x = abs(ATTACK_OFFSET)

func player_in_attack_range() -> bool:
    for body in attack_range.get_overlapping_bodies():
        if body.is_in_group("player"):
            return true
    return false

func should_use_shield() -> bool:
    if player == null or not is_instance_valid(player):
        return false

    var dist = global_position.distance_to(player.global_position)
    return dist <= 70 and randf() < SHIELD_CHANCE

func start_shield() -> void :
    if is_dead or is_hurt or is_attacking or is_shielding or not can_shield:
        return

    is_shielding = true
    can_shield = false
    velocity.x = 0
    animated_sprite.stop()
    animated_sprite.play("shield")

    await get_tree().create_timer(SHIELD_DURATION).timeout

    if is_dead:
        return

    is_shielding = false

    await get_tree().create_timer(SHIELD_COOLDOWN).timeout
    if not is_dead:
        can_shield = true

func attack() -> void :
    if is_dead or is_hurt or is_shielding or is_attacking or not can_attack:
        return

    can_attack = false
    is_attacking = true
    velocity.x = 0
    animated_sprite.stop()
    animated_sprite.play("attack")

    while animated_sprite.animation == "attack" and animated_sprite.frame < ATTACK_HIT_FRAME:
        await animated_sprite.frame_changed

    if is_dead:
        reset_attack_state()
        return

    if player != null and is_instance_valid(player) and player_in_attack_range() and player.has_method("take_damage"):
        player.take_damage(ATTACK_DAMAGE)

    await animated_sprite.animation_finished

    if is_dead:
        return

    is_attacking = false

    await get_tree().create_timer(ATTACK_COOLDOWN).timeout
    if not is_dead and not is_hurt and not is_shielding:
        can_attack = true
    else:
        reset_attack_state()

func take_damage(amount: int) -> void :
    if is_dead:
        return

    if is_shielding:
        print("Skeleton blocked the attack!")
        return

    health -= amount
    print("Skeleton health:", health)

    if health <= 0:
        die()
    else:
        hurt()

func hurt() -> void :
    if is_dead:
        return

    is_hurt = true
    is_attacking = false
    can_attack = false
    velocity.x = 0

    animated_sprite.stop()
    animated_sprite.play("take hit")

    await get_tree().create_timer(HURT_TIME).timeout

    if not is_dead:
        is_hurt = false
        if not is_shielding:
            can_attack = true

func die() -> void :
    if is_dead:
        return

    is_dead = true
    is_hurt = false
    is_attacking = false
    is_shielding = false
    can_attack = false
    can_shield = false
    player = null
    velocity = Vector2.ZERO

    detection_range.monitoring = false
    attack_range.monitoring = false
    hurtbox.monitoring = false
    hurtbox.monitorable = false

    animated_sprite.stop()
    animated_sprite.play("death")
    await animated_sprite.animation_finished
    queue_free()

func reset_attack_state() -> void :
    is_attacking = false
    if not is_dead and not is_hurt and not is_shielding:
        can_attack = true

func _on_detection_range_body_entered(body):
    if is_dead:
        return

    if body.is_in_group("player"):
        player = body

func _on_detection_range_body_exited(body):
    if body.is_in_group("player") and body == player:
        player = null

func _on_hurtbox_area_entered(area: Area2D) -> void :
    if is_dead:
        return

    if area.is_in_group("player_attack"):
        take_damage(25)
