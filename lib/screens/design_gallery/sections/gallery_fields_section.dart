import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Раздел витрины: поля ввода, выпадающий список и ползунки.
class GalleryFieldsSection extends StatefulWidget {
  const GalleryFieldsSection({super.key});

  @override
  State<GalleryFieldsSection> createState() => _GalleryFieldsSectionState();
}

class _GalleryFieldsSectionState extends State<GalleryFieldsSection> {
  late final TextEditingController _plainField = TextEditingController(
    text: 'Small talk at the airport',
  );
  late final TextEditingController _errorField = TextEditingController(
    text: 'не почта',
  );
  final TextEditingController _emptyField = TextEditingController();

  String? _topic = 'daily';
  double _speedValue = 1;
  double _position = 0.35;

  @override
  void dispose() {
    _plainField.dispose();
    _errorField.dispose();
    _emptyField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Поля',
    caption: 'Ввод, выпадающий список и ползунки',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _plainField,
          label: 'Название урока',
          hint: 'Например, «Разговор в аэропорту»',
          prefixIcon: Icons.title_rounded,
        ),
        const SizedBox(height: AppSpacing.s5),
        AppTextField(
          controller: _emptyField,
          label: 'Пароль',
          hint: 'Минимум 8 символов',
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: Icons.visibility_outlined,
          suffixSemanticLabel: 'Показать пароль',
          obscureText: true,
          helperText: 'Хранится только на устройстве',
          onSuffixPressed: () {},
        ),
        const SizedBox(height: AppSpacing.s5),
        AppTextField(
          controller: _errorField,
          label: 'Почта',
          prefixIcon: Icons.alternate_email_rounded,
          errorText: 'Похоже, это не адрес почты',
        ),
        const SizedBox(height: AppSpacing.s5),
        const AppTextField(
          label: 'Выключенное поле',
          hint: 'Недоступно',
          enabled: false,
        ),
        const SizedBox(height: AppSpacing.s6),
        AppDropdown<String>(
          label: 'Тема урока',
          hint: 'Выберите тему',
          value: _topic,
          onChanged: (value) => setState(() => _topic = value),
          items: const [
            AppDropdownItem(
              value: 'daily',
              label: 'Повседневное общение',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            AppDropdownItem(
              value: 'business',
              label: 'Деловой английский',
              icon: Icons.work_outline_rounded,
            ),
            AppDropdownItem(
              value: 'travel',
              label: 'Путешествия',
              icon: Icons.flight_takeoff_rounded,
            ),
            AppDropdownItem(
              value: 'movies',
              label: 'Кино и сериалы',
              icon: Icons.movie_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        AppSlider(
          label: 'Скорость',
          valueLabel: '${_speedValue.toStringAsFixed(2)}×',
          value: _speedValue,
          min: 0.5,
          max: 2,
          divisions: 6,
          semanticLabel: 'Скорость воспроизведения',
          onChanged: (value) => setState(() => _speedValue = value),
        ),
        AppSlider(
          label: 'Позиция',
          valueLabel: '00:42 / 04:17',
          value: _position,
          semanticLabel: 'Позиция воспроизведения',
          onChanged: (value) => setState(() => _position = value),
        ),
        const AppSlider(label: 'Выключенный', value: 0.5, onChanged: null),
      ],
    ),
  );
}
