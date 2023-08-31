extends Node

func _ready():
	randomize()
	
	$InputsContainer.hide()
	$GenerationContainer.hide()

func _on_Select_Inputs_pressed():
	$StartContainer.hide()
	$InputsContainer.show()

func _on_New_WFC_Generation_pressed():
	var _selectedInputs = $InputsContainer/VBoxContainer/HBoxContainer/Inputs.selectedInputs
	for _fileName in _selectedInputs:
		$GenerationContainer/Inputs.add_child(load("res://Inputs/{fileName}.tscn".format({ fileName = _fileName })).instantiate())
	
	$InputsContainer.hide()
	$GenerationContainer.show()
#	$GenerationContainer/Camera2D.zoom = Vector2(0.33, 0.33)
	
	$GenerationContainer/WaveFunctionCollapse.generateMap()
