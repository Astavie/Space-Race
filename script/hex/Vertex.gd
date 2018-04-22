var hexes = [];
var edges = [];
var vertices = [];
var i;

var token;
var player;

func init(hex1, i):
	self.hexes.append(hex1);
	self.i = i;
	return self;

func canPlace(player):
	if token != null:
		return false;
	for hex in hexes:
		if hex.player == player and hex.type & 1 == 1:
			return 1;
	for hex in hexes:
		if hex.player == player and hex.base.name == "Military Base":
			return 2;
	return 0;

func build(build, player):
	self.token = build;
	self.player = player;

func getType():
	if hexes.size() == 3 and hexes[0].type == hexes[1].type and hexes[1].type == hexes[2].type:
		return hexes[0].type;
	return 0;
