extends Camera2D

var up = false;
var down = false;
var left = false;
var right = false;

var drag = false;

var message;

func _ready():
	message = get_node("../Foreground/Menu");

func _process(delta):
	# MOVE CAMERA
	if not drag and not message.is_visible():
		if up:
			set_offset(get_offset() + Vector2(0, -500 * delta));
		if down:
			set_offset(get_offset() + Vector2(0, 500 * delta));
		if left:
			set_offset(get_offset() + Vector2(-500 * delta, 0));
		if right:
			set_offset(get_offset() + Vector2(500 * delta, 0));

func _input(event):
	# ARROW KEYS
	if event.is_action_pressed("ui_up"):
		up = true;
	elif event.is_action_released("ui_up"):
		up = false;
	if event.is_action_pressed("ui_down"):
		down = true;
	elif event.is_action_released("ui_down"):
		down = false;
	if event.is_action_pressed("ui_left"):
		left = true;
	elif event.is_action_released("ui_left"):
		left = false;
	if event.is_action_pressed("ui_right"):
		right = true;
	elif event.is_action_released("ui_right"):
		right = false;
	
	# MOUSE DRAG
	if event.is_action_pressed("ui_drag"):
		drag = true;
	elif event.is_action_released("ui_drag"):
		drag = false;
	elif event is InputEventMouseMotion and drag and not message.is_visible():
		set_offset(get_offset() - event.relative);
