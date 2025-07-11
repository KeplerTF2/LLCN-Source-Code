extends Node2D

enum CAMSTATE {DOWN, UP, GOINGDOWN, GOINGUP}
var CamState : int = CAMSTATE.DOWN
var CanBringUp = true
var CurrentCam : int = 1

var LightOn : bool = false

var SendBtnHeld : bool = false
var CancelBtnHeld : bool = false
var CancelProgress : float = 0.0 # Max of 1.0

var Springtrapped : bool = false

enum LURE {OFF, LOW, MED, HIGH}
var LurePlacements : Dictionary = {
	1 : LURE.OFF, 2 : LURE.OFF, 3 : LURE.OFF, 4 : LURE.OFF, 5 : LURE.OFF, 
	6 : LURE.OFF, 7 : LURE.OFF, 8 : LURE.OFF, 9 : LURE.OFF, 10 : LURE.OFF,
	11: LURE.OFF }
var CanChangeLure : bool = true

var LightsOut : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	SetUpCamSignals()
	if Global.Mobile:
		SetupMobileControls()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	CheckIfSendingStaticGuy(delta)
	HandleCancelBtn(delta)

func _process(delta):
	HandleActionInput()

func HandleActionInput():
	if Input.is_action_just_pressed("flipcam") and CanBringUp:
		ToggleCam()
	if Input.is_action_just_pressed("light") and (CamState == CAMSTATE.UP || CamState == CAMSTATE.GOINGUP):
		SetLight(!LightOn)
	if (CamState == CAMSTATE.UP || CamState == CAMSTATE.GOINGUP):
		if Input.is_action_just_pressed("high"):
			SetAudioLure(LURE.HIGH)
		if Input.is_action_just_pressed("med"):
			SetAudioLure(LURE.MED)
		if Input.is_action_just_pressed("low"):
			SetAudioLure(LURE.LOW)
		if Input.is_action_just_pressed("off"):
			SetAudioLure(LURE.OFF)

func SetupMobileControls():
	$screen/Map.scale = Vector2(14,14)
	$screen/Map.position = Vector2(1576,736)
	$screen/HUD/mobile.visible = true
	$screen/HUD/mobile/low.modulate = Global.LowColour
	$screen/HUD/mobile/med.modulate = Global.MedColour
	$screen/HUD/mobile/high.modulate = Global.HighColour
	$screen/HUD/mobile/light.visible = !Global.Challenges["LightsOut"]
	$FlipArea/CollisionShape2D.disabled = true
	$cameras.visible = true
	$screen/HUD/SendBtn.size.y = 36
	$screen/HUD/SendBtn/Button.size.y = 36
	$screen/HUD/SendBtn/Label.size.y = 72
	$screen/HUD/SendBtn/Mobile.visible = true
	$screen/HUD/SendBtn/Button.button_mask -= MOUSE_BUTTON_MASK_LEFT

func SetUpCamSignals():
	for CamButton : Button in $screen/Map/Buttons.get_children():
		var num = int(CamButton.text)
		if !Global.Mobile:
			CamButton.button_down.connect(_on_cam_button_pressed.bind(num))
		else:
			CamButton.button_mask -= MOUSE_BUTTON_MASK_LEFT
			var MobileButton = TouchScreenButton.new()
			MobileButton.position = Vector2(18, 12.5)
			MobileButton.shape = RectangleShape2D.new()
			MobileButton.shape.size = Vector2(36, 25)
			MobileButton.pressed.connect(_on_cam_button_pressed.bind(num))
			CamButton.add_child(MobileButton)

func _on_cam_button_pressed(num : int):
	SwitchCam(num)

func SwitchCam(num : int):
	var prevCam = CurrentCam
	CurrentCam = num
	if prevCam != CurrentCam:
		SendBtnHeld = false
		SendBtnChanged.emit()
	$screen/AudioOnly.visible = num == 7
	HandleStaticGuyHUD(num)
	HandleSpringtrap()
	$screen/Foxy.PassInInfo(LurePlacements, num)
	$screen/Foxy.SetSpriteVis(LightOn)
	$screen/Fredbear.SetSpriteVis(LightOn and num == 3)
	$screen/LoadAnim.stop()
	$screen/LoadAnim.play()
	$Sounds/CamSwitch.play()
	$screen/BG.animation = str(num)
	DisplayCurrentLure()
	SetAnimatronicVis()
	ChangedCam.emit()

