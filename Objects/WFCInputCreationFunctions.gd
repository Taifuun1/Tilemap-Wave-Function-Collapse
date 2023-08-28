
################################
### Input creation functions ###
################################

func createInput(_inputNode) -> Array:
	var _input = []
	for x in range(_inputNode.gridSize.x):
		_input.append([])
		for y in range(_inputNode.gridSize.y):
			_input[x].append(_inputNode.get_cell_source_id(0, Vector2(x,y)))
	return _input

func createNewInputPattern() -> Array:
	var _newInputPattern = []
	for x in range(3):
		_newInputPattern.append([])
		for _y in range(3):
			_newInputPattern[x].append(-1)
	return _newInputPattern

func createInputGrid(_input) -> Array:
	var _inputGrid = []
	for x in range(_input.size()):
		_inputGrid.append([])
		for y in range(_input[x].size()):
			_inputGrid[x].append(_input[x][y])
	return _inputGrid


######################################
### Input pattern getter functions ###
######################################

func getInputPatterns(_input, _allInputs) -> Array:
	var _newInput = []
	for _x in range(1, _input.size() - 1):
		for _y in range(1, _input[_x].size() - 1):
			var _inputPattern = getInputPattern(_input, _x, _y)
			if typeof(_inputPattern) != TYPE_BOOL and !checkIfInputIsAlreadyAnInput(_inputPattern, _newInput, _allInputs):
				_newInput.append(_inputPattern)
	return _newInput

func getInputPattern(_input, _x, _y) -> Array:
	var _inputPattern = createNewInputPattern()
	var _inputPatternX = 0
	var _inputPatternY = 0
	for patternX in range(_x - 1, _x + 2):
		for patternY in range(_y - 1, _y + 2):
			_inputPattern[_inputPatternX][_inputPatternY] = _input[patternX][patternY]
			_inputPatternY += 1
		_inputPatternX += 1
		_inputPatternY = 0
	return _inputPattern


######################################
### Input transform functions ###
######################################

func turnInput(_input) -> Array:
	var _turnedInput = createInputGrid(_input)
	var _inputIndex = _input.size() - 1
	for x in _input.size():
		for y in _input[x].size():
			_turnedInput[x][y] = _input[y][_inputIndex]
		_inputIndex -= 1
	return _turnedInput

func transformInputToPackedInt32Array(_inputArray) -> PackedInt32Array:
	var _input = PackedInt32Array()
	for _xArray in _inputArray:
		for _tile in _xArray:
			_input.append(_tile)
	return _input


########################
### Checker funtions ###
########################

func checkIfInputIsAlreadyAnInput(_newInputPattern, _newInput, _allInputs) -> bool:
	for _inputPattern in _newInput:
		if checkIfInputsAreEqual(_newInputPattern, _inputPattern):
			return true
	for _input in _allInputs:
		for _inputPattern in _input:
			if checkIfInputsAreEqual(_newInputPattern, _inputPattern):
				return true
	return false

func checkIfInputsAreEqual(_newInputPattern: Array, _inputPattern: Array) -> bool:
	for i in _newInputPattern.size():
			if _newInputPattern[i] != _inputPattern[i]:
				return false
	return true
