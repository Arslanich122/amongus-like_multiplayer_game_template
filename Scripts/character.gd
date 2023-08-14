extends CharacterBody3D

var CameraRotation = Vector2.ZERO
var killed_num = 0
@onready var head = $head
@onready var cam = $head/Camera3D
@export var canAttack = false
var SPEED = 3
var attack = false
var start = true
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.current = true
	

func _input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * 0.003
		CameraLook(MouseEvent)

func CameraLook(Movement: Vector2):
	if not is_multiplayer_authority(): return
	CameraRotation += Movement
	CameraRotation.y = clamp(CameraRotation.y, deg_to_rad(-70), deg_to_rad(75))
	
	head.transform.basis = Basis()
	cam.transform.basis = Basis()
	
	head.rotate_object_local(Vector3.UP, -CameraRotation.x)
	cam.rotate_object_local(Vector3.RIGHT, -CameraRotation.y)


func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	if killed_num >= 2:
		print("Маньяк выиграл раунд")
	
	print(killed_num)
	if Input.is_action_pressed("attack") and canAttack:
		attack = true
		$AttackPlayer.play()
		$AttackTimer.start()
		if $head/Camera3D/RayCast3D.is_colliding():
			var hit_player = $head/Camera3D/RayCast3D.get_collider()
			hit_player.rpc("kill_player")
		canAttack = false
		$AbilTimer.start()
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		SPEED = 3
		if Input.is_action_pressed("run"):
			SPEED = 8
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	anim_change()
	velocity = velocity.rotated(Vector3.UP, head.rotation.y)
	
	if canAttack:
		$Control/Label.text = "Ты маньяк ! Убей их"
	else:
		$Control/Label.text = "Ты мирный ! Выживи"

	move_and_slide()

func anim_change_pose():
	if SPEED == 3:
		$Armature.position.y = -0.83
	$Armature.position.y = -0.7




func _on_timer_timeout():
	attack = false

func footstep():
	$AudioStreamPlayer3D.playing = true

func anim_change():
	$AnimationTree.set("parameters/conditions/attack", attack)
	$AnimationTree.set("parameters/conditions/idle", velocity == Vector3.ZERO && !attack)
	$AnimationTree.set("parameters/conditions/run", velocity.length() == 8 && !attack)
	$AnimationTree.set("parameters/conditions/walk", velocity.length() <= 3 && velocity.length() != 0 && !attack)

@rpc("call_local", "any_peer")
func security():
	var mat = preload("res://Assets/blue.tres")
	$head/Armature/Skeleton3D/CharacterMesh.set_surface_override_material(1,mat)
	canAttack = false

@rpc("call_local", "any_peer")
func maniac():
	canAttack = true
	

@rpc("call_local", "any_peer")
func kill_player():
	visible = false
	position = Vector3.ZERO
	$head/Camera3D/ColorRect.visible = true
	killed_num += 1


func _on_abil_timer_timeout():
	canAttack = true
