class_name Main
extends Node2D

@export var initial_scene: PackedScene

var current_scene

func _ready():
	if initial_scene == null:
		return
	
	if current_scene == null:
		current_scene = initial_scene.instantiate()
		add_child(current_scene)

func change_to_scene(path: String):
	change_to_packed_scene(load(path))

func change_to_packed_scene(packed_scene: PackedScene):
	current_scene.tree_exited.connect(func():
		current_scene = packed_scene.instantiate()
		add_child.call_deferred(current_scene))
	current_scene.queue_free()
