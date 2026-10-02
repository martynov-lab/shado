import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../auth/domain/entities/user_session.dart';
import '../../../../home/presentation/screens/home_page.dart';
import '../../../../languages/domain/entities/language.dart';
import '../../../domain/entities/audio_trim.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/usecases/synthesize_tts.dart';
import '../../widgets/segment_splitter/marked_text_controller.dart';
import '../../widgets/synthesize_tts_dialog.dart';
import '../lesson/lesson_page.dart';
import 'add_lesson_form.dart';
import 'add_lesson_form_state.dart';
import 'add_lesson_model.dart';
import 'add_lesson_page.dart';
import 'add_lesson_preview.dart';

AddLessonWidgetModel addLessonWidgetModelFactory(BuildContext context) =>
    AddLessonWidgetModel(
      AddLessonModel(ProviderScope.containerOf(context, listen: false)),
    );

class AddLessonWidgetModel extends WidgetModel<AddLessonPage, AddLessonModel> {
  AddLessonWidgetModel(super.model);

  final TextEditingController titleController = TextEditingController();
  final MarkedTextController textController = MarkedTextController();

  /// While the screen itself holds the focus, space plays and pauses.
  final FocusNode pageFocus = FocusNode(debugLabel: 'add-lesson-page');

  final AddLessonForm _form = AddLessonForm();
  final ValueNotifier<AsyncState<List<Topic>>> _topics = ValueNotifier(
    const AsyncPending(),
  );
  final ValueNotifier<int?> _quotaLeft = ValueNotifier(null);
  late final AddLessonPreview _preview = AddLessonPreview(
    _form,
    model.createPreviewPlayer(),
  );
  late final ValueNotifier<bool> _canSubmit = ValueNotifier(
    _currentCanSubmit(),
  );
  late final Listenable _submitSources = Listenable.merge([
    _form,
    model.accents,
  ]);

  ValueListenable<AddLessonFormState> get form => _form;
  ValueListenable<AsyncState<List<Topic>>> get topics => _topics;
  ValueListenable<List<Accent>> get accents => model.accents;
  ValueListenable<UserSession> get session => model.session;
  ValueListenable<bool> get isPlaying => _preview.isPlaying;
  ValueListenable<int> get playheadMs => _preview.playheadMs;

  /// Voice-overs left today; `null` hides the hint.
  ValueListenable<int?> get quotaLeft => _quotaLeft;

