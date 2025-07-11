extends CamAnimatronic

var CamTree : Dictionary = {
	1: [4],
	4: [1, 5],
	5: [4, 6, 9],
	6: [5, 9],
	9: [5, 6, 10],
	10: [11],
	11: [1]
}
var ForwardCamTree : Dictionary = {
	1: 4,
	4: 5,
	5: 6,
	6: 9,
	9: 10,
	10: 11,
	11: 11
}
var StalledTimer : bool = false
var StalledMoves : int = 0
var MovementBlocked : bool = false
var PotentialLowLures : Array = []
@export var RandomiseTimer : bool = false
var RNG : RandomNumberGenerator = RandomNumberGenerator.new()
var SoundCache : Array = [
	null, null, null, null,
	null, null, null, null
] # Array is filled on InitSoundCache()

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

func PassInInfo(lures : Dictionary, cam : int):
	super.PassInInfo(lures, cam)
	if CamLures[CurrentCam] == LURE.MED and !StalledTimer:
		StalledTimer = true
	elif CamLures[CurrentCam] != LURE.MED and StalledTimer:
		StalledTimer = false

func CheckForLowLures():
	PotentialLowLures = []
	for Cam in CamTree[CurrentCam]:
		if CamLures[Cam] == LURE.LOW:
			PotentialLowLures.append(Cam)
	return !PotentialLowLures.is_empty()

func Move():
	CheckForLowLures()
	if Difficulty != 0 and ($MixedBag.GetItem() || CheckForLowLures() || CamLures[CurrentCam] == LURE.HIGH || (CamLures[10] == LURE.HIGH and CurrentCam == 9)):
		var NextCam : int
		if CheckForLowLures() and $LowLureBag.GetItem():
			NextCam = PotentialLowLures.pick_random()
		elif CurrentCam == 9 and CamLures[10] == LURE.HIGH:
			NextCam = $MainHallFailBag.GetItem()
		elif CurrentCam == 10 and CamLures[10] == LURE.HIGH:
			NextCam = 10
		else:
			NextCam = ForwardCamTree[CurrentCam]
			
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
			if NextCam == 11:
				Jumpscared.emit()
			
			if NextCam != 11:
				$Footsteps.volume_db = CurrentCam * 2.5 - 25.0
				$Footsteps.pitch_scale = (CurrentCam / 20.0) + 0.75
				$Footsteps.stream = SoundCache.pick_random()
				$Footsteps.play()
				
			Moved.emit()
		elif CurrentCam != 10 and Global.LifeOnEdge:
			Global.LifeOnEdge = false

func InitSoundCache():
	for i in range(8):
		SoundCache[i] = load("res://assets/sounds/chica/retro/" + str(i) + ".wav")

func _on_timer_timeout():
	TimeOut.emit()
	SetTimer()

func SetTimer():
	if RandomiseTimer:
		$Timer.wait_time = RNG.randf_range(4.0, 5.0)
	elif Global.Bitcrush:
		$Timer.wait_time = RNG.randf_range(4.5 * (0.75 ** (Global.StarDiff - 1)), 5 * (0.75 ** (Global.StarDiff - 1)))
