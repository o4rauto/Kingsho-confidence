extends Node
## Sfx — sound effects + music.
##
## Asset slot: if res://assets/audio/<name>.ogg (or .wav) exists it is used —
## drop in sounds made with an AI SFX/music tool. Otherwise every sound is
## synthesized once at startup into a PCM buffer, so the game is never silent.

const RATE := 22050
const NAMES := ["shoot", "hit", "enemy_die", "deploy", "coin", "click", "back", "boon", "ult", "boss", "hurt", "victory", "defeat"]

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _buf := PackedFloat32Array()

func _ready() -> void:
	for n in NAMES:
		_streams[n] = _load_slot(n)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -14.0
	add_child(_music)
	var m = _load_slot("music")
	_music.stream = m if m else _synth_music()
	_music.finished.connect(func(): if _music_on(): _music.play())
	if _music_on():
		_music.play()

func _music_on() -> bool:
	return Save.data.settings.music

func set_music(on: bool) -> void:
	if on and not _music.playing:
		_music.play()
	elif not on:
		_music.stop()

func play(name: String, pitch := 1.0) -> void:
	if not Save.data.settings.sfx:
		return
	var s = _streams.get(name)
	if s == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.pitch_scale = pitch * randf_range(0.95, 1.05)
			p.play()
			return

func haptic(ms := 25) -> void:
	if Save.data.settings.haptics:
		Input.vibrate_handheld(ms)

# ── slots / synthesis ───────────────────────────────────────
func _load_slot(name: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		var path: String = "res://assets/audio/" + name + ext
		if ResourceLoader.exists(path):
			return load(path)
	if name == "music":
		return null
	return _synth(name)

func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w

## Tone: wave in {sine, square, saw, tri, noise}, freq slide f0→f1.
func _tone(start: float, dur: float, f0: float, f1: float, wave: String, vol: float) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	if _buf.size() < s0 + n:
		_buf.resize(s0 + n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		phase += f / RATE
		var x := 0.0
		match wave:
			"sine": x = sin(phase * TAU)
			"square": x = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"saw": x = fmod(phase, 1.0) * 2.0 - 1.0
			"tri": x = absf(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
			"noise": x = randf() * 2.0 - 1.0
		var env := minf(1.0, i / (0.004 * RATE)) * pow(1.0 - t, 1.6)
		_buf[s0 + i] += x * vol * env

func _synth(name: String) -> AudioStreamWAV:
	_buf = PackedFloat32Array()
	match name:
		"shoot":
			_tone(0, 0.12, 900, 380, "tri", 0.5)
		"hit":
			_tone(0, 0.06, 1, 1, "noise", 0.3)
			_tone(0, 0.06, 220, 140, "square", 0.2)
		"enemy_die":
			_tone(0, 0.2, 200, 60, "saw", 0.35)
			_tone(0, 0.12, 1, 1, "noise", 0.25)
		"deploy":
			_tone(0, 0.18, 320, 620, "sine", 0.5)
			_tone(0.05, 0.2, 480, 720, "sine", 0.35)
		"coin":
			_tone(0, 0.08, 880, 1180, "square", 0.25)
			_tone(0.07, 0.1, 1180, 1180, "square", 0.2)
		"click":
			_tone(0, 0.06, 520, 700, "square", 0.25)
		"back":
			_tone(0, 0.08, 400, 280, "square", 0.22)
		"boon":
			for i in 3:
				var f: float = [523.0, 784.0, 1046.0][i]
				_tone(i * 0.1, 0.2, f, f, "tri", 0.4)
		"ult":
			_tone(0, 0.5, 120, 900, "saw", 0.45)
			_tone(0, 0.4, 1, 1, "noise", 0.3)
		"boss":
			_tone(0, 0.8, 70, 48, "saw", 0.55)
			_tone(0, 0.6, 1, 1, "noise", 0.3)
		"hurt":
			_tone(0, 0.16, 160, 70, "square", 0.4)
			_tone(0, 0.1, 1, 1, "noise", 0.25)
		"victory":
			for i in 4:
				var f: float = [523.0, 659.0, 784.0, 1046.0][i]
				_tone(i * 0.13, 0.3, f, f, "tri", 0.4)
		"defeat":
			for i in 3:
				var f: float = [440.0, 349.0, 262.0][i]
				_tone(i * 0.2, 0.5, f, f * 0.8, "saw", 0.35)
	return _wav(_buf)

const MODES := {
	"minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10],
	"lydian": [0, 2, 4, 6, 7, 9, 11], "major": [0, 2, 4, 5, 7, 9, 11], "locrian": [0, 1, 3, 5, 6, 8, 10],
	"hijaz": [0, 1, 4, 5, 7, 8, 10],
}
var _realm_music: Dictionary = {}
var _menu_stream: AudioStream

## Each realm has its own scale, tempo and timbre. Slot: assets/audio/music_<realm_id>.ogg
func play_realm_music(realm: Dictionary) -> void:
	if _menu_stream == null:
		_menu_stream = _music.stream
	var key: String = "music_" + realm.id
	if not _realm_music.has(key):
		var slot = _load_slot(key) if ResourceLoader.exists("res://assets/audio/%s.ogg" % key) else null
		if slot == null:
			var m: Dictionary = realm.music
			slot = _synth_realm(m.root, MODES.get(m.mode, MODES.minor), m.tempo, m.wave, hash(realm.id))
		_realm_music[key] = slot
	_swap(_realm_music[key])

func play_menu_music() -> void:
	if _menu_stream and _music.stream != _menu_stream:
		_swap(_menu_stream)

func _swap(s: AudioStream) -> void:
	_music.stream = s
	if _music_on():
		_music.play()

func _synth_realm(root: float, mode: Array, step: float, wave: String, seed: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var steps := 16
	_buf = PackedFloat32Array()
	_buf.resize(int(step * steps * RATE) + RATE)
	var deg := 0
	for i in steps:
		deg = clampi(deg + rng.randi_range(-2, 2), 0, 9)
		var semis: int = mode[deg % 7] + 12 * int(deg / 7)
		var f := root * pow(2.0, semis / 12.0)
		_tone(i * step, step * 1.8, f, f, wave, 0.16)
		if i % 4 == 0:
			_tone(i * step, step * 3.5, root / 2.0, root / 2.0, "tri", 0.14)
		if i % 2 == 1:
			_tone(i * step, 0.05, 1, 1, "noise", 0.04)
	_buf.resize(int(step * steps * RATE))
	return _wav(_buf, true)

## A slow minor arpeggio pad, rendered once and looped.
func _synth_music() -> AudioStreamWAV:
	var scale := [196.0, 233.08, 261.63, 293.66, 349.23, 392.0, 466.16]
	var pattern := [0, 2, 4, 2, 5, 4, 2, 0, 3, 4, 6, 4, 0, 2, 4, 5]
	var step := 0.46
	_buf = PackedFloat32Array()
	_buf.resize(int(step * pattern.size() * RATE) + RATE)
	for i in pattern.size():
		var f: float = scale[pattern[i]]
		_tone(i * step, 0.9, f, f, "sine", 0.22)
		if i % 4 == 0:
			_tone(i * step, 1.6, f / 2.0, f / 2.0, "tri", 0.16)
	_buf.resize(int(step * pattern.size() * RATE))
	return _wav(_buf, true)
