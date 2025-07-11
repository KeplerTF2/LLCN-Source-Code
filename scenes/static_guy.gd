extends Node2D

@export var Difficulty : int
@export var StartingCam : int = 2
@export var LongNights : bool = false
@export var ShortNights : bool = false
@export var Tutorial : bool = false
@onready var CurrentCam : int = StartingCam
@onready var PreviousCam : int = StartingCam
var PlayerCam : int = 1

var CamTree : Dictionary = {
	0: [],
	1: [3,4],
	2: [5,6],
	3: [1,4],
	4: [1,3,5,8],
	5: [2,4,6,8,9],
	6: [2,5,9],
	7: [8],
	8: [4,5,7,9],
	9: [5,8,10],
	10: [9],
	11: []
}

var SendProgress : Dictionary = {
	0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0, 8: 0.0, 9: 0.0, 10: 0.0, 11: 0.0
}
var MaxSendProgress : float = 30
var PowerConsumption : float = 30 # %/min
var EnteringOffice : bool = false
var VisitedCams : Array = [2]

# Called when the node enters the scene tree for the first time.
func Init():
	CalcPowerConsumption()
	if Global.Bitcrush:
		SetCam(0)
	if ShortNights:
		$OfficeTimer.wait_time = 40.0 / 6.0

func PassInInfo(cam : int):
	PlayerCam = cam

func SetCam(cam : int):
	PreviousCam = CurrentCam
	CurrentCam = cam
	SetSpriteVis(cam == PlayerCam)

func SetSpriteVis(value : bool):
	$OpaqueStatic.visible = value 

func CalcPowerConsumption():
	PowerConsumption = 30 + (Difficulty * 1.5)

func Move(cam : int):
	if CamTree[CurrentCam].has(cam):
		CancelProgress()
		SetCam(cam)
		Moved.emit()
		StartEnterOffice()
	if !VisitedCams.has(cam):
		VisitedCams.append(cam)
		print(VisitedCams)

func CancelProgress():
	SendProgress = { 1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0, 8: 0.0, 9: 0.0, 10: 0.0, 11: 0.0 }

func StartEnterOffice():
	if CurrentCam == 8 || CurrentCam == 10:
		EnteringOffice = true
		$KeyFumbling.play()
		if !Tutorial:
			$OfficeTimer.start()

func AddProgress(cam : int, delta):
	if !Tutorial:
		if !LongNights and !ShortNights:
			SendProgress[cam] += delta
		elif ShortNights:
			SendProgress[cam] += delta * 6.0
		else:
			SendProgress[cam] += delta / 2.0
	else:
		SendProgress[cam] += delta * 6.0
	if cam != CurrentCam and (CurrentCam == 8 || CurrentCam == 10):
		CancelEnterOffice()

func CancelEnterOffice():
	EnteringOffice = false
	$KeyFumbling.stop()
	$OfficeTimer.stop()

func _on_office_timer_timeout():
	SetCam(11)
	$KeyFumbling.stop()
	EnteredOffice.emit()

func _process(delta):
	if Input.is_action_just_pressed("win"):
		VisitedCams = [1,2,3,4,5,6,7,8,9,10]
		_on_office_timer_timeout()
	if Input.is_action_just_pressed("win_noglobetrotter"):
		_on_office_timer_timeout()

signal EnteredOffice
signal Moved
