extends AudioStreamPlayer

var current_music: AudioStream = null

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS

func play_music(music: AudioStream):
    if current_music == music and playing:
        return

    current_music = music
    stream = music
    play()
