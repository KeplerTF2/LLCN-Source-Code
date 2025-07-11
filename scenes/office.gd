extends Node2D

enum CAMSTATE {DOWN, UP, GOINGDOWN, GOINGUP}
enum JUMPSCARE {FREDDY, BONNIE, CHICA, FOXYFORWARD, FOXYRIGHT, FREDBEAR}

@export var LightsOut : bool = false

var CurrentTime : int = 0
var Power : float = 100.0
var PowerConsumption : float = 0.0
var SilentPowerConsumption : float = 0.0
var TotalPowerUsed : float = 0.0
var PowerGenerated : float = 0.0
var PowerOut : bool = false
var StaticShock : bool = false

var UsingFlashLight : bool = false
var StaticGuyEntering : bool = false
var MousePos : Vector2 = Vector2(0,0)

var PowerGenUp : bool = false
var GeneratingPower : bool = false
var CanBringUpPowerGen : bool = true
var HoldingPowerGenBtn : bool = false

var CanBringUpCam : bool = true

var MouseScrollsCam : bool = false

var GlobeTrotter : bool = true
var CoveKeeper : bool = true
var FullFocus : bool = true

var PanSpeed : int = 2500
var PanSpeedMultipler : float = 0
var ShouldPan : bool = false
const PanCap : int = 480
const PanStart : float = 0.25
const PanCentre : int = 1440

var RNG : RandomNumberGenerator = RandomNumberGenerator.new()

enum LURE {OFF, LOW, MED, HIGH}
const NoLures : Dictionary = {
	1 : LURE.OFF, 2 : LURE.OFF, 3 : LURE.OFF, 4 : LURE.OFF, 5 : LURE.OFF, 
	6 : LURE.OFF, 7 : LURE.OFF, 8 : LURE.OFF, 9 : LURE.OFF, 10 : LURE.OFF,
	11 : LURE.OFF }
	

var FailingRequirement : bool = false

var JumpscareToAnimName : Dictionary = {
	JUMPSCARE.FREDDY: "freddy",
	JUMPSCARE.BONNIE: "bonnie",
	JUMPSCARE.CHICA: "chica",
	JUMPSCARE.FOXYFORWARD: "foxy",
	JUMPSCARE.FOXYRIGHT: "foxy",
	JUMPSCARE.FREDBEAR: "fredbear"
}

@export var FastPower : bool = false
@onready var StartTime : int = int(Time.get_unix_time_from_system())

@export var Tutorial : bool = false
var TutorialProgress : int = 2
var CurrentLabel : int = 1
var TSubState : Array = []
var HideButton : Array = [2,3,4,5,6,7,8,9,10]

@export var TAS : bool = false
var TimePrecise : float = 0

var WarningStagePG = 0
var WarningStageH = 0

@export var GodMode : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Black.visible = true
	InitMusic()
	if !Global.Mobile:
		if Global.Bitcrush:
			DiscordPresence(100)
		else:
			DiscordPresence(2)
	else:
		$Camera2D/Cursor.visible = true
		$Camera2D/PowerGen/Button.size.y = 54
		$Camera2D/PowerGen/Button.button_mask -= MOUSE_BUTTON_MASK_LEFT
		$Camera2D/PowerGen/Mobile.visible = true
		$Camera2D/HUD/PowerGenArea/CollisionShape2D.disabled = true
		$Camera2D/Node2D/Tutorial.position = Vector2(-2144, -404)
		$Camera2D/Node2D/Tutorial.scale = Vector2(1.25, 1.25)
		$Camera2D/Node2D/Tutorial/Texts.visible = false
		$Camera2D/Node2D/Tutorial/MobileTexts.visible = true
		#$Camera2D/PowerGen/Button.position.y = -12
	InitAI()
	FindFirstMousePos()
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	var tween = get_tree().create_tween()
	tween.tween_property($Black, "modulate:a", 0, 1.0)
	$Dark.modulate.a = 1 * int(LightsOut)
	$Camera2D/cams.LightsOut = LightsOut
	if LightsOut:
		$Camera2D/cams/Sounds/Breathing.volume_db = 10
	$Camera2D/HUD/Mobile.visible = Global.Mobile
	
	Engine.time_scale = Global.TimeScale
	
	if TAS:
		$Camera2D/HUD/TimeCheat.visible = true
		
	if Global.Bitcrush:
		HandlePowerGenVis(false)

