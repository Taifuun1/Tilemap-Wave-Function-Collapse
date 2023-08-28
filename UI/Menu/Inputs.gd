extends ScrollContainer

@onready var inputItem = preload("res://UI/InputItem/InputItem.tscn")

var inputsPath = "res://Inputs"

var selectedInputs = []

func _ready():
	var dir = DirAccess.open(inputsPath)
	if dir:
		dir.list_dir_begin()
		var fileName = dir.get_next()
		while fileName != "":
			if not dir.current_is_dir() and fileName.get_extension().matchn("tscn"):
				var newItem = inputItem.instantiate()
				newItem.create(fileName.trim_suffix(".tscn"))
				$InputsList.add_child(newItem)
			fileName = dir.get_next()

func _on_Add_Input_Item_Clicked(itemName):
	selectedInputs.append(itemName)
	var newItem = inputItem.instantiate()
	newItem.create(itemName, false)
	$"../SelectedInputs/SelectedInputsList".add_child(newItem)
	get_node("InputsList/{itemName}".format({ itemName = itemName })).queue_free()

func _on_Remove_Input_Item_Clicked(itemName):
	selectedInputs.erase(itemName)
	var newItem = inputItem.instantiate()
	newItem.create(itemName)
	$"InputsList".add_child(newItem)
	get_node("../SelectedInputs/SelectedInputsList/{itemName}".format({ itemName = itemName })).queue_free()
