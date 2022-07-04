extends TileMap
class_name WaveFunctionCollapseTemplate

enum tiles { 
	EMPTY
	CORRIDOR
	WALL_DUNGEON
	FLOOR_DUNGEON
	SIDEWALK
	DOWN_STAIR_DUNGEON
	UP_STAIR_DUNGEON
	DOOR_CLOSED
	DOOR_OPEN
	GRASS
	SEA
	SAND
	SOIL
	WALL_SAND
	WALL_BRICK_SAND
	FLOOR_SAND
	DOWN_STAIR_SAND
	UP_STAIR_SAND
	WALL_BOARD
}

var gridSize = Vector2(0,0)

func create(_gridSize = Vector2(5, 5)):
	gridSize = _gridSize
