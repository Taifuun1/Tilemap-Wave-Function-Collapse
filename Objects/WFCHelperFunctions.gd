
func checkIfArrayOfClassesHasValue(_array, _property, _value):
	for _index in _array.size():
		if _array[_index][_property] == _value:
			return _index
	return -1

func checkIfTileExists(_position, _testTiles, _generatedTiles) -> bool:
	if _testTiles.has(_position) or _generatedTiles.has(_position):
		return true
	return false
