var requirements;
var resources;
var strength;
var name;
var description;
var texture;

func init(requirements, resources, strength, name, description, texture):
	self.requirements = requirements;
	self.resources = resources;
	self.strength = strength;
	self.name = name;
	self.description = description;
	self.texture = texture;
	return self;