  /// The create button unlocks once everything required is filled in.
  ValueListenable<bool> get canSubmit => _canSubmit;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _form.addListener(_syncText);
    _submitSources.addListener(_onSubmitSourcesChanged);
    unawaited(_loadTopics());
    unawaited(_loadQuota());
  }

  @override
  void dispose() {
    _form.removeListener(_syncText);
    _submitSources.removeListener(_onSubmitSourcesChanged);
    unawaited(_preview.dispose());
    titleController.dispose();
    textController.dispose();
    pageFocus.dispose();
    _form.dispose();
    _topics.dispose();
    _quotaLeft.dispose();
    _canSubmit.dispose();
    super.dispose();
  }

  void back() => context.go(HomePage.routePath);

  void setTitle(String title) => _form.setTitle(title);
  void setText(String text) => _form.setText(text);
  void setAccent(String? accent) => _form.setAccent(accent);
  void setLevel(LessonLevel? level) => _form.setLevel(level);
  void setTopic(String? topicId) => _form.setTopic(topicId);
  void setPrivate(bool isPrivate) => _form.setPrivate(isPrivate);
  void setBoundaries(List<int> boundaries) => _form.setBoundaries(boundaries);
  void removeMarker(int ordinal) => _form.removeMarker(ordinal);
  void setMarkerAtPlayhead(bool enabled) => _form.setMarkerAtPlayhead(enabled);
  void startTrim() => _form.startTrim();
  void updateTrim(AudioTrim trim) => _form.updateTrim(trim);
  void applyTrim() => _form.applyTrim();
  void cancelTrim() => _form.cancelTrim();
  void togglePreview() => unawaited(_preview.togglePlay());
  void seekPreview(int positionMs) => unawaited(_preview.seek(positionMs));

  /// Places the paired boundary of a new marker under the playhead.
  void insertMarker(String text, int ordinal) => _form.insertMarker(
    text,
    ordinal,
    _form.value.hasWaveform ? _preview.playheadMs.value : 0,
  );

  /// Touching the waveform takes the focus off the text field.
  void focusPage() => pageFocus.requestFocus();

  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.space ||
        !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    // There is no file yet — do not spin up the player for nothing.
    if (_form.value.audioPath == null) return KeyEventResult.ignored;
    togglePreview();
    return KeyEventResult.handled;
  }

  Future<void> pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedAudioExtensions,
      );
      final file = result?.files.singleOrNull;
      final path = file?.path;
      if (file == null || path == null) return;
      _form.startUpload(file.name);
      final upload = await model.uploadAudio(
        path,
        onProgress: _form.setUploadProgress,
      );
      if (upload != null) _form.finishUpload(upload);
    } catch (error) {
      _form.dropUpload();
      _showMessage('Failed to pick the file: $error');
    }
  }

  void cancelUpload() {
    model.cancelUpload();
    _form.dropUpload();
  }

  /// Voices the text, asking first when it would replace the chosen audio.
  Future<void> synthesize() async {
    if (_form.value.audioId != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const SynthesizeTtsDialog(),
      );
      if (confirmed != true || !isMounted) return;
    }
    await _runSynthesis();
  }

  Future<void> submit() async {
    final context = this.context;
    _form.setSubmitting(true);
    try {
      final lesson = await model.createLesson(_form.value);
      _form.reset();
      if (!context.mounted) return;
      titleController.clear();
      textController.clear();
      unawaited(context.push(LessonPage.routeTo(lesson.id)));
    } catch (error) {
      _form.setSubmitting(false);
      _showMessage('Failed to create the lesson: $error');
    }
  }

  Future<void> _runSynthesis() async {
    final text = _form.value.text;
    if (SynthesizeTts.prepareText(text).isEmpty) return;
    _form.startUpload('AI voiceover', isSynthesis: true);
    try {
      final upload = await model.synthesize(text);
      if (upload != null) _form.finishUpload(upload);
      // The voice-over spent daily quota — re-read what is left.
      unawaited(_loadQuota());
    } on ApiException catch (error) {
      _form.dropUpload();
      if (error.code == ApiErrorCode.ttsQuotaExceeded) {
        unawaited(_loadQuota());
      }
      _showTtsError(error);
    } catch (error) {
      _form.dropUpload();
      _showMessage('Failed to voice the text: $error');
    }
  }

  /// A voice-over error with a matching action: retry or upload a file.
  void _showTtsError(ApiException error) {
    if (!isMounted) return;
    switch (error.code) {
      case ApiErrorCode.ttsUnavailable:
        showAppSnackbar(
          context,
          message: 'Voiceover is temporarily unavailable. Try again later.',
          variant: AppSnackbarVariant.warning,
          actionLabel: 'Retry',
          onAction: _runSynthesis,
        );
      case ApiErrorCode.ttsQuotaExceeded:
        showAppSnackbar(
          context,
          message: error.message,
          variant: AppSnackbarVariant.warning,
          actionLabel: 'Upload a file',
          onAction: pickAudio,
        );
      case _:
        _showMessage('Failed to voice the text: ${error.message}');
    }
  }

  /// Text changed by the form (a removed marker) goes back into the field.
  void _syncText() {
    final text = _form.value.text;
    if (text != textController.text) textController.text = text;
  }

  void _onSubmitSourcesChanged() => _canSubmit.value = _currentCanSubmit();

  bool _currentCanSubmit() =>
      _form.value.isReady(needsAccent: model.accents.value.isNotEmpty);

  Future<void> _loadTopics() async {
    final topics = await AsyncState.guard(model.loadTopics);
    if (!isMounted) return;
    _topics.value = topics;
    // The topic could have been deleted elsewhere.
    final list = topics.value;
    if (list != null) _form.dropTopicUnless([for (final t in list) t.id]);
  }

  /// The quota hint is shown to the owner only.
  Future<void> _loadQuota() async {
    if (!model.session.value.isOwner) return;
    try {
      final day = (await model.loadQuota()).day;
      if (!isMounted) return;
      _quotaLeft.value = day.isUnlimited ? null : day.remaining;
    } catch (_) {
      return;
    }
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
