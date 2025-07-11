extends Node2D

@export var Difficulty : int
@export var HelloHello : bool = false
var Ringing : bool = false
var LuresDisabled : bool = false
var RNG : RandomNumberGenerator = RandomNumberGenerator.new()
var TimeOnCams : float = 0.0
var OnCams : bool = false

# Called when the node enters the scene tree for the first time.
func Init():
	$MixedBag.InitialBag = []
	$MixedBag.PopulateInitialBag(true, Difficulty)
	$MixedBag.PopulateInitialBag(false, 40 - Difficulty)
	$MixedBag.RefillBag()
	if Difficulty != 0:
		SetTimer()
		$Timer.start()
	if Global.Mobile:
		$Button/Mobile.visible = true
		$Button.button_mask -= MOUSE_BUTTON_MASK_LEFT
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	UpdateTimeOnCams(delta)
	if Global.Bitcrush:
		MoveAway(delta)

func MoveAway(delta: float):
	var viewportSize = get_viewport().get_visible_rect().size
	var LocalMousePos = (get_viewport().get_mouse_position() / viewportSize) * Vector2(2880, 1080)
	var DistVector = (LocalMousePos - Vector2(96, 34)).direction_to($Button.global_position) * (500 - (LocalMousePos - Vector2(96, 34)).distance_to($Button.global_position)) * 0.2 * Global.StarDiff

	position += DistVector * delta
	position.x = max(min(position.x, 2880 - 192), 0)
	position.y = max(min(position.y, 987 - 68), 0)

func PassInInfo(OnCamera : bool):
	OnCams = OnCamera
	$Button.visible = !OnCams and Ringing
	$Button.disabled = OnCams

func UpdateTimeOnCams(delta : float):
	if OnCams:
		TimeOnCams += delta
	else:
		TimeOnCams -= delta
	if TimeOnCams < 0:
		TimeOnCams = 0
	if TimeOnCams > 20:
		TimeOnCams = 20

func Activate():
	Ringing = true
	BeganRinging.emit()
	RNG.randomize()
	if RNG.randi_range(0,200) == 100:
		$CoolerSong.play()
		GameJolt.trophies_add_achieved(GjId.SecretSong)
	else:
		$Song.play()
	if HelloHello:
		position.x = RNG.randi_range(576,2496)
		position.y = RNG.randi_range(192,832)
	$DisableTimer.start()
	if !OnCams:
		$Button.visible = true
	$Timer.stop()

func Deactivate():
	Ringing = false
	EndedRinging.emit()
	$TurnOff.play()
	$Timer.start()
	$DisableTimer.stop()
	$Button.visible = false
	$Song.stop()
	$CoolerSong.stop()
	if LuresDisabled:
		LuresDisabled = false
		ReenabledAudioLures.emit()

func _on_timer_timeout():
	if $MixedBag.GetItem():
		Activate()
	else:
		RNG.randomize()
		if TimeOnCams * RNG.randf_range(0, 1) >= 25 - Difficulty:
			Activate()

func _on_song_finished():
	Deactivate()

func _on_disable_timer_timeout():
	LuresDisabled = true
	DisabledAudioLures.emit()

func _on_button_button_down():
	Deactivate()
	
func SetTimer():
	if Global.Bitcrush:
		$Timer.wait_time = (-0.5 * Global.StarDiff) + 5.5
		$DisableTimer.wait_time = $Timer.wait_time

signal DisabledAudioLures
signal ReenabledAudioLures
signal BeganRinging
signal EndedRinging
