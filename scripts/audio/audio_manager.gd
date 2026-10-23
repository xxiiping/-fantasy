extends Node

## 全局唯一 AutoLoad。三个场景都要放音效，各挂一个 AudioStreamPlayer
## 会重复且没人管生命周期，所以收敛到一处。
##
## 用一个小池子轮转，避免连续点击时后一声把前一声掐掉。

const SOUNDS := {
	"click": "res://assets/audio/click.wav",
	"correct": "res://assets/audio/correct.wav",
	"wrong": "res://assets/audio/wrong.wav",
}

const POOL_SIZE := 6
const AMBIENCE_PATH := "res://assets/audio/ambience.wav"

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _ambience: AudioStreamPlayer


func _ready() -> void:
	for key in SOUNDS:
		_streams[key] = load(SOUNDS[key])

	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_pool.append(player)

	_ambience = AudioStreamPlayer.new()
	var ambience := load(AMBIENCE_PATH)
	if ambience != null:
		_ambience.stream = ambience
		_ambience.volume_db = -22.0
		add_child(_ambience)
		_ambience.play()


func play_click() -> void:
	_play("click", -9.0)


func play_correct() -> void:
	_play("correct", -3.0)


func play_wrong() -> void:
	_play("wrong", -4.0)


func _play(key: String, volume_db: float) -> void:
	var stream: AudioStream = _streams.get(key)
	if stream == null:
		return

	for player in _pool:
		if not player.playing:
			_trigger(player, stream, volume_db)
			return

	# 池子满了就复用第一个，宁可掐断也不要静音
	_trigger(_pool[0], stream, volume_db)


func _trigger(player: AudioStreamPlayer, stream: AudioStream, volume_db: float) -> void:
	player.stream = stream
	player.volume_db = volume_db
	player.play()
