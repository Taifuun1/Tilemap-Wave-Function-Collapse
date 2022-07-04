extends CanvasLayer

#onready var waveFunctionCollapse = preload("res://Objects/Wave Function Collapse.tscn").instance()

func _ready():
	$InputsContainer.hide()
	$GenerationContainer.hide()

func _on_Select_Inputs_pressed():
	$StartContainer.hide()
	$InputsContainer.show()

func _on_New_WFC_Generation_pressed():
	var _selectedInputs = $InputsContainer/VBoxContainer/HBoxContainer/Inputs.selectedInputs
	for _fileName in _selectedInputs:
		$GenerationContainer/Inputs.add_child(load("res://Inputs/{fileName}.tscn".format({ fileName = _fileName })).instance())
	
	$InputsContainer.hide()
	$GenerationContainer.show()
	
	$GenerationContainer/WaveFunctionCollapse.generateMap()#Vector2(24, 60))