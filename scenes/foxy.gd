extends CamAnimatronic

enum FOXY {COVE, HOOK, LEFT, RIGHT, HALLWAYLEFT, HALLWAYRIGHT}

@export var FoxerFoxy : bool = false

var StalledInCove : bool = false
var CoveTimer : float = 0
var MaxCoveTimer : float = 25
var CameraUp : bool = false
var AttemptedHallway : bool = false

func _physics_process(delta):
	UpdateCoveTimer(delta)

# Called when the node enters the scene tree for the first time.
func Init():
	if Global.Bitcrush:
		$FootstepsCove.volume_db = 12.5
		$FootstepsHallway.stream = load("res://assets/sounds/running.mp3")
		$FootstepsHallway.volume_db = 7.5
	State = FOXY.COVE
	CalcCoveTimer()
	$MixedBag.InitialBag = []
	$MixedBag.PopulateInitialBag(true, 5)
	$MixedBag.PopulateInitialBag(false, 5)
	$MixedBag.RefillBag()

func PassInCamUp(value:bool):
	CameraUp = value

func PassInInfo(lures : Dictionary, cam : int):
	super.PassInInfo(lures, cam)
	if Global.Bitcrush and (State in [FOXY.COVE, FOXY.HOOK, FOXY.LEFT, FOXY.RIGHT] and (CamLures[5] in [LURE.MED, LURE.HIGH])):
		StalledInCove = true
	elif !Global.Bitcrush and (State in [FOXY.COVE, FOXY.HOOK, FOXY.LEFT, FOXY.RIGHT] and (cam == 5 or CamLures[5] in [LURE.MED, LURE.HIGH])):
		StalledInCove = true
	else:
		StalledInCove = false
	
	if cam == CurrentCam and State in [FOXY.HALLWAYLEFT, FOXY.HALLWAYRIGHT]:
		if CamLures[cam] in [LURE.OFF, LURE.LOW]:
			$SameCamTimer.stop()
			$KillTimer.stop()
			$CamTimer.start()
		else:
			$SameCamTimer.stop()
			$KillTimer.stop()
			$CamTimer.stop()
			$FootstepsHallway.stop()
			SetCam(5)
			State = FOXY.COVE
			SetSprite(5)
			Moved.emit()

func UpdateCoveTimer(delta : float):
	if Difficulty != 0 and State in [FOXY.HOOK, FOXY.COVE, FOXY.LEFT, FOXY.RIGHT]:
		if !StalledInCove:
			CoveTimer += delta
		elif !FoxerFoxy:
			CoveTimer -= delta * (MaxCoveTimer / 5.0)
		
		if CoveTimer < 0:
			CoveTimer = 0
			if State == FOXY.HOOK:
				State = FOXY.COVE
				if CameraUp and PlayerCam == 5:
					$Fabric.play()
			SetCam(5)
		elif CoveTimer > MaxCoveTimer:
			CoveTimer = 0
			Move()
		
		if CoveTimer > 0 and State == FOXY.COVE:
			State = FOXY.HOOK
			SetCam(5)

func Move():
	if State in [FOXY.COVE, FOXY.HOOK]:
		if $MixedBag.GetItem():
			$FootstepsCove.position.x = 960
			State = FOXY.LEFT
		else:
			$FootstepsCove.position.x = 1920
			State = FOXY.RIGHT
		$FootstepsCove.play()
		SetCam(5)
	elif State == FOXY.LEFT:
		AttemptedHallway = true
		SetCam(8)
		SetSprite(8)
		State = FOXY.HALLWAYLEFT
		$FootstepsHallway.position.x = 960
		$FootstepsHallway.play()
		if PlayerCam == 8:
			$SameCamTimer.start()
		else:
			$KillTimer.start()
	elif State == FOXY.RIGHT:
		AttemptedHallway = true
		SetCam(9)
		SetSprite(9)
		State = FOXY.HALLWAYRIGHT
		$FootstepsHallway.position.x = 1920
		$FootstepsHallway.play()
		if PlayerCam == 9:
			$SameCamTimer.start()
		else:
			$KillTimer.start()
			
	if State in [FOXY.HALLWAYLEFT, FOXY.HALLWAYRIGHT]:
		if CamLures[CurrentCam] in [LURE.MED, LURE.HIGH]:
			$SameCamTimer.stop()
			$KillTimer.stop()
			$CamTimer.stop()
			SetCam(5)
			State = FOXY.COVE
			SetSprite(5)
			
	Moved.emit()
	if Global.Minus3Strat:
		Global.Minus3Strat = false
		print("Failed -3 Strat")

func SetSprite(cam : int):
	var animToPlay = str(cam)
	if cam == 5:
		match State:
			FOXY.HOOK:
				animToPlay = "5hook"
			FOXY.LEFT:
				animToPlay = "5left"
			FOXY.RIGHT:
				animToPlay = "5right"
	$Sprites.play(animToPlay)

func SetSpriteVis(value : bool):
	Sprites.visible = value and PlayerCam == CurrentCam

func CalcCoveTimer():
	MaxCoveTimer = 25 - Difficulty
	if Global.Bitcrush:
		MaxCoveTimer = 5 * (0.8 ** (Global.StarDiff - 1))
		$KillTimer.wait_time = MaxCoveTimer

func _on_kill_timer_timeout():
	Jumpscared.emit()

func _on_cam_timer_timeout():
	Jumpscared.emit()
