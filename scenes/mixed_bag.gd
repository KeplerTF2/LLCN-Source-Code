extends Node

class_name MixedBag

@export var Size : int
@export var InitialBag : Array
@export var RefillWhenEmpty : bool
var Bag : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	RefillBag()

func RefillBag():
	Bag = InitialBag.duplicate(true)

func Populate(item, amount : int):
	if Bag.size() + amount > Size:
		amount = Size - Bag.size()
	if amount < 0:
		return
	
	for i in range(0, amount):
		Bag.append(item)

func PopulateInitialBag(item, amount : int):
	if InitialBag.size() + amount > Size:
		amount = Size - InitialBag.size()
	if amount < 0:
		return
	
	for i in range(0, amount):
		InitialBag.append(item)

func GetItem():
	if !Bag.is_empty():
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var RandNum = rng.randi_range(0, Bag.size() - 1)
		var Item = Bag.pop_at(RandNum)
		if Bag.is_empty() and !InitialBag.is_empty() and RefillWhenEmpty:
			RefillBag()
		return Item
	else:
		return null
	