func HandleCancelBtn(delta : float):
	if CancelBtnHeld:
		CancelProgress += delta
		if CancelProgress >= 1.0:
			CancelProgress = 0.0
			CancelBtnHeld = false
			
			$screen/StaticGuy.CancelProgress()
			$Sounds/CancelProgress.play()
			if $screen/StaticGuy.CurrentCam == 8 || $screen/StaticGuy.CurrentCam == 10:
				$screen/StaticGuy.StartEnterOffice()
		$screen/HUD/CancelBtn.value = CancelProgress

func HandleStaticGuyHUD(cam : int):
	$screen/StaticGuy.PassInInfo(cam)
	$screen/StaticGuy.SetSpriteVis($screen/StaticGuy.CurrentCam == cam)
	$screen/HUD/CancelBtn.visible = $screen/StaticGuy.CurrentCam == cam
	$screen/HUD/SendBtn.visible = $screen/StaticGuy.CamTree[$screen/StaticGuy.CurrentCam].has(cam)
	$screen/HUD/SendBtn.value = $screen/StaticGuy.SendProgress[cam]
	$Sounds/StaticGuySound.playing = (Springtrapped || $screen/StaticGuy.CurrentCam == cam) and (CamState == CAMSTATE.GOINGUP || CamState == CAMSTATE.UP)

func HandleSpringtrap():
	$screen/OpaqueStatic.visible = Springtrapped
	$Sounds/StaticGuySound.playing = (Springtrapped || $screen/StaticGuy.CurrentCam == CurrentCam) and (CamState == CAMSTATE.GOINGUP || CamState == CAMSTATE.UP)
	if Springtrapped:
		$Sounds/Breathing.volume_db = -80
	else:
		$Sounds/Breathing.volume_db = 5 + (5 * int(LightsOut))

func CheckIfSendingStaticGuy(delta : float):
	if SendBtnHeld:
		if !$Sounds/MovingStaticGuy.playing:
			$Sounds/MovingStaticGuy.play()
		$screen/StaticGuy.AddProgress(CurrentCam, delta)
		if $screen/StaticGuy.SendProgress[CurrentCam] >= $screen/StaticGuy.MaxSendProgress:
			$screen/StaticGuy.Move(CurrentCam)
			if CurrentCam != 8 and CurrentCam != 10:
				$screen/StaticGuy.CancelEnterOffice()
			HandleStaticGuyHUD(CurrentCam)
			DisplayAnimMove()
			SendBtnHeld = false
			SendBtnChanged.emit()
		$screen/HUD/SendBtn.value = $screen/StaticGuy.SendProgress[CurrentCam]
	else:
		$Sounds/MovingStaticGuy.stop()

func SetAudioLure(LureValue : int):
	if CanChangeLure:
		LurePlacements[CurrentCam] = LureValue
		DisplayCurrentLure()
		$screen/Foxy.PassInInfo(LurePlacements, CurrentCam)
		$screen/Fredbear.PassInInfo(LurePlacements[3])
		LureChanged.emit(LureValue)
		
		if LureValue == LURE.HIGH and CurrentCam != 3 and Global.ColourBlind:
			Global.ColourBlind = false

func SetIfCanPlaceLure(value : bool):
	CanChangeLure = value
	if value:
		$screen/HUD/AudioLure.self_modulate = Color.WHITE
	elif !value:
		$screen/HUD/AudioLure.self_modulate = Color.DIM_GRAY

func DisplayCurrentLure():
	$Sounds/AudioLure.play()
	var Colour : Color
	match LurePlacements[CurrentCam]:
		LURE.OFF:
			Colour = Color.WHITE
			$Sounds/AudioLure.stop()
			$screen/HUD/AudioLure.text = "Audio Lure: NONE"
		LURE.LOW:
			Colour = Global.LowColour
			$Sounds/AudioLure.pitch_scale = 0.5
			$screen/HUD/AudioLure.text = "Audio Lure: LOW"
		LURE.MED:
			Colour = Global.MedColour
			$Sounds/AudioLure.pitch_scale = 1.0
			$screen/HUD/AudioLure.text = "Audio Lure: MED"
		LURE.HIGH:
			Colour = Global.HighColour
			$Sounds/AudioLure.pitch_scale = 1.5
			$screen/HUD/AudioLure.text = "Audio Lure: HIGH"
	$screen/HUD/AudioLure.modulate = Colour
	var buttonnode = get_node("screen/Map/Buttons/" + str(CurrentCam))
	buttonnode.modulate = Colour

