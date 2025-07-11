extends Camera2D

@onready var noise = FastNoiseLite.new()
var noise_y = 0

@export var decay = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).
@export var min_zoom = 0.5

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

func _ready():
	randomize()
	noise.seed = randi()
	#noise.frequency = 0.1
	#noise.octaves = 2

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func _physics_process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()

func shake():
	var amount : float = pow(trauma, trauma_power) 
	noise_y += 4
	rotation = max_roll * amount * noise.get_noise_2d(0, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(100, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(200, noise_y)
	zoom = Vector2((amount/2)+1,(amount/2)+1)
