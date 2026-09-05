import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/gallery_speed.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery sheet content: speed picker and the confirm button.
class GallerySpeedSheet extends StatefulWidget {
  const GallerySpeedSheet({
    super.key,
    required this.initialSpeed,
    required this.onSpeedChanged,
  });

  final GallerySpeed initialSpeed;
  final ValueChanged<GallerySpeed> onSpeedChanged;

  @override
  State<GallerySpeedSheet> createState() => _GallerySpeedSheetState();
}

class _GallerySpeedSheetState extends State<GallerySpeedSheet> {
  late GallerySpeed _speed = widget.initialSpeed;

  void _select(GallerySpeed speed) {
    setState(() => _speed = speed);
    widget.onSpeedChanged(speed);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final speed in GallerySpeed.values)
        AppRadio<GallerySpeed>(
          value: speed,
          groupValue: _speed,
          label: speed.label,
          onChanged: _select,
        ),
      const SizedBox(height: AppSpacing.s5),
      AppButton(
        label: 'Готово',
        expand: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}