func _physics_process(delta):
	UpdatePower(delta)
	CheckIfGenerating()
	
	if $Camera2D/CheatUI.visible:
		$Camera2D/CheatUI/Label.text = "Bonnie Move Tally: " + str($Camera2D/cams/screen/Bonnie.FailedKitchenMoves)
		$Camera2D/CheatUI/Label.text += "\n\nBonnie LOW Bag: " + str($Camera2D/cams/screen/Bonnie/LowLureBag.Bag)
		$Camera2D/CheatUI/Label.text += "\n\nChica LOW Bag: " + str($Camera2D/cams/screen/Chica/LowLureBag.Bag)
		$Camera2D/CheatUI/Label.text += "\n\nBonnie Stall Tally: : " + str($Camera2D/cams/screen/Bonnie.StalledMoves)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Global.Mobile:
		FindFirstMousePos()
	PanCamera(delta)
	MoveFlashlight()
	HandleActionInput()
	HandleInput()
	if TAS:
		TimePrecise += delta
		$Camera2D/HUD/TimeCheat.text = str(snapped(TimePrecise, 0.01) - (int(TimePrecise) / 60))

func _input(event):
	if event is InputEventMouseMotion and !Global.Mobile:
		CalculateMousePos(event)

func HandleInput():
	if Input.is_action_just_pressed("quit"):
		FailingRequirement = true
		var FadeTween = get_tree().create_tween()
		FadeTween.tween_property($Black, "modulate:a", 1, 2.0)
		FadeTween.tween_callback(ChangeSceneMenu)

func PowerOutage():
	PowerOut = true
	var tween1 = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	tween1.tween_property($Black, "modulate:a", 0.5, 15.0)
	tween2.tween_property($Dark, "modulate:a", 1.0, 15.0)
	$Sounds/PowerOut.play()
	if PowerGenUp:
		_on_power_gen_area_mouse_entered()
	if $Camera2D/cams.CamState == CAMSTATE.UP || $Camera2D/cams.CamState == CAMSTATE.GOINGUP:
		$Camera2D/cams.CloseCam()
	HandleCamVis(false)
	HandlePowerGenVis(false)
	$Camera2D/cams.RemoveAllLures()
	SetAI25()

func InitMusic():
	if Global.Bitcrush:
		$Sounds/Bitcrush.stream = load("res://assets/sounds/bitcrush/bitcrush" + str(Global.StarDiff) + ".mp3")
		$Sounds/Bitcrush.play()

func InitAI():
	Tutorial = Global.Tutorial
	$Camera2D/Node2D/Tutorial.visible = Tutorial
	$Camera2D/cams/screen/StaticGuy.Tutorial = Tutorial
	StaticShock = Global.Challenges["StaticShock"]
	LightsOut = Global.Challenges["LightsOut"]
	if LightsOut:
		$phone_guy/Button/Light.visible = true
	$Camera2D/cams/screen/Fredbear.KillerTheory = Global.Challenges["KillerTheory"]
	$freddy.HyperFreddy = Global.Challenges["HyperFreddy"]
	$Camera2D/cams/screen/springtrap.Permatrap = Global.Challenges["Permatrap"]
	$Camera2D/cams/screen/Foxy.FoxerFoxy = Global.Challenges["FoxerFoxy"]
	$phone_guy.HelloHello = Global.Challenges["HelloHello"]
	if Global.Challenges["TheParty"]:
		if Global.AIDiffs["bonnie"] > 0:
			Global.AIDiffs["bonnie"] += 5
			$Camera2D/cams/screen/Bonnie.RandomiseTimer = true
		if Global.AIDiffs["chica"] > 0:
			Global.AIDiffs["chica"] += 5
			$Camera2D/cams/screen/Chica.RandomiseTimer = true
	
	SetAnimDiff($Camera2D/cams/screen/StaticGuy, "static_guy")
	SetAnimDiff($Camera2D/cams/screen/Bonnie, "bonnie")
	SetAnimDiff($Camera2D/cams/screen/Chica, "chica")
	SetAnimDiff($Camera2D/cams/screen/Foxy, "foxy")
	SetAnimDiff($freddy, "freddy")
	SetAnimDiff($phone_guy, "phone_guy")
	SetAnimDiff($Camera2D/cams/screen/springtrap, "springtrap")
	SetAnimDiff($Camera2D/cams/screen/Fredbear, "fredbear")

