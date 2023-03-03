extends CharacterBody2D


enum PlayerStates {DEFAULT, HOOKED}
enum HookStates {NONE, EXTEND, RETRACT_TO_PLAYER}

const SPEED := 400.0
const JUMP_VELOCITY := -600.0
const HOOK_MAX_LENGTH := 600.0
const HOOK_SPEED := 800.0
const PLAYER_HOOK_SPEED := 600.0
const MAX_JUMPS := 1
const ACCELERATION := 1_500.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var hook_direction: Vector2
var player_state: PlayerStates = PlayerStates.DEFAULT
var hook_state: HookStates = HookStates.NONE
var jumps := 0

@onready var hook := $Hook
@onready var hook_shape := $Hook/CollisionShape2D
@onready var line := $Line2D


func _physics_process(delta: float) -> void:
	if is_on_floor():
		jumps = 0
		
	match player_state:
		PlayerStates.DEFAULT:
			# Add the gravity.
			if not is_on_floor():
				velocity.y += gravity * delta

			# Handle Jump.
			if Input.is_action_just_pressed("ui_up") and jumps < MAX_JUMPS:
				velocity.y = JUMP_VELOCITY
				jumps += 1

			# Get the input direction and handle the movement/deceleration.
			# As good practice, you should replace UI actions with custom gameplay actions.
			var direction := Input.get_axis("ui_left", "ui_right")
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)

			move_and_slide()
		PlayerStates.HOOKED:
			var collision := move_and_collide(velocity * delta)
			if collision:
				player_state = PlayerStates.DEFAULT
				hide_hook()
			elif global_position.distance_to(hook.global_position) <= PLAYER_HOOK_SPEED * delta:
				global_position = hook.global_position
				player_state = PlayerStates.DEFAULT
				hide_hook()
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				player_state = PlayerStates.DEFAULT
				hook_state = HookStates.RETRACT_TO_PLAYER
			if Input.is_action_pressed("ui_up"):
				if jumps < MAX_JUMPS:
					velocity.y = JUMP_VELOCITY
					jumps += 1
				player_state = PlayerStates.DEFAULT
				hook_state = HookStates.RETRACT_TO_PLAYER
	match hook_state:
		HookStates.EXTEND:
			hook.global_position += hook_direction * HOOK_SPEED * delta
			if hook.global_position.distance_to(global_position) >= HOOK_MAX_LENGTH:
				hook_state = HookStates.RETRACT_TO_PLAYER
				hook_shape.set_disabled.call_deferred(true)
		HookStates.RETRACT_TO_PLAYER:
			hook.global_position += hook.global_position.direction_to(global_position) * HOOK_SPEED * delta
			if hook.global_position.distance_to(global_position) <= HOOK_SPEED * delta:
				hook_state = HookStates.NONE
				hide_hook()
				
	if hook.visible:
		line.points[1] = to_local(hook.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click") and hook_state == HookStates.NONE:
		hook.global_position = global_position
		hook_state = HookStates.EXTEND
		hook_direction = get_local_mouse_position().normalized()
		hook.show()
		line.show()
		hook_shape.disabled = false


func _on_hook_body_entered(_body: Node2D) -> void:
	player_state = PlayerStates.HOOKED
	velocity = global_position.direction_to(hook.global_position) * PLAYER_HOOK_SPEED
	hook_state = HookStates.NONE
	hook_shape.set_disabled.call_deferred(true)


func hide_hook() -> void:
	hook.hide()
	line.hide()
	hook_shape.set_disabled.call_deferred(true)
