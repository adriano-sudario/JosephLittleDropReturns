extends Node

var panel:DebugPanel = null

func _ready():
	if OS.is_debug_build():
		panel = load("res://entities/debug/debug_panel.tscn").instantiate()
		add_child(panel)

func setup_node_variables(node: Node, variables: Array[String], node_description = null):
	if panel == null:
		return
	
	panel.setup_node_variables(node, variables, node_description)

func setup_node_callable(node: Node, description: String, callable: Callable,
	format := "%s", node_description = null):
	panel.setup_node_callable(
		node,
		description.to_lower().replace(" ", "_") + "()",
		callable,
		format,
		node_description)

func remove_node(node: Node):
	if panel == null:
		return
	
	panel.remove_node(node)

func remove_message(message: String):
	if panel == null:
		return
	
	panel.remove_message(message)

func show_message(message: String, seconds := 1.5, show_elapsed_time := false):
	if panel == null:
		return
	
	panel.show_message(message, seconds, show_elapsed_time)
