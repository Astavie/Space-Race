extends TileMap

func _ready():
	seed(OS.get_unix_time());
	for x in range(60):
		for y in range(34):
			set_cell(x, y, randi()%10);
