extends Node

# 640 is the display setting
const SPAWN_RADIUS = 375

@export var basic_enemy_scene: PackedScene
@export var wizard_enemy_scene: PackedScene
@export var bat_enemy_scene: PackedScene
@export var arena_time_manager: Node

@onready var timer = $Timer

var base_spawn_time = 0
var enemy_table = WeightedTable.new()
var number_to_spawn = 1


func _ready():
	enemy_table.add_item(basic_enemy_scene, 10)
	base_spawn_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)


func get_spawn_position():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.ZERO
	
	
	var spawn_position = Vector2.ZERO
	var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
		
		# we need to add an additional 20px because we are checking compared to the center of the enemy
		var additional_check_offset = random_direction * 20
		var query_params = PhysicsRayQueryParameters2D.create(player.global_position, spawn_position + additional_check_offset, 1)
		var result = get_tree().root.world_2d.direct_space_state.intersect_ray(query_params)
		
		if result.is_empty():
			# no intersection
			return spawn_position
		else:
			random_direction = random_direction.rotated(deg_to_rad(90))

	return spawn_position


func on_timer_timeout():
	timer.start()
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	for i in number_to_spawn:
		var enemy_scene = enemy_table.pick_item()
		var enemy = enemy_scene.instantiate() as Node2D
		
		var entites_layer = get_tree().get_first_node_in_group("entites_layer")
		entites_layer.add_child(enemy)
		enemy.global_position = get_spawn_position()


func on_arena_difficulty_increased(arena_difficulty: int):
	var time_off = (0.1 / 12) * arena_difficulty
	time_off = min(time_off,  0.7)
	timer.wait_time = base_spawn_time - time_off

	if arena_difficulty == 6:
		enemy_table.add_item(wizard_enemy_scene, 15)
	elif arena_difficulty == 18:
		enemy_table.add_item(bat_enemy_scene, 8)

	if (arena_difficulty % 6) == 0:
		number_to_spawn += 1