func SetAI25():
	SetAnimDiffNum($Camera2D/cams/screen/Bonnie, $Camera2D/cams/screen/Bonnie.Difficulty + 5)
	SetAnimDiffNum($Camera2D/cams/screen/Chica, $Camera2D/cams/screen/Chica.Difficulty + 5)
	SetAnimDiffNum($freddy, $freddy.Difficulty + 4)
	SetAnimDiffNum($phone_guy, $phone_guy.Difficulty + 8)

func SetAnimDiff(node : Node, AnimName : String):
	if "Difficulty" in node:
		node.Difficulty = Global.AIDiffs[AnimName]
		if node.has_method("Init"):
			node.Init()

func SetAnimDiffNum(node, num : int):
	if "Difficulty" in node:
		node.Difficulty = num
		if node.has_method("Init"):
			node.Init()

func HandlePowerGenVis(value : bool):
	if PowerOut:
		value = false
	$Camera2D/HUD/PowerGenIndicator.visible = value
	$Camera2D/HUD/Mobile.visible = Global.Mobile and value
	CanBringUpPowerGen = value
	
func HandleCamVis(value : bool):
	if PowerOut:
		value = false
	$Camera2D/cams.visible = value
	CanBringUpCam = value
	$Camera2D/cams.CanBringUp = value

func HandleActionInput():
	if Input.is_action_just_pressed("light"):
		match $Camera2D/cams.CamState:
			CAMSTATE.DOWN:
				SetUsingFlashlight(!UsingFlashLight)
			CAMSTATE.GOINGDOWN:
				SetUsingFlashlight(!UsingFlashLight)

func CheckIfGenerating():
	var LastValue = GeneratingPower
	GeneratingPower = HoldingPowerGenBtn and $Camera2D/cams.LurePlacements == NoLures
	$Camera2D/PowerGen/Button.disabled = !($Camera2D/cams.LurePlacements == NoLures)
	if Global.Mobile:
		$Camera2D/PowerGen/Mobile.visible = $Camera2D/cams.LurePlacements == NoLures
	$freddy.PassInInfo($Camera2D/cams.LurePlacements, GeneratingPower, $phone_guy.Ringing, $Camera2D/cams.SendBtnHeld)
	if LastValue != GeneratingPower:
		$Sounds/PowerGenSwitch.play()
		if GeneratingPower:
			$Sounds/PowerGenOn.play()
		else:
			$Sounds/PowerGenOn.stop()

func CalculateMousePos(event):
	var viewportSize = get_viewport().get_visible_rect().size
	# Move Camera
	MousePos.x = ((event.position.x / viewportSize.x) - 0.5) * 2 # Mouse X from -1.0 to 1.0
	MousePos.y = ((event.position.y / viewportSize.y) - 0.5) * 2 # Mouse X from -1.0 to 1.0
	MousePos.x = max(-1, MousePos.x)
	MousePos.x = min(1, MousePos.x)
	MousePos.y = max(-1, MousePos.y)
	MousePos.y = min(1, MousePos.y)
	
	CalcPanSpeedMultipler()

func FindFirstMousePos():
	var viewportSize = get_viewport().get_visible_rect().size
	# Move Camera
	MousePos.x = (((get_local_mouse_position().x) / 2880.0) - 0.5) * 2 # Mouse X from -1.0 to 1.0
	MousePos.y = ((get_local_mouse_position().y / 1080.0) - 0.5) * 2 # Mouse X from -1.0 to 1.0
	MousePos.x = max(-1, MousePos.x)
	MousePos.x = min(1, MousePos.x)
	MousePos.y = max(-1, MousePos.y)
	MousePos.y = min(1, MousePos.y)
	
	CalcPanSpeedMultipler()

func SetUsingFlashlight(value : bool):
	UsingFlashLight = value
	$Flashlight.visible = value
	$Flashlight/Area2D/CollisionShape2D.disabled = !value
	$Sounds/FlashlightPress.play()
	match value:
		true:
			$Sounds/Flashlight.play()
			if $Camera2D/hallucination.Active:
				$Camera2D/hallucination.Deactivate()
				EndWarning(false)
				$Black.modulate.a = 1
				var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
				tween.tween_property($Black, "modulate:a", 0.0, 3.0)
		false:
			$Sounds/Flashlight.stop()
	
	# TUTORIAL
	if Tutorial and CurrentLabel == 2:
		ProgressTutorial(3)

func MoveFlashlight():
	var pos = get_local_mouse_position()
	$Flashlight.position = pos
	if Global.Mobile:
		$Camera2D/Cursor.position = pos - $Camera2D.position
	if LightsOut || PowerOut:
		$Dark.position = pos

