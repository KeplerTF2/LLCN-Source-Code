extends Node2D

@export var Difficulty : int
@export var Permatrap : bool = false
var WasOnPreviousFlip : bool = false
var OnCamera : bool = false
var CurrentlyShown : bool = false
var PowerToDrain : float = 10
var NumOfJumpscares : int = -1

# Called when the node enters the scene tree for the first time.
func Init():
	$MixedBag.InitialBag = []
	if !Permatrap:
		$MixedBag.PopulateInitialBag(true, Difficulty)
		$MixedBag.PopulateInitialBag(false, 40 - Difficulty)
	else:
		$MixedBag.PopulateInitialBag(true, 40)
		$Sprite.play("permatrap")
	$MixedBag.RefillBag()
	CalcAttackTime()

func PassInInfo(OnCams : bool):
	if Difficulty != 0:
		OnCamera = OnCams
		if OnCamera:
			if !WasOnPreviousFlip || Permatrap:
				if $MixedBag.GetItem():
					ShowUp()
					WasOnPreviousFlip = true
			else:
				WasOnPreviousFlip = false
		else:
			if CurrentlyShown:
				OutOfDanger.emit()
			Unshow()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func ShowUp():
	CurrentlyShown = true
	$Sprite.visible = true
	$AttackTimer.start()
	$DangerTimer.start()

func Unshow():
	CurrentlyShown = false
	$Sprite.visible = false
	$AttackTimer.stop()
	$DangerTimer.stop()

func CalcAttackTime():
	if !Global.Bitcrush:
		$AttackTimer.wait_time = 3.0 - (Difficulty / 10.0)
		if Permatrap:
			$AttackTimer.wait_time *= 3.5
	else:
		$AttackTimer.wait_time = (-0.375 * Global.StarDiff) + 3.875
		if !Permatrap:
			$AttackTimer.wait_time /= 3.5
	$DangerTimer.wait_time = $AttackTimer.wait_time - 0.5
	CalcPowerDrain()

func CalcPowerDrain():
	PowerToDrain = 10 + (Difficulty / 2) + (5 * NumOfJumpscares)

func _on_attack_timer_timeout():
	NumOfJumpscares += 1
	CalcPowerDrain()
	Jumpscared.emit()
	OutOfDanger.emit()
	$RestoreTimer.start()

func _on_danger_timer_timeout():
	InDanger.emit()

func _on_restore_timer_timeout():
	RestoreCams.emit()

signal Jumpscared
signal InDanger
signal OutOfDanger
signal RestoreCams
