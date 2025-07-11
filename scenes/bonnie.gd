extends CamAnimatronic

var CamTree : Dictionary = {
	1: [3, 4],
	3: [4, 7],
	4: [3, 7],
	7: [8],
	8: [11],
	11: [1]
}
var LowLureCamTree : Dictionary = {
	1: [3, 4],
	3: [1, 4, 7],
	4: [1, 3, 7],
	7: [8],
	8: [4, 7],
	11: []
}
var StalledTimer : bool = false
var StalledMoves : int = 0
var FailedKitchenMoves : int = 0
var MovementBlocked : bool = false
var PotentialLowLures : Array = []
@export var RandomiseTimer : bool = false
var RNG : RandomNumberGenerator = RandomNumberGenerator.new()
var SoundCache : Array = [
	null, null, null
] # Array is filled on InitSoundCache


# Called when the node enters the scene tree for the first time.
func Init():
	if Difficulty > 0 and Global.Bitcrush:
		Difficulty += 5
	SetTimer()
	$Timer.start()
	$MixedBag.InitialBag = []
	$MixedBag.PopulateInitialBag(true, Difficulty)
	$MixedBag.PopulateInitialBag(false, 25 - Difficulty)
	$MixedBag.RefillBag()
	InitSoundCache()

func InitSoundCache():
	for i in range(3):
		SoundCache[i] = load("res://assets/sounds/bonnie/metalwalk" + str(i + 1) + ".mp3")

func PassInInfo(lures : Dictionary, cam : int):
	super.PassInInfo(lures, cam)
	if CamLures[CurrentCam] == LURE.MED and !StalledTimer:
		StalledTimer = true
	elif CamLures[CurrentCam] != LURE.MED and StalledTimer:
		StalledTimer = false

func SetSprite(cam : int):
	$Sprites.play(str(cam))
	$SpritesEyes.play(str(cam))

func CheckForLowLures():
	PotentialLowLures = []
	for Cam in LowLureCamTree[CurrentCam]:
		if CamLures[Cam] == LURE.LOW:
			PotentialLowLures.append(Cam)
	return !PotentialLowLures.is_empty()

func Move():
	CheckForLowLures()
	if Difficulty != 0 and ($MixedBag.GetItem() || CheckForLowLures() || CamLures[CurrentCam] == LURE.HIGH):
		var NextCam : int
		if CheckForLowLures() and $LowLureBag.GetItem():
			NextCam = PotentialLowLures.pick_random()
		elif CurrentCam == 8 and CamLures[CurrentCam] == LURE.HIGH:
			NextCam = $MainHallFailBag.GetItem()
		else:
			NextCam = CamTree[CurrentCam].pick_random()
			
			if FailedKitchenMoves == 3:
				NextCam = 7
				FailedKitchenMoves = 0
				
			if NextCam < 7:
				FailedKitchenMoves += 1
			else:
				FailedKitchenMoves = 0
			
		if StalledTimer:
			StalledMoves += 1
			if StalledMoves == 3:
				StalledMoves = 0
		else:
			StalledMoves = 0
			
		if StalledMoves == 0 and CamLures[NextCam] != LURE.HIGH:
			SetCam(NextCam)
			if Global.Minus3Strat:
				Global.Minus3Strat = false
			if NextCam == 8 and Global.LifeOnEdge:
				Global.LifeOnEdge = false
			if NextCam == 11:
				Jumpscared.emit()
			else:
				$Footsteps.volume_db = CurrentCam * 2 - 15.0
				$Footsteps.stream = SoundCache.pick_random()
				$Footsteps.play()
			Moved.emit()

func _on_timer_timeout():
	TimeOut.emit()
	SetTimer()

func SetTimer():
	if RandomiseTimer:
		$Timer.wait_time = RNG.randf_range(4.0, 5.0)
	elif Global.Bitcrush:
		$Timer.wait_time = RNG.randf_range(4.5 * (0.75 ** (Global.StarDiff - 1)), 5 * (0.75 ** (Global.StarDiff - 1)))
