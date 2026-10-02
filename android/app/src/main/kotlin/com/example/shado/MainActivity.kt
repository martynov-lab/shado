package com.example.shado

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity instead of FlutterActivity: audio_service starts the Flutter
// engine from its service, and a tap on the notification/lock screen opens this window.
class MainActivity : AudioServiceActivity()
