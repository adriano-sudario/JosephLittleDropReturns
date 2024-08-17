class_name DebugPanel
extends CanvasLayer

var variables_info = []
var temporary_messages = []
var elapsed_time:float

@onready var label = $PanelContainer/MarginContainer/Label
@onready var temp_panel_container = $TempPanelContainer
@onready var label_temp = $TempPanelContainer/MarginContainer/Label

func get_readable_elapsed_time():
	var elapsed_time_floor = floor(elapsed_time)
	
	var seconds = int(elapsed_time_floor) % 60
	var minutes = int((elapsed_time_floor / 60)) % 60
	var hours = int((elapsed_time_floor / 60) / 60)
	
	if hours == 0:
		return "%02d:%02d" % [minutes, seconds]
	else:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]

func get_readable_elapsed_time_with_millisecond():
	var elapsed_time_floor = floor(elapsed_time)
	var milliseconds = int((elapsed_time - elapsed_time_floor) * 1000)
	
	if elapsed_time_floor == 0:
		return "%0.3f" % milliseconds
	
	var seconds = int(elapsed_time_floor) % 60
	var minutes = int((elapsed_time_floor / 60)) % 60
	var hours = int((elapsed_time_floor / 60) / 60)
	
	if hours == 0:
		return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]
	else:
		return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]

func setup_node_variables(node: Node, variables: Array[String], node_description = null):
	if node_description == null:
		node_description = StringExtension.pascal_case_to_snake_case(node.name)
	
	for variable in variables:
		var variable_split = variable.split("%")
		var variable_name = variable_split[0]
		var format = ""
		
		if variable_split.size() > 1:
			format = "%" + variable_split[1]
		
		variables_info.append({
			"node": node,
			"node_description": node_description,
			"variable": variable_name,
			"format": format
		})

func setup_node_callable(node: Node, description: String, callable: Callable,
	format: String, node_description = null):
	if node_description == null:
		node_description = StringExtension.pascal_case_to_snake_case(node.name)
	
	variables_info.append({
		"node": node,
		"node_description": node_description,
		"variable": description,
		"format": format,
		"callable": callable
	})

func remove_node(node: Node):
	for i in range(variables_info.size() - 1, 0, -1):
		if variables_info[i].node == node:
			variables_info.remove_at(i)

func update_label_temp():
	temp_panel_container.visible = temporary_messages.size() > 0
	var text = ""
	
	for i in temporary_messages.size():
		var temporary_message = temporary_messages[i]
		text += temporary_message
		
		if i < temporary_messages.size() - 1:
			text += "\n\n"
	
	label_temp.text = text

func remove_message(message: String):
	for i in temporary_messages.size():
		var temporary_message = temporary_messages[i]
		
		if temporary_message.begins_with(message):
			temporary_messages.remove_at(i)
			update_label_temp()
			return

func show_message(message: String, seconds := 1.5, show_elapsed_time := false):
	if show_elapsed_time:
		message = "%s (%s)" % [message, get_readable_elapsed_time_with_millisecond()]
	
	if temporary_messages.has(message):
		return
	
	temporary_messages.append(message)
	update_label_temp()
	
	if seconds <= 0:
		return
	
	await get_tree().create_timer(seconds).timeout
	remove_message(message)

func _process(delta):
	elapsed_time += delta
	
	if Input.is_action_just_pressed("toggle_debug_panel"):
		visible = not visible
	
	if not visible:
		return
	
	var info_text = "%s ~ %d FPS" % [get_readable_elapsed_time(), Engine.get_frames_per_second()]
	var variables_info_size = variables_info.size()
	
	if variables_info_size > 0:
		info_text += "\n\n"
	
	var clear_null_nodes := false
	
	for variable_info_index in variables_info_size:
		var variable_info = variables_info[variable_info_index]
		
		if variable_info.node == null:
			clear_null_nodes = true
			continue
		
		var value
		var is_callable = variable_info.has("callable")
		
		if is_callable:
			value = variable_info.callable.call()
		else:
			var variable_access = variable_info.variable.split(".")
			value = variable_info.node.get(variable_access[0])
			
			for i in range(1, variable_access.size()):
				value = value[variable_access[i]]
		
		var format = variable_info.format
		
		if format.is_empty():
			format = "%s"
			
			if typeof(value) == TYPE_INT:
				format = "%d"
			elif typeof(value) == TYPE_FLOAT:
				format = "%0.2f"
		
		info_text += ("- %s / %s : " + format) % [
			variable_info.node_description,
			variable_info.variable,
			value
		]
		
		if variable_info_index < variables_info_size:
			info_text += "\n"
	
	label.text = info_text
	
	if clear_null_nodes:
		remove_node(null)