func CalcPanSpeedMultipler():
	ShouldPan = abs(MousePos.x) > PanStart
	match ShouldPan:
		true:
			PanSpeedMultipler = (abs(MousePos.x) - PanStart) / (1 - PanStart) * sign(MousePos.x)
		false:
			PanSpeedMultipler = 0

# Panning the camera
func PanCamera(delta):
	if MouseScrollsCam:
		if ShouldPan and $Camera2D/cams.CamState != CAMSTATE.UP:
			$Camera2D.position.x += delta * PanSpeed * PanSpeedMultipler
			if $Camera2D.position.x > PanCentre + PanCap:
				$Camera2D.position.x = PanCentre + PanCap
			elif $Camera2D.position.x < PanCentre - PanCap:
				$Camera2D.position.x = PanCentre - PanCap
	else:
		if MousePos.x > 1:
			MousePos.x = 1
		if MousePos.x < -1:
			MousePos.x = -1
		if PlayerData.SaveData.get_meta("SmoothTurn") in [null, true]:
			$Camera2D.position = $Camera2D.position.lerp(Vector2(PanCentre + (PanCap * MousePos.x), $Camera2D.position.y), delta * 10)
		else:
			$Camera2D.position.x = PanCentre + (PanCap * MousePos.x)

func CalculatePowerConsumption():
	PowerConsumption = 0.0
	PowerConsumption += 20.0 * int($Camera2D/cams.CamState == CAMSTATE.UP)
	PowerConsumption += 20.0 * int($Camera2D/cams.LightOn)
	PowerConsumption += 20.0 * int(UsingFlashLight)
	PowerConsumption += 100.0 * int($Camera2D/hallucination.Active)
	PowerConsumption += $Camera2D/cams/screen/StaticGuy.PowerConsumption * int($Camera2D/cams.SendBtnHeld)
	for Lure in $Camera2D/cams.LurePlacements:
		if $Camera2D/cams.LurePlacements[Lure] != 0:
			PowerConsumption += 10 + (20 * $Camera2D/cams.LurePlacements[Lure])
	if $Camera2D/cams/screen/StaticGuy.EnteringOffice and StaticShock:
		PowerConsumption *= 1.5
	PowerConsumption -= 300.0 * int(GeneratingPower)
	if FastPower:
		PowerConsumption *= 2.5
	if Global.Bitcrush:
		PowerConsumption /= 3.6

func UpdatePower(delta):
	CalculatePowerConsumption()
	
	var OldPower = Power
	Power -= ((PowerConsumption + SilentPowerConsumption) * delta) / 60.0
	if PowerConsumption > 0:
		TotalPowerUsed += ((PowerConsumption + SilentPowerConsumption) * delta) / 60.0
	elif Power < 100:
		PowerGenerated -= (PowerConsumption * delta) / 60.0
	if Power < 0.0:
		Power = 0.0
		if !PowerOut and !Tutorial:
			PowerOutage()
	elif Power > 100.0:
		Power = 100.0
		
		# TUTORIAL
		if Tutorial and CurrentLabel == 6:
			ProgressTutorial(7)
	
	if Global.Bitcrush and int(OldPower) != int(Power):
		DiscordPresence(int(OldPower))
	
	var DisplayPower : int
	var DisplayConsumption : float
	if $Camera2D/hallucination.Active:
		RNG.randomize()
		DisplayPower = RNG.randi_range(0,100)
		DisplayConsumption = RNG.randf_range(0, 200)
	else:
		DisplayPower = int(Power)
		DisplayConsumption = PowerConsumption
	if FastPower:
		DisplayConsumption /= 2.5
	if Global.Bitcrush:
		DisplayConsumption *= 4.0
	$Camera2D/HUD/Power.text = str(DisplayPower) + "%"
	$Camera2D/HUD/PowerUsage.value = DisplayConsumption
	$Camera2D/HUD/PowerUsage.modulate.b = (50.0 - (DisplayConsumption/4.0)) / 50.0
	$Camera2D/HUD/PowerUsage.modulate.g = (50.0 - (DisplayConsumption/4.0)) / 25.0

func ChangeScene():
	if !Tutorial:
		get_tree().change_scene_to_file("res://scenes/endscreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/cn_menu.tscn")

func ChangeSceneMenu():
	get_tree().change_scene_to_file("res://scenes/cn_menu.tscn")