func DisplayLure(num : int):
	$Sounds/AudioLure.play()
	var Colour : Color
	match LurePlacements[num]:
		LURE.OFF:
			Colour = Color.WHITE
			$Sounds/AudioLure.stop()
			$screen/HUD/AudioLure.text = "Audio Lure: NONE"
		LURE.LOW:
			Colour = Global.LowColour
			$Sounds/AudioLure.pitch_scale = 0.5
			$screen/HUD/AudioLure.text = "Audio Lure: LOW"
		LURE.MED:
			Colour = Global.MedColour
			$Sounds/AudioLure.pitch_scale = 1.0
			$screen/HUD/AudioLure.text = "Audio Lure: MED"
		LURE.HIGH:
			Colour = Global.HighColour
			$Sounds/AudioLure.pitch_scale = 1.5
			$screen/HUD/AudioLure.text = "Audio Lure: HIGH"
	if num == CurrentCam:
		$screen/HUD/AudioLure.modulate = Colour
	var buttonnode = get_node("screen/Map/Buttons/" + str(num))
	buttonnode.modulate = Colour

func RemoveAllLures():
	LurePlacements = {
	1 : LURE.OFF, 2 : LURE.OFF, 3 : LURE.OFF, 4 : LURE.OFF, 5 : LURE.OFF, 
	6 : LURE.OFF, 7 : LURE.OFF, 8 : LURE.OFF, 9 : LURE.OFF, 10 : LURE.OFF,
	11: LURE.OFF }

func SetLight(value : bool):
	if !LightsOut:
		LightOn = value
		$screen/BG.visible = value
		$screen/Bonnie.SetSpriteVis(value)
		$screen/Chica.SetSpriteVis(value)
		$screen/Foxy.SetSpriteVis(value)
		$screen/Fredbear.SetSpriteVis(value and CurrentCam == 3)
		match value:
			true:
				$Sounds/Light.play()
			false:
				$Sounds/Light.stop()
		UsedLight.emit()

func ToggleCam():
	if CamState == CAMSTATE.GOINGDOWN || CamState == CAMSTATE.DOWN:
		OpenCam()
	elif CamState == CAMSTATE.GOINGUP || CamState == CAMSTATE.UP:
		CloseCam()

func OpenCam():
	OpenedCam.emit()
	CamState = CAMSTATE.GOINGUP
	$CamFlipSprite.play("up")
	$Sounds/CamFlipFull.play()
	DisplayCurrentLure()
	SetAnimatronicBreathing()
	HandleStaticGuyHUD(CurrentCam)
	HandleSpringtrap()
	$screen/springtrap.PassInInfo(true)
	$screen/Foxy.PassInCamUp(true)

func CloseCam():
	ClosedCam.emit()
	CamState = CAMSTATE.GOINGDOWN
	$CamFlipSprite.play("down")
	$screen.visible = false
	$Sounds/CamStatic.stop()
	$Sounds/CamFlipShort.play()
	$Sounds/CamFlipFull.stop()
	$Sounds/AudioLure.stop()
	SetAnimatronicBreathing()
	HandleStaticGuyHUD(CurrentCam)
	HandleSpringtrap()
	$screen/springtrap.PassInInfo(false)
	$screen/Foxy.PassInCamUp(false)
	SendBtnHeld = false
	SendBtnChanged.emit()
	if LightOn:
		SetLight(false)

func SetAnimatronicVis():
	$screen/Bonnie.visible = $screen/Bonnie.CurrentCam == CurrentCam
	$screen/Chica.visible = $screen/Chica.CurrentCam == CurrentCam
	$screen/Foxy.visible = $screen/Foxy.CurrentCam == CurrentCam
	SetAnimatronicBreathing()

