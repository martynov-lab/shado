import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/gallery_speed.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery section: checkboxes, radios, switches and segments.
class GallerySelectionSection extends StatefulWidget {
  const GallerySelectionSection({super.key});

  @override
  State<GallerySelectionSection> createState() =>
      _GallerySelectionSectionState();
}

class _GallerySelectionSectionState extends State<GallerySelectionSection> {
  bool _checked = true;
  bool _unchecked = false;
  bool? _indeterminate;
  GallerySpeed _speed = GallerySpeed.normal;
  bool _switchOn = true;
  bool _switchOff = false;

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Выбор',
    caption: 'Флажки, переключатели, тумблеры и сегменты',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GalleryLabel('Флажки'),
        AppCheckbox(
          value: _checked,
          label: 'Повторять сегмент',
          onChanged: (value) => setState(() => _checked = value),
        ),
        AppCheckbox(
          value: _unchecked,
          label: 'Показывать перевод',
          onChanged: (value) => setState(() => _unchecked = value),
        ),
        AppCheckbox(
          value: _indeterminate,
          label: 'Выбраны не все сегменты',
          onChanged: (value) => setState(() => _indeterminate = value),
        ),
        const AppCheckbox(
          value: true,
          label: 'Выключенный флажок',
          onChanged: null,
        ),
        const GalleryLabel('Переключатели'),
        for (final speed in GallerySpeed.values)
          AppRadio<GallerySpeed>(
            value: speed,
            groupValue: _speed,
            label: speed.label,
            onChanged: (value) => setState(() => _speed = value),
          ),
        const GalleryLabel('Тумблеры'),
        AppSwitch(
          value: _switchOn,
          label: 'Автопауза после сегмента',
          onChanged: (value) => setState(() => _switchOn = value),
        ),
        AppSwitch(
          value: _switchOff,
          label: 'Скрывать текст',
          onChanged: (value) => setState(() => _switchOff = value),
        ),
        const AppSwitch(
          value: true,
          label: 'Выключенный тумблер',
          onChanged: null,
        ),
        const GalleryLabel('Сегменты'),
        AppSegmentedControl<GallerySpeed>(
          value: _speed,
          onChanged: (value) => setState(() => _speed = value),
          segments: [
            for (final speed in GallerySpeed.values)
              AppSegment(value: speed, label: speed.shortLabel),
          ],
        ),
      ],
    ),
  );
}
