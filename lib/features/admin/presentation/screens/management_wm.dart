import 'package:elementary/elementary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../../lessons/domain/entities/lesson_category.dart';
import '../../../settings/presentation/widgets/settings_text_edit_sheet.dart';
import '../widgets/delete_topic_dialog.dart';
import 'management_model.dart';
import 'management_page.dart';

ManagementWidgetModel managementWidgetModelFactory(BuildContext context) =>
    ManagementWidgetModel(
      ManagementModel(ProviderScope.containerOf(context, listen: false)),
    );

class ManagementWidgetModel
    extends WidgetModel<ManagementPage, ManagementModel> {
  ManagementWidgetModel(super.model);

  final ValueNotifier<AsyncState<List<Topic>>> _topics = ValueNotifier(
    const AsyncPending(),
  );
  bool _isSavingReps = false;

  ValueListenable<int?> get completionReps => model.completionReps;
  ValueListenable<AsyncState<List<Topic>>> get topics => _topics;

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    reloadTopics();
  }

  @override
  void dispose() {
    _topics.dispose();
    super.dispose();
  }

  Future<void> reloadTopics() async {
    _topics.value = const AsyncPending();
    final topics = await AsyncState.guard(model.loadTopics);
    if (isMounted) _topics.value = topics;
  }

  Future<void> editCompletionReps() async {
    final current = model.completionReps.value;
    if (current == null) return;
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: 'Completion threshold',
      builder: (_) => SettingsTextEditSheet(
        label: 'Repeats per segment',
        initialValue: '$current',
        hint: 'For example, 10',
        keyboardType: TextInputType.number,
      ),
    );
    if (raw == null || !isMounted) return;
    final reps = int.tryParse(raw.trim());
    if (reps == null) {
      _showMessage('Enter the number of repeats');
      return;
    }
    if (_isSavingReps) return;
    _isSavingReps = true;
    try {
      await model.saveCompletionReps(reps);
    } on Failure catch (failure) {
      _showMessage(failure.message);
    } catch (error) {
      _showMessage('Failed to save: $error');
    } finally {
      _isSavingReps = false;
    }
  }

  Future<void> createTopic() async {
    final name = await _promptName(title: 'New topic', initial: '');
    if (name == null) return;
    await _changeTopics(() => model.createTopic(name));
  }

  Future<void> renameTopic(Topic topic) async {
    final name = await _promptName(title: 'Rename topic', initial: topic.name);
    if (name == null) return;
    await _changeTopics(() => model.renameTopic(id: topic.id, name: name));
  }

  Future<void> deleteTopic(Topic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteTopicDialog(topicName: topic.name),
    );
    if (confirmed != true || !isMounted) return;
    await _changeTopics(
      () => model.deleteTopic(topic.id),
      success: 'Topic "${topic.name}" deleted',
    );
  }

  /// Returns `null` when the sheet is closed or the name is left empty.
  Future<String?> _promptName({
    required String title,
    required String initial,
  }) async {
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: title,
      builder: (_) => SettingsTextEditSheet(
        label: 'Topic name',
        initialValue: initial,
        hint: 'For example, Travel',
      ),
    );
    final name = raw?.trim();
    if (name == null || name.isEmpty || !isMounted) return null;
    return name;
  }

  Future<void> _changeTopics(
    Future<void> Function() change, {
    String? success,
  }) async {
    try {
      await change();
      final topics = await model.loadTopics();
      if (!isMounted) return;
      _topics.value = AsyncReady(topics);
      if (success != null) _showMessage(success);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Failed to save: $error');
    }
  }

  void _showMessage(String message) {
    if (!isMounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
