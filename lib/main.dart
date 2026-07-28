import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/platform/platform_setup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUpPlatform();
  runApp(const ProviderScope(child: ShadoApp()));
}