func DisplayTime():
	var minute = CurrentTime % 60
	var hour = CurrentTime / 60
	var am = (hour / 12) % 2 == 0
	
	hour %= 12
	if hour == 0:
		hour = 12
		
	minute = str(minute)
	if minute.length() == 1:
		minute = "0" + minute
	hour = str(hour)
	if hour.length() == 1:
		hour = "0" + hour
	
	match am:
		true:
			am = " AM"
		false:
			am = " PM"
			
	$Camera2D/HUD/Time.text = hour + ":" + minute + am

func PassInGlobalVars():
	Global.TotalPowerUsed = TotalPowerUsed
	Global.PowerGenerated = PowerGenerated
	Global.TimeSpent = CurrentTime

func Jumpscare(animatronic : int):
	if !StaticGuyEntering and !FailingRequirement and !GodMode:
		$Black.modulate.a = 0
		PassInGlobalVars()
		Global.Won = false
		Global.Character = JumpscareToAnimName[animatronic]
		$Camera2D.add_trauma(1)
		$Camera2D/cams.visible = false
		$Camera2D/HUD.visible = false
		$Camera2D/PowerGen.visible = false
		$Flashlight.visible = false
		$JumpTimer1.start()
		$JumpTimer2.start()
		match animatronic:
			JUMPSCARE.BONNIE:
				$Camera2D/Jumpscare.play("bonnie")
			JUMPSCARE.CHICA:
				$Camera2D/Jumpscare.play("chica")
			JUMPSCARE.FREDDY:
				$freddy.visible = false
				$Camera2D/Jumpscare.play("freddy")
			JUMPSCARE.FOXYFORWARD:
				$Camera2D/Jumpscare.play("foxymain")
			JUMPSCARE.FOXYRIGHT:
				$Camera2D/Jumpscare.play("foxysidestart")
			JUMPSCARE.FREDBEAR:
				$Camera2D/Jumpscare.play("fredbear")
				$Sounds/Jumpscare.pitch_scale = 0.5
		$Sounds/Jumpscare.play()
		get_tree().paused = true

func SpringtrapJumpscare():
	if $Camera2D/cams.CamState == CAMSTATE.UP || $Camera2D/cams.CamState == CAMSTATE.GOINGUP:
		$Camera2D/cams.CloseCam()
	$Sounds/Jumpscare.play()
	$Camera2D.add_trauma(1)
	$Camera2D/SpringtrapJump.modulate.a = 1.0
	Power -= $Camera2D/cams/screen/springtrap.PowerToDrain
	TotalPowerUsed += $Camera2D/cams/screen/springtrap.PowerToDrain
	$Camera2D/SpringtrapJump/STTimer.start()
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_property($Camera2D/SpringtrapJump, "modulate:a", 0, 2.0)

func FailFullFocus():
	if !StaticGuyEntering:
		FullFocus = false
		Global.FullFocus = false
		if Global.TrackingFullFocus and !FailingRequirement:
			Global.FailedChallenge = "FullFocus"
			$FadeLogic.FailAchievement()

func _on_cams_opened_cam():
	if UsingFlashLight:
		SetUsingFlashlight(false)
	if !Global.Bitcrush:
		HandlePowerGenVis(false)
	$phone_guy.PassInInfo(true)

func _on_cams_closed_cam():
	if !Global.Bitcrush:
		HandlePowerGenVis(true)
	$phone_guy.PassInInfo(false)

func _on_power_gen_area_mouse_entered():
	if CanBringUpPowerGen:
		$Sounds/PowerGenSlide.play()
		PowerGenUp = !PowerGenUp
		HandleCamVis(!PowerGenUp)
		if PowerGenUp:
			var PosTween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
			PosTween.tween_property($Camera2D/PowerGen, "position:y", 0, 0.5)
			$Camera2D/PowerGen/Button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			$Camera2D/PowerGen/Timer.start()
		else:
			var PosTween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
			PosTween.tween_property($Camera2D/PowerGen, "position:y", -900, 0.5)
			HoldingPowerGenBtn = false
			$Camera2D/PowerGen/Timer.stop()
			$Camera2D/PowerGen/Button.button_pressed = false
			$Camera2D/PowerGen/Button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_time_timer_timeout():
	CurrentTime += 1
	DisplayTime()
	
	if CurrentTime >= 360 and Global.Bitcrush and !Global.Won:
		BitcrushWin()

func _on_bonnie_jumpscared():
	Jumpscare(JUMPSCARE.BONNIE)

