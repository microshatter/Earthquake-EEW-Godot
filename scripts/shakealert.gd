extends AudioStreamPlayer

@export var autoplayshakealert = true

func setAutoPlay(value: bool):
	autoplayshakealert = value


func _on_eew_popup_shakealert() -> void:
	play()


func _on_finished() -> void:
	if $"..".visible and autoplayshakealert:
		play()
