extends Node2D

var MousePos : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	$Black.color = Color.BLACK
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.WHITE, 2.0)
	DiscordPresence()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var viewportSize = get_viewport().get_visible_rect().size
	MousePos.x = (((get_global_mouse_position().x) / viewportSize.x) - 0.5) * 2 # Mouse X from -1.0 to 1.0
	MousePos.y = (((get_global_mouse_position().y) / viewportSize.x) - 0.5) * 2
	if MousePos.x > 1:
		MousePos.x = 1
	elif MousePos.x < -1:
		MousePos.x = -1
	if MousePos.y > 1:
		MousePos.y = 1
	elif MousePos.y < -1:
		MousePos.y = -1
	$Camera2D.position = Vector2(960,540) + Vector2(MousePos.x * 90, MousePos.y * 60)
	$Camera2D.rotation_degrees = MousePos.x * 2.5

func _on_timer_timeout():
	$PhoneCall/Text.visible = !$PhoneCall/Text.visible


func _on_phonecall_finished():
	var FadeTween = get_tree().create_tween()
	FadeTween.tween_property($Black, "color", Color.BLACK, 2.0)
	FadeTween.tween_callback(ChangeScene)

func ChangeScene():
	get_tree().change_scene_to_file("res://scenes/cn_menu.tscn")

func DiscordPresence():
	if Global.DiscordRPCSetup:
		DiscordRPC.details = "How Did We Get Here?"
		DiscordRPC.state = ""
		DiscordRPC.large_image = "game_icon" # Image key from "Art Assets"
		DiscordRPC.large_image_text = "Static Guy!"
		DiscordRPC.small_image = ""
		DiscordRPC.small_image_text = ""
		
		DiscordRPC.start_timestamp = Global.StartTime # "02:46 elapsed"
		# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
		
		DiscordRPC.refresh() # Always refresh after changing the values!
