extends Node2D

@export var Difficulty : int
@export var HyperFreddy : bool = false
var Active : bool = false
var Progress : float = 0.0
var MaxProgress : float = 50.0
var PowerGenerating : bool = false
var PhoneGuyRinging : bool = false
var LuringStaticGuy : bool = false
var QueueDeactivation : bool = false

enum LURE {OFF, LOW, MED, HIGH}
var CamLures : Dictionary = {
	1 : LURE.OFF, 2 : LURE.OFF, 3 : LURE.OFF, 4 : LURE.OFF, 5 : LURE.OFF, 
	6 : LURE.OFF, 7 : LURE.OFF, 8 : LURE.OFF, 9 : LURE.OFF, 10 : LURE.OFF,
	11 : LURE.OFF } # 11 is needed for the office

func Init():
	CalcMaxProgress()
	SetKillTimer()

func _physics_process(delta):
	AddProgress(delta)

func PassInInfo(lures : Dictionary, PowerGen : bool, PhoneGuy : bool, StaticGuy : bool):
	CamLures = lures
	PowerGenerating = PowerGen
	PhoneGuyRinging = PhoneGuy
	LuringStaticGuy = StaticGuy

func CalcMaxProgress():
	MaxProgress = 50.0 - (Difficulty * 2.0)
	if Global.Bitcrush:
		MaxProgress = MaxProgress / (((Global.StarDiff - 1) / 3.0) + 1)

func AddProgress(delta : float):
	if !Active and Difficulty != 0:
		if !HyperFreddy:
			for Cam in CamLures:
				Progress += delta * CamLures[Cam]
			Progress += delta * int(PowerGenerating)
			Progress += delta * int(PhoneGuyRinging)
			Progress += delta * int(LuringStaticGuy)
		else:
			for Cam in CamLures:
				if CamLures[Cam] != LURE.OFF:
					Progress += delta * 3
			Progress += delta * int(PowerGenerating) * 3
			Progress += delta * int(PhoneGuyRinging) * 3
			Progress += delta * int(LuringStaticGuy) * 3
		if Progress >= MaxProgress:
			Activate()

func Activate():
	Active = true
	Progress = 0.0
	$Sprite.play("on")
	$Active.play()
	$KillTimer.start()
	$PitchTimer.start()
	Activated.emit()
	if QueueDeactivation:
		Deactivate()

func Deactivate():
	Active = false
	$PitchTimer.stop()
	$Active.pitch_scale = 1.0
	$Active.volume_db = -7.0
	$Sprite.play("off")
	$Active.stop()
	$Deactivate.play()
	$KillTimer.stop()
	Deactivated.emit()

func _on_kill_timer_timeout():
	Jumpscared.emit()

func _on_hitbox_area_entered(area):
	if Active:
		Deactivate()
	QueueDeactivation = true

func _on_hitbox_area_exited(area):
	QueueDeactivation = false

func _on_pitch_timer_timeout():
	$Active.pitch_scale = 0.5
	$Active.volume_db = 0.0

func SetKillTimer():
	if Global.Bitcrush:
		$KillTimer.wait_time = (-0.625 * Global.StarDiff) + 5.625
		$PitchTimer.wait_time = $KillTimer.wait_time - 1.0

signal Jumpscared
signal Activated
signal Deactivated

func _on_cams_closed_cam() -> void:
	if Global.Bitcrush:
		position.x = randi_range(272, 2432)
		position.y = randi_range(0, 256)
		scale = Vector2(1 + (position.y / 512.0), 1 + (position.y / 512.0))
