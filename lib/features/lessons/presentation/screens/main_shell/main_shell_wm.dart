import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_shell.dart';
import 'main_shell_model.dart';

MainShellWidgetModel mainShellWidgetModelFactory(BuildContext context) =>
    MainShellWidgetModel(
      MainShellModel(ProviderScope.containerOf(context, listen: false)),
    );

class MainShellWidgetModel extends WidgetModel<MainShell, MainShellModel> {
  MainShellWidgetModel(super.model);

  late final ValueNotifier<StatefulNavigationShell> _shell = ValueNotifier(
    widget.navigationShell,
  );

  /// The add section is shown to authors only.
  ValueListenable<bool> get canAuthor => model.canAuthor;

  ValueListenable<String> get email => model.email;

  /// The router hands over a new shell on every navigation.
  ValueListenable<StatefulNavigationShell> get shell => _shell;

  int get currentIndex => _shell.value.currentIndex;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    unawaited(model.reloadUser());
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _shell.value = widget.navigationShell;
  }

  @override
  void dispose() {
    _shell.dispose();
    super.dispose();
  }

  /// Tapping the active section again returns it to its first screen.
  void select(int index) => _shell.value.goBranch(
    index,
    initialLocation: index == _shell.value.currentIndex,
  );
}
