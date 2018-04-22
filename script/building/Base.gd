extends "Building.gd"

var type;

func init(type, requirements, resources, strength, name, description, texture):
	.init(requirements, resources, strength, name, description, texture);
	self.type = type;
	return self;

func getStrength(hex):
	var mod = 0;
	for vertex in hex.vertices:
		if vertex.token != null and vertex.token.name == "Shield Generator" and vertex.player == hex.player:
			mod += 1;
	return strength + mod;
