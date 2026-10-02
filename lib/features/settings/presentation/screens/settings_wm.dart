import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../../languages/domain/entities/language.dart';
import '../../../lessons/presentation/widgets/tts_voice_sheet.dart';
import '../../domain/entities/playback_settings.dart';
import '../widgets/playback_speed_sheet.dart';
import '../widgets/settings_text_edit_sheet.dart';
import '../widgets/studied_language_sheet.dart';
import '../widgets/switch_language_dialog.dart';
import 'settings_model.dart';
import 'settings_page.dart';

/// Data for the profile card. `languageLabel` is null until the user picks
/// a language.
typedef SettingsProfile = ({String name, String email, String? languageLabel});

SettingsWidgetModel settingsWidgetModelFactory(BuildContext context) =>
    SettingsWidgetModel(
      SettingsModel(ProviderScope.containerOf(context, listen: false)),
    );

class SettingsWidgetModel extends WidgetModel<SettingsPage, SettingsModel> {
  SettingsWidgetModel(super.model);

  late final ValueNotifier<SettingsProfile> _profile = ValueNotifier(
    _currentProfile(),
  );
  late final ValueNotifier<String> _studiedLanguageLabel = ValueNotifier(
    _currentLanguageLabel(),
  );
  late final ValueNotifier<String> _ttsVoiceLabel = ValueNotifier(
    _currentVoiceLabel(),
  );
  late final ValueNotifier<int?> _dailyGoalMinutes = ValueNotifier(
    model.user.value?.dailyGoalMinutes,
  );
  late final Listenable _profileSources = Listenable.merge([
    model.user,
    model.studiedLanguage,
  ]);

  bool _isSavingProfile = false;
  bool _isSwitchingLanguage = false;

  ValueListenable<SettingsProfile> get profile => _profile;

  ValueListenable<PlaybackSettings> get playbackSettings =>
      model.playbackSettings;

  ValueListenable<int?> get dailyGoalMinutes => _dailyGoalMinutes;

  ValueListenable<String> get studiedLanguageLabel => _studiedLanguageLabel;

  ValueListenable<String> get ttsVoiceLabel => _ttsVoiceLabel;

  ValueListenable<bool> get isOwner => model.isOwner;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _profileSources.addListener(_onProfileSourcesChanged);
    model.ttsVoice.addListener(_onTtsVoiceChanged);
  }

  @override
  void dispose() {
    _profileSources.removeListener(_onProfileSourcesChanged);
    model.ttsVoice.removeListener(_onTtsVoiceChanged);
    _ttsVoiceLabel.dispose();
    _profile.dispose();
    _studiedLanguageLabel.dispose();
    _dailyGoalMinutes.dispose();
    super.dispose();
  }

  Future<void> editName() async {
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: 'Name',
      builder: (_) => SettingsTextEditSheet(
        label: 'Name',
        initialValue: model.user.value?.name ?? '',
        hint: 'Alex',
      ),
    );
    if (raw == null || !isMounted) return;
    await _saveProfile(name: raw.trim());
  }

  Future<void> editDailyGoal() async {
    final current = model.user.value?.dailyGoalMinutes;
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: 'Daily goal',
      builder: (_) => SettingsTextEditSheet(
        label: 'Minutes per day',
        initialValue: current?.toString() ?? '',
        hint: 'For example, 15',
        keyboardType: TextInputType.number,
      ),
    );
    if (raw == null || !isMounted) return;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final minutes = int.tryParse(trimmed);
    if (minutes == null) {
      _showMessage('Enter the number of minutes');
      return;
    }
    await _saveProfile(dailyGoalMinutes: minutes);
  }

  Future<void> editDefaultSpeed() async {
    final selected = await showAppBottomSheet<double>(
      context: context,
      title: 'Default speed',
      builder: (_) => PlaybackSpeedSheet(
        current: model.playbackSettings.value.defaultSpeed,
      ),
    );
    if (selected == null) return;
    await model.setDefaultSpeed(selected);
  }

  Future<void> editStudiedLanguage() async {
    final context = this.context;
    final current = model.user.value?.studiedLanguage;
    final languages = ValueNotifier<AsyncState<List<Language>>>(
      const AsyncPending(),
    );
    var isSheetOpen = true;
    model.loadLanguages().then(
      (value) {
        if (isSheetOpen) languages.value = AsyncReady(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (isSheetOpen) languages.value = AsyncFailed(error, stackTrace);
      },
    );
    final code =
        await showAppBottomSheet<String>(
          context: context,
          title: 'Studied language',
          builder: (_) => ValueListenableBuilder(
            valueListenable: languages,
            builder: (_, languages, _) => StudiedLanguageSheet(
              languages: languages,
              selectedCode: current,
            ),
          ),
        ).whenComplete(() {
          isSheetOpen = false;
          languages.dispose();
        });
    if (code == null || code == current || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          SwitchLanguageDialog(languageLabel: model.languageLabel(code)),
    );
    if (confirmed != true || !context.mounted || _isSwitchingLanguage) return;

    _isSwitchingLanguage = true;
    try {
      await model.changeStudiedLanguage(code);
    } on ApiException catch (error) {
      _showMessage(
        error.status == 422
            ? 'The server did not accept the language — choose another one'
            : error.message,
      );
    } on Failure catch (failure) {
      _showMessage(failure.message);
    } catch (error) {
      _showMessage('Failed to switch the language: $error');
    } finally {
      _isSwitchingLanguage = false;
    }
  }

  Future<void> editTtsVoice() => showAppBottomSheet<void>(
    context: context,
    title: 'AI voiceover voice',
    builder: (_) => const TtsVoiceSheet(),
  );

  void setRepeatsInCycle(int repeats) => model.setRepeatsInCycle(repeats);

  void setPauseBetweenRepeats(bool enabled) =>
      model.setPauseBetweenRepeats(enabled);

  void setCountdownEnabled(bool enabled) => model.setCountdownEnabled(enabled);

  Future<void> _saveProfile({String? name, int? dailyGoalMinutes}) async {
    if (_isSavingProfile) return;
    _isSavingProfile = true;
    try {
      await model.updateProfile(name: name, dailyGoalMinutes: dailyGoalMinutes);
    } on Failure catch (failure) {
      _showMessage(failure.message);
    } catch (error) {
      _showMessage('Failed to save: $error');
    } finally {
      _isSavingProfile = false;
    }
  }

  void _onProfileSourcesChanged() {
    _studiedLanguageLabel.value = _currentLanguageLabel();
    _dailyGoalMinutes.value = model.user.value?.dailyGoalMinutes;
    _profile.value = _currentProfile();
  }

  void _onTtsVoiceChanged() => _ttsVoiceLabel.value = _currentVoiceLabel();

  String _currentVoiceLabel() {
    final voice = model.ttsVoice.value.voice;
    return voice == null || voice.isEmpty ? 'Default' : voice;
  }

  String _currentLanguageLabel() {
    final code = model.user.value?.studiedLanguage;
    if (code == null || code.isEmpty) return 'Not selected';
    return model.studiedLanguage.value?.label ?? code;
  }

  SettingsProfile _currentProfile() {
    final user = model.user.value;
    final email = user?.email ?? '';
    return (
      name: _displayName(user?.name, email),
      email: email,
      languageLabel: user?.studiedLanguage == null
          ? null
          : _currentLanguageLabel(),
    );
  }

  String _displayName(String? name, String email) {
    if (name != null && name.isNotEmpty) return name;
    final local = email.split('@').first;
    if (local.isEmpty) return 'Profile';
    return local[0].toUpperCase() + local.substring(1);
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
