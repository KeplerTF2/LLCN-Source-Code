extends Node2D

@export var Difficulty : int
@export var KillerTheory : bool = false
var Cam : int = 3
var Attacking : bool = false
var GracePeriod = true

enum LURE {OFF, LOW, MED, HIGH}
var RequiredLure : int = LURE.OFF
var CamLure : int = LURE.OFF

# Called when the node enters the scene tree for the first time.
func Init():
	if Difficulty != 0:
		CalcKillTimer()
		StartAttackTimers()

func SetSpriteVis(value : bool):
	if Attacking:
		$Sprite.visible = value
	else:
		$Sprite.visible = false

func CalcKillTimer():
	if !Global.Bitcrush:
		$KillTimer.wait_time = 15.0 - (Difficulty / 2.0)
	else:
		$KillTimer.wait_time = (-0.5 * Global.StarDiff) + 5.5

func StartAttackTimers():
	$AttackTimer.wait_time = $TimeBag.GetItem() - (2 * Difficulty)
	if Global.Bitcrush:
		$AttackTimer.wait_time = $AttackTimer.wait_time / (((Global.StarDiff - 1) / 10.0) + 1)
	$HallucinateTimer.wait_time = $AttackTimer.wait_time / 2
	$AttackTimer.start()
	$HallucinateTimer.start()

func PassInInfo(lure : int):
	CamLure = lure
	if Attacking and CamLure == RequiredLure:
		EndAttack()
	elif Attacking and CamLure != RequiredLure and CamLure != LURE.OFF and KillerTheory and !GracePeriod:
		Jumpscared.emit()

func Attack():
	RequiredLure = $LureBag.GetItem()
	match RequiredLure:
		LURE.LOW:
			$low.play()
			$Sprite/Eyes.material.set_shader_parameter("colour", Global.LowColour)
			$Sprite/Eyes.play("low")
		LURE.MED:
			$med.play()
			$Sprite/Eyes.material.set_shader_parameter("colour", Global.MedColour)
			$Sprite/Eyes.play("med")
		LURE.HIGH:
			$high.play()
			$Sprite/Eyes.material.set_shader_parameter("colour", Global.HighColour)
			$Sprite/Eyes.play("high")
	if RequiredLure != CamLure:
		Attacking = true
		$GraceTimer.start()
		$KillTimer.start()
		Moved.emit()
	else:
		EndAttack()

func EndAttack():
	Attacking = false
	GracePeriod = true
	$KillTimer.stop()
	SetSpriteVis(false)
	$Sprite/Eyes.play("off")
	StartAttackTimers()
	Moved.emit()

func _on_kill_timer_timeout():
	Jumpscared.emit()

func _on_hallucinate_timer_timeout():
	Hallucinate.emit()

func _on_attack_timer_timeout():
	Attack()

func _on_grace_timer_timeout():
	GracePeriod = false
	if Attacking and CamLure != RequiredLure and CamLure != LURE.OFF and KillerTheory:
		Jumpscared.emit()

signal Jumpscared
signal Moved
signal Hallucinate
