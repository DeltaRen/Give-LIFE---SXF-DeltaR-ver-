extends Node
class_name GL_Timeline

@onready var master = $"../../Master"
@onready var createChannel : OptionButton = $MarginContainer/TimelineBox/CreateChannel
@onready var timelineBox : VBoxContainer = $MarginContainer/TimelineBox
@onready var playButton : Button = $"../TimeManager/HBoxContainer/Play Button"
@onready var timeStartText : Label = $"../TimeManager/MarginContainer/StartTime"
@onready var timeEndText : Label = $"../TimeManager/MarginContainer/EndTime"
@onready var timelinePositionBar : ColorRect = $TimelineBar
@onready var currentTimeText : Label = $TimelineBar/currentTime

var channelPrefab = preload("res://New New/Prefabs/Channel.tscn")
var scrolledIndex = 0
var timeStart = 0.0
var timeEnd = 10.0
var timeCurrent = timeStart
const zoomMultOut = 1.1
const zoomMultIn = 0.9
const zoomMin = 0.1
const zoomMax = 60
const panAmount = 0.1

func format_time(seconds: float) -> String:
	var h = int(seconds) / 3600
	var m = (int(seconds) % 3600) / 60
	var s = int(seconds) % 60
	return "%02d:%02d:%02d" % [h, m, s]

func _process(delta: float) -> void:
	timeStartText.text = format_time(timeStart)
	timeEndText.text = format_time(timeEnd)

func setCurrentTime(current: float) -> void:
	timeCurrent = timeStart + current * (timeEnd - timeStart)
	currentTimeText.text = format_time(timeCurrent)

func _input(event: InputEvent) -> void:
	if master.currentlyLoadedPath != "":
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if event.ctrl_pressed:
					zoom(false)
				elif event.shift_pressed:
					pan(true)
				else:
					scroll(false)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.ctrl_pressed:
					zoom(true)
				elif event.shift_pressed:
					pan(false)
				else:
					scroll(true)

func updateTimelineBarX() -> void:
	timelinePositionBar.position.x = get_viewport().get_mouse_position().x

func zoom(out: bool):
	if out:
		print("Zoomed Out")
	else:
		print("Zoomed In")
	var mid = (timeStart + timeEnd) / 2.0
	var dist = timeEnd - timeStart
	var new_dist = dist * (zoomMultOut if out else zoomMultIn)
	new_dist = clamp(new_dist, zoomMin, zoomMax)
	timeStart = mid - new_dist / 2.0
	timeEnd = mid + new_dist / 2.0
	if timeStart < 0.0:
		timeEnd += -timeStart
		timeStart = 0.0
	repaintTimeline()

func pan(left: bool):
	if left:
		print("Panned Left")
	else:
		print("Panned Right")
	var dist = timeEnd - timeStart
	var offset = dist * panAmount * (-1.0 if left else 1.0)
	timeStart += offset
	timeEnd += offset
	if timeStart < 0.0:
		timeEnd += -timeStart
		timeStart = 0.0
	repaintTimeline()

func scroll(down: bool):
	if down:
		if scrolledIndex < master.currentlyLoadedFile["channels"].size() - 1:
			scrolledIndex += 1
			print("Scrolled Down")
	else:
		if scrolledIndex > 0:
			scrolledIndex -= 1
			print("Scrolled Up")
	repaintTimeline()

func repaintTimeline() -> void:
	for child in timelineBox.get_children():
		if child.name != "CreateChannel":
			(child as GL_Channel).renderBits()

func _ready() -> void:
	reload_timeline()

func create_channel(type: int) -> void:
	var finished = false
	match(type):
		0:
			return
		1:
			finished = master.create_channel("bool")
			print("Creating Bool Channel")
		2:
			finished = master.create_channel("float")
			print("Creating Float Channel")
		3:
			finished = master.create_channel("color")
			print("Creating Color Channel")
	if(finished):
		reload_timeline()
		createChannel.selected = 0
	else:
		print("Creating Channel Failed")

func reload_timeline() -> void:
	if master.currentlyLoadedPath == "":
		createChannel.visible = false
	else:
		createChannel.visible = true
	
	if master.currentlyLoadedPath == "":
		return
	
	if scrolledIndex >= master.currentlyLoadedFile["channels"].size():
		scrolledIndex = 0
	
	for child in timelineBox.get_children():
		if child.name != "CreateChannel":
			print(child.name)
			child.queue_free()
	
	var channels = master.currentlyLoadedFile["channels"]
	var sorted_keys = channels.keys()
	sorted_keys.sort_custom(func(a, b): return channels[a]["index"] < channels[b]["index"])
	for key in sorted_keys:
		var channelBox : GL_Channel = channelPrefab.instantiate()
		timelineBox.add_child(channelBox)
		channelBox.id = key
		channelBox.master = master
		channelBox.timeline = self
		channelBox.start()
	
	timelineBox.move_child(timelineBox.get_node("CreateChannel"), timelineBox.get_child_count() - 1)
