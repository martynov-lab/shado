import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import '../widgets/language_settings_section.dart';
import '../widgets/learning_settings_section.dart';
import '../widgets/playback_settings_section.dart';
import '../widgets/settings_mobile_view.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_tablet_view.dart';
import 'settings_wm.dart';

/// Settings screen: profile, appearance, playback, learning, language and
/// storage.
class SettingsPage extends ElementaryWidget<SettingsWidgetModel> {
  const SettingsPage({super.key}) : super(settingsWidgetModelFactory);

  static const String routePath = '/settings';

  @override
  Widget build(SettingsWidgetModel wm) {
    final profile = ValueListenableBuilder(
      valueListenable: wm.profile,
      builder: (_, profile, _) => SettingsProfileCard(
        name: profile.name,
        email: profile.email,
        languageLabel: profile.languageLabel,
        onEdit: () => unawaited(wm.editName()),
      ),
    );
    final playback = ValueListenableBuilder(
      valueListenable: wm.playbackSettings,
      builder: (_, settings, _) => PlaybackSettingsSection(
        settings: settings,
        onEditSpeed: () => unawaited(wm.editDefaultSpeed()),
        onRepeatsChanged: wm.setRepeatsInCycle,
        onPauseChanged: wm.setPauseBetweenRepeats,
        onCountdownChanged: wm.setCountdownEnabled,
      ),
    );
    final learning = ValueListenableBuilder(
      valueListenable: wm.dailyGoalMinutes,
      builder: (_, goal, _) => LearningSettingsSection(
        dailyGoalMinutes: goal,
        onEditGoal: () => unawaited(wm.editDailyGoal()),
      ),
    );
    final language = ListenableBuilder(
      listenable: Listenable.merge([
        wm.studiedLanguageLabel,
        wm.ttsVoiceLabel,
        wm.isOwner,
      ]),
      builder: (_, _) => LanguageSettingsSection(
        studiedLanguageLabel: wm.studiedLanguageLabel.value,
        ttsVoiceLabel: wm.isOwner.value ? wm.ttsVoiceLabel.value : null,
        onEditLanguage: () => unawaited(wm.editStudiedLanguage()),
        onEditVoice: () => unawaited(wm.editTtsVoice()),
      ),
    );

    return AppAdaptiveLayout(
      mobile: (_) => SettingsMobileView(
        profile: profile,
        playback: playback,
        learning: learning,
        language: language,
      ),
      tablet: (_) => SettingsTabletView(
        profile: profile,
        playback: playback,
        learning: learning,
        language: language,
      ),
    );
  }
}
