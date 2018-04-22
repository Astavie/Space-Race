extends "Building.gd"

func init():
	.init({ "wealth": 2, "colonists": 1 }, {}, 0, "Route", "Set up a transport route", load("res://tile/building/Route.png"));
	return self;
