extends Node2D

class_name CamAnimatronic

@export var Difficulty : int
@export var Sprites : AnimatedSprite2D
@export var StartingCam : int = 1
var CurrentCam : int = 1
var PreviousCam : int = 1
var State : int
var PlayerCam : int = 1

enum LURE {OFF, LOW, MED, HIGH}
var CamLures : Dictionary = {
	1 : LURE.OFF, 2 : LURE.OFF, 3 : LURE.OFF, 4 : LURE.OFF, 5 : LURE.OFF, 
	6 : LURE.OFF, 7 : LURE.OFF, 8 : LURE.OFF, 9 : LURE.OFF, 10 : LURE.OFF,
	11 : LURE.OFF } # 11 is needed for the office

func _ready():
	CurrentCam = StartingCam
	PreviousCam = StartingCam

func PassInInfo(lures : Dictionary, cam : int):
	CamLures = lures
	PlayerCam = cam

func SetCam(cam : int):
	PreviousCam = CurrentCam
	CurrentCam = cam
	SetSprite(cam)

func SetSprite(cam : int):
	Sprites.play(str(cam))

func SetSpriteVis(value : bool):
	Sprites.visible = value

func Move():
	pass

signal TimeOut
signal Moved
signal Jumpscared
