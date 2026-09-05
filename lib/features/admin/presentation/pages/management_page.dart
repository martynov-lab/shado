import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import '../widgets/completion_threshold_section.dart';
import '../widgets/topics_admin_section.dart';

/// Management screen: completion threshold and the topic directory.
class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  static const String routePath = '/manage';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s5),
              child: CompletionThresholdSection(),
            ),
            const Expanded(child: TopicsAdminSection()),
          ],
        ),
      ),
    );
  }
}