func SetAnimatronicBreathing():
	if (CamState == CAMSTATE.UP || CamState == CAMSTATE.GOINGUP) and ($screen/Bonnie.visible || $screen/Chica.visible):
		$Sounds/Breathing.play()
	else:
		$Sounds/Breathing.stop()

func DisplayAnimMove():
	if CamState == CAMSTATE.GOINGUP || CamState == CAMSTATE.UP:
		$screen/LoadAnim.stop()
		$screen/LoadAnim.play()
		$Sounds/AnimMoveStatic.play()

func _on_cam_flip_sprite_animation_finished():
	match CamState:
		CAMSTATE.GOINGUP:
			CamState = CAMSTATE.UP
			$screen.visible = true
			$Sounds/CamStatic.play()
			$screen/LoadAnim.stop()
			$screen/LoadAnim.play()
		CAMSTATE.GOINGDOWN:
			CamState = CAMSTATE.DOWN


func _on_flip_area_mouse_entered():
	ToggleCam()

func _on_bonnie_time_out():
	$screen/Bonnie.PassInInfo(LurePlacements, CurrentCam)
	$screen/Bonnie.Move()
	SetAnimatronicVis()

func _on_bonnie_moved():
	if $screen/Bonnie.CurrentCam == CurrentCam || $screen/Bonnie.PreviousCam == CurrentCam:
		DisplayAnimMove()

func _on_chica_moved():
	if $screen/Chica.CurrentCam == CurrentCam || $screen/Chica.PreviousCam == CurrentCam:
		DisplayAnimMove()

func _on_chica_time_out():
	$screen/Chica.PassInInfo(LurePlacements, CurrentCam)
	$screen/Chica.Move()
	SetAnimatronicVis()

func _on_static_guy_moved():
	StaticGuyMoved.emit()

func _on_static_guy_entered_office():
	StaticGuyEntering.emit()

func _on_send_button_down():
	SendBtnHeld = !SendBtnHeld
	SendBtnChanged.emit()
	$Sounds/CamSwitch.play()

func _on_cancel_button_down():
	CancelBtnHeld = true

func _on_cancel_button_up():
	CancelBtnHeld = false
	CancelProgress = 0.0
	$screen/HUD/CancelBtn.value = 0.0

func _on_phone_guy_disabled_audio_lures():
	SetIfCanPlaceLure(false)

func _on_phone_guy_reenabled_audio_lures():
	SetIfCanPlaceLure(true)

func _on_springtrap_jumpscared():
	Springtrapped = true

func _on_springtrap_restore_cams():
	Springtrapped = false
	HandleSpringtrap()

func _on_foxy_moved():
	if $screen/Foxy.CurrentCam == CurrentCam || $screen/Foxy.PreviousCam == CurrentCam:
		DisplayAnimMove()
		SetAnimatronicVis()
		$screen/Foxy.SetSpriteVis(LightOn)

func _on_fredbear_moved():
	if $screen/Fredbear.Cam == CurrentCam:
		DisplayAnimMove()
	if $screen/Fredbear.Attacking and $screen/Fredbear.KillerTheory:
		LurePlacements[3] = LURE.OFF
		DisplayLure(3)
		$screen/Fredbear.PassInInfo(LurePlacements[3])
		LureChanged.emit(LURE.OFF)
	$screen/Fredbear.SetSpriteVis(CurrentCam == 3 and LightOn)

func _on_off_pressed():
	SetAudioLure(LURE.OFF)
	$Sounds/CamSwitch.play()

func _on_low_pressed():
	SetAudioLure(LURE.LOW)
	$Sounds/CamSwitch.play()

func _on_med_pressed():
	SetAudioLure(LURE.MED)
	$Sounds/CamSwitch.play()

func _on_high_pressed():
	SetAudioLure(LURE.HIGH)
	$Sounds/CamSwitch.play()

func _on_light_pressed():
	if (CamState == CAMSTATE.UP || CamState == CAMSTATE.GOINGUP):
		SetLight(!LightOn)

func _on_cameras_button_down() -> void:
	_on_flip_area_mouse_entered()

signal OpenedCam
signal ClosedCam
signal StaticGuyEntering
signal LureChanged
signal SendBtnChanged
signal UsedLight
signal ChangedCam
signal StaticGuyMoved
