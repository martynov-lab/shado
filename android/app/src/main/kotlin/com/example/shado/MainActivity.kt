package com.example.shado

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity вместо FlutterActivity: audio_service запускает Flutter-
// движок из своего сервиса, и тап по уведомлению/локскрину открывает это же окно.
class MainActivity : AudioServiceActivity()
