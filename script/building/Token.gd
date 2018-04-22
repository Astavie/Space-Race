extends "Building.gd"

var attack;
var move;

func init(requirements, resources, strength, attack, move, name, description, texture):
	.init(requirements, resources, strength, name, description, texture);
	self.attack = attack;
	self.move = move;
	return self;
