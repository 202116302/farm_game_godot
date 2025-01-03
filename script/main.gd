extends Node

@export var playtime = 30

var level = 1
var score = 0
var time_left = 0 
var screensize = Vector2.ZERO
var playing = false 


func _ready():
	#screensize = get_viewport().get_visible_rect().size
	screensize = Vector2(get_window().size)
	if $Player.has_method("set_screensize"):  # 메서드를 통해 전달
		$Player.set_screensize(screensize)
	#$Player.screensize = screensize
	#$Player.hide()
	
 