func _on_bonnie_moved():
	$BGSprite/BonnieEyes.visible = $Camera2D/cams/screen/Bonnie.CurrentCam == 8

func _on_chica_jumpscared():
	Jumpscare(JUMPSCARE.CHICA)

func _on_generate_button_down():
	HoldingPowerGenBtn = !HoldingPowerGenBtn

func _on_cams_static_guy_entering():
	StaticGuyEntering = true
	$Sounds/StaticGuyEntering.play()
	if $Camera2D/cams/screen/StaticGuy.PreviousCam == 8:
		$BGSprite/StaticGuyFrontDoor.visible = true
	elif $Camera2D/cams/screen/StaticGuy.PreviousCam == 10:
		$BGSprite/StaticGuySideDoor.visible = true
	if $Camera2D/cams/screen/StaticGuy.VisitedCams.size() != 10:
		GlobeTrotter = false
		if Global.TrackingGlobeTrotter and !FailingRequirement:
			Global.FailedChallenge = "GlobeTrotter"
			$FadeLogic.FailAchievement()
	else:
		GlobeTrotter = true
		Global.GlobeTrotter = true

func Win():
	PassInGlobalVars()
	Global.Won = true
	ChangeScene()

func _on_static_guy_entering_finished():
	var tween = get_tree().create_tween()
	tween.tween_property($Black, "modulate:a", 1.0, 1.0)
	tween.tween_callback(Win)

func BitcrushWin():
	StaticGuyEntering = true
	$Camera2D/HUD/Time.visible = false
	
	SetAnimDiffNum($Camera2D/cams/screen/Bonnie, 0)
	SetAnimDiffNum($Camera2D/cams/screen/Chica, 0)
	SetAnimDiffNum($freddy, 0)
	SetAnimDiffNum($phone_guy, 0)
	SetAnimDiffNum($Camera2D/cams/screen/Fredbear, 0)
	SetAnimDiffNum($Camera2D/cams/screen/Foxy, 0)
	SetAnimDiffNum($Camera2D/cams/screen/springtrap, 0)
	
	var tween = get_tree().create_tween()
	tween.tween_property($Black, "modulate:a", 1.0, 2.0)
	tween.tween_callback(Win)

func _on_cams_lure_changed(lure : int):
	$freddy.PassInInfo($Camera2D/cams.LurePlacements, GeneratingPower, $phone_guy.Ringing, $Camera2D/cams.SendBtnHeld)
	
	# TUTORIAL
	if Tutorial and CurrentLabel == 4:
		if !TSubState.has(lure) and lure != LURE.OFF:
			TSubState.append(lure)
			print(lure)
			print(TSubState)
		if TSubState.size() == 3:
			ProgressTutorial(5)
	
	if Tutorial and CurrentLabel == 5:
		if !DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.LOW) and !DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.MED) and !DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.HIGH):
			ProgressTutorial(6)

func _on_cams_send_btn_changed():
	$freddy.PassInInfo($Camera2D/cams.LurePlacements, GeneratingPower, $phone_guy.Ringing, $Camera2D/cams.SendBtnHeld)

func _on_freddy_jumpscared():
	Jumpscare(JUMPSCARE.FREDDY)

func StartWarning(AsPhoneguy : bool):
	if AsPhoneguy:
		$Camera2D/HUD/WarningPhoneGuy/PhoneGuyTimer.start()
		WarningStagePG = 1
		if Global.TrackingFullFocus:
			$Camera2D/HUD/WarningPhoneGuy.play("1")
			if !$Camera2D/HUD/WarningHallucination.visible:
				$Camera2D/HUD/WarningPhoneGuy.visible = true
	else:
		$Camera2D/HUD/WarningHallucination/HallucinationTimer.start()
		WarningStageH = 1
		if Global.TrackingFullFocus:
			$Camera2D/HUD/WarningHallucination.play("1")
			if !$Camera2D/HUD/WarningPhoneGuy.visible:
				$Camera2D/HUD/WarningHallucination.visible = true

