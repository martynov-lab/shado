import 'dart:async';

import 'package:elementary/elementary.dart';
import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../widgets/completion_threshold_section.dart';
import '../widgets/topics_admin_section.dart';
import 'management_wm.dart';

/// Management screen: completion threshold and the topic directory.
class ManagementPage extends ElementaryWidget<ManagementWidgetModel> {
  const ManagementPage({super.key}) : super(managementWidgetModelFactory);

  static const String routePath = '/manage';

  @override
  Widget build(ManagementWidgetModel wm) {
    return Scaffold(
      appBar: AppBar(title: const Text('Management')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: ValueListenableBuilder(
                valueListenable: wm.completionReps,
                builder: (_, reps, _) => CompletionThresholdSection(
                  reps: reps,
                  onEdit: () => unawaited(wm.editCompletionReps()),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: wm.topics,
                builder: (_, topics, _) => TopicsAdminSection(
                  topics: topics,
                  onAdd: () => unawaited(wm.createTopic()),
                  onRename: (topic) => unawaited(wm.renameTopic(topic)),
                  onDelete: (topic) => unawaited(wm.deleteTopic(topic)),
                  onRetry: () => unawaited(wm.reloadTopics()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
