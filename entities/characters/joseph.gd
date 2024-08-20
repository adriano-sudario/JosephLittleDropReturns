extends CharacterBody2D

@export var speed := 300.0
@export var running_boost := 150.0
@export var jump_force := 400.0
@export var start_flipped := false
@export var coyote_time := 0.15

var level: Level
var is_holding_jump := false
var has_just_released_jump := false
var is_waiting_release_to_jump := false
var has_jump := false
var is_running := false
var gravity := 980.0
var gravity_force_applied := 0.0
var direction_input := Vector2.ZERO
var collision_flip_sign:int
var coyote_timer: SceneTreeTimer

var is_flipped:bool = false:
	set(value):
		is_flipped = value
		sprite.flip_h = is_flipped
		
		if is_flipped:
			collision.position.x = abs(collision.position.x) * -collision_flip_sign
		else:
			collision.position.x = abs(collision.position.x) * collision_flip_sign

@onready var was_on_floor := is_on_floor()
@onready var sprite = $Sprite
@onready var collision = $Collision

const MINIMAL_JUMP_FORCE := 150.0

func _ready():
	if Input.is_action_pressed("jump"):
		is_waiting_release_to_jump = true
	
	collision_flip_sign = sign(collision.position.x)
	is_flipped = start_flipped
	
	var _level = get_parent()
	
	while _level != null and not _level is Level:
		_level = _level.get_parent()
	
	level = _level

func get_direction_input() -> Vector2:
	var x = 0
	var y = 0
	
	if Input.is_action_pressed("left"):
		x = -1
	elif Input.is_action_pressed("right"):
		x = 1
	
	if Input.is_action_pressed("up"):
		y = -1
	elif Input.is_action_pressed("down"):
		y = 1
	
	return Vector2(x, y)

func _process(_delta):
	is_holding_jump = Input.is_action_pressed("jump")
	has_just_released_jump = Input.is_action_just_released("jump")
	
	if not is_on_floor() and is_holding_jump:
		is_waiting_release_to_jump = true
	elif has_just_released_jump:
		is_waiting_release_to_jump = false
	
	direction_input = get_direction_input()
	is_running = Input.is_action_pressed("run") and direction_input.x != 0

func _physics_process(delta):
	update_gravity_force(delta)
	update_movement()
	update_animation()

func update_gravity_force(delta):
	if is_on_floor():
		handle_jump_or_landing()
	else:
		if was_on_floor and not has_jump:
			coyote_timer = get_tree().create_timer(coyote_time)
			coyote_timer.timeout.connect(on_coyote_timer_timeout)
		
		gravity_force_applied += gravity * delta
		
		if is_holding_jump and not has_jump:
			jump()
		
		if has_jump and has_just_released_jump:
			if gravity_force_applied < -MINIMAL_JUMP_FORCE:
				gravity_force_applied = -MINIMAL_JUMP_FORCE
			
			has_jump = false
	
	was_on_floor = is_on_floor()

func land():
	if has_jump and has_just_released_jump:
		has_jump = false
	
	gravity_force_applied = 0

func handle_jump_or_landing():
	if is_holding_jump and not has_jump:
		jump()
	else:
		land()

func jump():
	if (not is_on_floor() or (is_waiting_release_to_jump and not has_just_released_jump))\
		and coyote_timer == null:
		return
	
	gravity_force_applied = -jump_force
	has_jump = true

func on_coyote_timer_timeout():
	coyote_timer.timeout.disconnect(on_coyote_timer_timeout)
	coyote_timer = null

func update_movement():
	var speed_boost = 0
	
	if is_running:
		speed_boost = running_boost
	
	velocity = Vector2(direction_input.x * (speed + speed_boost), gravity_force_applied)
	move_and_slide()

func update_animation():
	if velocity.x == 0:
		sprite.play("idle")
	else:
		if velocity.y == 0:
			if is_running:
				sprite.play("run")
			else:
				sprite.play("walk")
		
		is_flipped = velocity.x < 0
	
	if velocity.y < 0:
		sprite.play("air_up")
	elif velocity.y > 0:
		sprite.play("air_down")