func EndWarning(AsPhoneguy : bool):
	if AsPhoneguy:
		$Camera2D/HUD/WarningPhoneGuy/PGWarningTimer.stop()
		$Camera2D/HUD/WarningPhoneGuy/PhoneGuyTimer.stop()
		WarningStagePG = 0
		$Camera2D/HUD/WarningPhoneGuy.play("0")
		$Camera2D/HUD/WarningPhoneGuy.visible = false
		if WarningStageH > 0 and !$Camera2D/HUD/WarningHallucination.visible:
			$Camera2D/HUD/WarningHallucination.visible = true
	else:
		$Camera2D/HUD/WarningHallucination/HWarningTimer.stop()
		$Camera2D/HUD/WarningHallucination/HallucinationTimer.stop()
		WarningStageH = 0
		$Camera2D/HUD/WarningHallucination.play("0")
		$Camera2D/HUD/WarningHallucination.visible = false
		if WarningStagePG > 0 and !$Camera2D/HUD/WarningPhoneGuy.visible:
			$Camera2D/HUD/WarningPhoneGuy.visible = true

func _on_phone_guy_began_ringing():
	$freddy.PassInInfo($Camera2D/cams.LurePlacements, GeneratingPower, true, $Camera2D/cams.SendBtnHeld)
	StartWarning(true)

func _on_phone_guy_ended_ringing():
	$freddy.PassInInfo($Camera2D/cams.LurePlacements, GeneratingPower, false, $Camera2D/cams.SendBtnHeld)
	EndWarning(true)

func _on_springtrap_jumpscared():
	SpringtrapJumpscare()

func _on_springtrap_in_danger():
	var tween = get_tree().create_tween()
	tween.tween_property($RedModulate, "color", Color(0.5,0.25,0.25), 0.1)

func _on_springtrap_out_of_danger():
	var tween = get_tree().create_tween()
	tween.tween_property($RedModulate, "color", Color.WHITE, 0.1)

func _on_jumpscare_animation_finished():
	if $Camera2D/Jumpscare.animation == "foxysidestart":
		$Camera2D/Jumpscare.play("foxysideloop")

func _on_foxy_jumpscared():
	if $Camera2D/cams/screen/Foxy.CurrentCam == 9:
		Jumpscare(JUMPSCARE.FOXYRIGHT)
	else:
		Jumpscare(JUMPSCARE.FOXYFORWARD)

func _on_fredbear_jumpscared():
	Jumpscare(JUMPSCARE.FREDBEAR)


func _on_fredbear_hallucinate():
	if $Camera2D/cams.CamState == CAMSTATE.UP:
		$Camera2D/hallucination.Activate()
	else:
		$Camera2D/hallucination.QueueActivation()


func _on_cam_flip_sprite_animation_finished():
	if $Camera2D/hallucination.ActiveQueued and $Camera2D/cams.CamState in [CAMSTATE.UP,CAMSTATE.GOINGUP]:
		$Camera2D/hallucination.Activate()

func _on_foxy_moved():
	if $Camera2D/cams/screen/Foxy.AttemptedHallway and !StaticGuyEntering:
		CoveKeeper = false
		Global.CoveKeeper = false
		if Global.TrackingCoveKeeper and !FailingRequirement:
			Global.Character = "foxy"
			Global.FailedChallenge = "CoveKeeper"
			$FadeLogic.FailAchievement()

func DiscordPresence(Num : int):
	if Global.DiscordRPCSetup:
		var state
		if Global.Bitcrush:
			state = "Power: " + str(Num) + "%"
		elif Num == 11:
			state = "Static Guy Entering Office"
		elif Num == 10:
			state = "Static Guy: Cam " + str(Num)
		else:
			state = "Static Guy: Cam 0" + str(Num)
		
		DiscordRPC.details = "In Game: " + Global.Preset
		DiscordRPC.state = state
		DiscordRPC.large_image = "game_icon" # Image key from "Art Assets"
		DiscordRPC.large_image_text = "Static Guy!"
		DiscordRPC.small_image = ""
		DiscordRPC.small_image_text = ""
		
		DiscordRPC.start_timestamp = StartTime # "02:46 elapsed"
		# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
		
		DiscordRPC.refresh() # Always refresh after changing the values!

func _on_static_guy_moved():
	DiscordPresence($Camera2D/cams/screen/StaticGuy.CurrentCam)

func _on_static_guy_entered_office():
	DiscordPresence(11)


func _on_next_pressed():
	$Sounds/Honk.play()
	CurrentLabel += 1
	if !Global.Mobile:
		for i : Label in $Camera2D/Node2D/Tutorial/Texts.get_children():
			i.visible = i.name == str(CurrentLabel)
	else:
		for i : Label in $Camera2D/Node2D/Tutorial/MobileTexts.get_children():
			i.visible = i.name == str(CurrentLabel)
	if HideButton.has(CurrentLabel) and !CheckAlreadyDoingTutorialTask():
		$Camera2D/Node2D/Tutorial/Next.visible = false
	if CurrentLabel > 12:
		GameJolt.trophies_add_achieved(GjId.Tutorial)
		$Camera2D/Node2D/Tutorial.visible = false
		$Camera2D/cams/screen/StaticGuy._on_office_timer_timeout()

