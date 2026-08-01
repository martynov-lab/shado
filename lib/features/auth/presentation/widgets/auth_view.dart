import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import 'auth_desktop_layout.dart';
import 'auth_mobile_layout.dart';
import 'auth_tablet_layout.dart';

/// Тело экрана входа: одна и та же форма в трёх раскладках макета.
class AuthView extends StatelessWidget {
  const AuthView({super.key, required this.form, required this.isRegistration});

  final Widget form;
  final bool isRegistration;

  @override
  Widget build(BuildContext context) => AppAdaptiveLayout(
    mobile: (context) => AuthMobileLayout(form: form),
    tablet: (context) =>
        AuthTabletLayout(form: form, isRegistration: isRegistration),
    desktop: (context) =>
        AuthDesktopLayout(form: form, isRegistration: isRegistration),
  );
}
