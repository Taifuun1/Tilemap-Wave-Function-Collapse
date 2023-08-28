extends Control

var itemName
var add = true

func create(_name, _add = true):
	itemName = _name
	name = str(_name)
	$Name.text = _name
	add = _add

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if add:
			$"../.."._on_Add_Input_Item_Clicked(itemName)
		else:
			$"../../../Inputs"._on_Remove_Input_Item_Clicked(itemName)