func _on_cams_used_light():
	# TUTORIAL
	if Tutorial and CurrentLabel == 3:
		ProgressTutorial(4)

func ProgressTutorial(newNum):
	$Camera2D/Node2D/Tutorial/Next.visible = true
	TutorialProgress = newNum
	TSubState = []

func CheckAlreadyDoingTutorialTask() -> bool:
	var returnValue : bool = false
	match CurrentLabel:
		2:
			returnValue = UsingFlashLight
		3:
			returnValue = $Camera2D/cams.LightOn
		4:
			returnValue = DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.LOW) and DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.MED) and DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.HIGH)
		5:
			returnValue = !DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.LOW) and !DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.MED) and !DictionaryHasValue($Camera2D/cams.LurePlacements, LURE.HIGH)
		6:
			returnValue = Power == 100
		7:
			returnValue = $Camera2D/cams.CurrentCam == 2
		8:
			returnValue = $Camera2D/cams.CurrentCam == 5
		9:
			returnValue = $Camera2D/cams/screen/StaticGuy.CurrentCam == 5
		10:
			returnValue = $Camera2D/cams/screen/StaticGuy.CurrentCam == 8
			
	return returnValue

func DictionaryHasValue(dict : Dictionary, value) -> bool:
	for i in dict:
		if dict[i] == value:
			return true
	return false

func _on_cams_changed_cam():
	# TUTORIAL
	if Tutorial and CurrentLabel == 7:
		if $Camera2D/cams.CurrentCam == 2:
			ProgressTutorial(8)
	
	elif Tutorial and CurrentLabel == 8:
		if $Camera2D/cams.CurrentCam == 5:
			ProgressTutorial(9)

func _on_cams_static_guy_moved():
	# TUTORIAL
	if Tutorial and CurrentLabel == 9:
		if $Camera2D/cams/screen/StaticGuy.CurrentCam == 5:
			ProgressTutorial(10)
	
	if Tutorial and CurrentLabel == 10:
		if $Camera2D/cams/screen/StaticGuy.CurrentCam == 8:
			ProgressTutorial(11)

func _on_light_pressed():
	#match $Camera2D/cams.CamState:
	#	CAMSTATE.DOWN:
	#		SetUsingFlashlight(!UsingFlashLight)
	#	CAMSTATE.GOINGDOWN:
	#		SetUsingFlashlight(!UsingFlashLight)
	pass

func _on_back_pressed():
	FailingRequirement = true
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "modulate:a", 1, 2.0)
	FadeTween.tween_callback(ChangeSceneMenu)


func _on_powergen_timer_timeout():
	$Camera2D/PowerGen/Button.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_phone_guy_timer_timeout():
	$Camera2D/HUD/WarningPhoneGuy/PGWarningTimer.start()

func _on_hallucination_timer_timeout():
	$Camera2D/HUD/WarningHallucination/HWarningTimer.start()


func _on_pg_warning_timer_timeout():
	WarningStagePG += 1
	if WarningStagePG > 3:
		if Global.TrackingFullFocus:
			Global.Character = "phone_guy"
		FailFullFocus()
	elif Global.TrackingFullFocus:
		$Camera2D/HUD/WarningPhoneGuy.play(str(WarningStagePG))


func _on_h_warning_timer_timeout():
	WarningStageH += 1
	if WarningStageH > 3:
		if Global.TrackingFullFocus:
			Global.Character = "fredbear"
		FailFullFocus()
	elif Global.TrackingFullFocus:
		$Camera2D/HUD/WarningHallucination.play(str(WarningStageH))


func _on_hallucination_activated():
	StartWarning(false)

func _on_st_timer_timeout():
	if Global.TrackingFullFocus:
		Global.Character = "springtrap"
	FailFullFocus()


func _on_mobile_power_gen_btn_button_down() -> void:
	_on_power_gen_area_mouse_entered()


func _on_mobile_pressed() -> void:
	_on_generate_button_down()
	$Camera2D/PowerGen/Button.button_pressed = !$Camera2D/PowerGen/Button.button_pressed
