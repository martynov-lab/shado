import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Витрина дизайн-системы: все компоненты на одном экране, разбитые по
/// разделам, с переключателем темы наверху.
///
/// Экран приёмочный, а не продуктовый — держите его в проекте, пока
/// библиотека растёт: он показывает, что компонент жив в обеих темах и на
/// любой ширине.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  /// Маршрут витрины. Открыт без входа в аккаунт.
  static const String routePath = '/design';

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

enum _Speed { slow, normal, fast }

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  bool _checked = true;
  bool _unchecked = false;
  bool? _indeterminate;
  _Speed _speed = _Speed.normal;
  bool _switchOn = true;
  bool _switchOff = false;
  final Set<String> _filters = {'Идиомы'};
  String? _topic = 'daily';
  double _speedValue = 1;
  double _position = 0.35;
  bool _loading = false;

  late final TextEditingController _plainField = TextEditingController(
    text: 'Small talk at the airport',
  );
  late final TextEditingController _errorField = TextEditingController(
    text: 'не почта',
  );
  final TextEditingController _emptyField = TextEditingController();

  @override
  void dispose() {
    _plainField.dispose();
    _errorField.dispose();
    _emptyField.dispose();
    super.dispose();
  }

  void _fakeLoad() {
    setState(() => _loading = true);
    Future.delayed(AppDurations.slow * 4, () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = context.responsive(
      mobile: AppSpacing.s4,
      tablet: AppSpacing.s6,
      desktop: AppSpacing.s8,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContent,
            ),
            child: ListView(
              padding: EdgeInsets.all(pad),
              children: [
                _header(context),
                const SizedBox(height: AppSpacing.s8),
                _typography(context),
                _buttons(context),
                _fields(context),
                _selection(context),
                _chips(context),
                _lists(context),
                _overlays(context),
                const SizedBox(height: AppSpacing.s16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Дизайн-система', style: AppText.displayLg.copyWith(color: c.text)),
        const SizedBox(height: AppSpacing.s2),
        Text(
          'Слушай. Повторяй. Все компоненты — на токенах.',
          style: AppText.body.copyWith(color: c.text2),
        ),
        const SizedBox(height: AppSpacing.s6),
        Align(
          alignment: Alignment.centerLeft,
          child: ThemeToggle(expand: context.isMobile),
        ),
      ],
    );
  }

  Widget _typography(BuildContext context) {
    final c = context.colors;
    return _Section(
      title: 'Типографика',
      caption: 'Sora для заголовков, Plus Jakarta Sans для текста, '
          'JetBrains Mono для цифр',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display 40/800', style: AppText.displayLg.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text('Heading 1 — 28/700', style: AppText.h1.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text('Heading 2 — 22/600', style: AppText.h2.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text('Title — 17/700', style: AppText.title.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Body — 15/400. Shadowing — это когда ты повторяешь за диктором '
            'почти одновременно с ним.',
            style: AppText.body.copyWith(color: c.text2),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text('LABEL — 13/600', style: AppText.label.copyWith(color: c.text2)),
          const SizedBox(height: AppSpacing.s2),
          Text('Caption — 12/500', style: AppText.caption.copyWith(color: c.text3)),
          const SizedBox(height: AppSpacing.s2),
          Text('00:42 / 04:17 · 1.25×', style: AppText.monoTime.copyWith(color: c.text)),
        ],
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return _Section(
      title: 'Кнопки',
      caption: 'Варианты, размеры, загрузка и выключенное состояние',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Варианты'),
          _Wrap(
            children: [
              AppButton(label: 'Слушать', icon: Icons.play_arrow_rounded, onPressed: () {}),
              AppButton(
                label: 'Повторить',
                variant: AppButtonVariant.secondary,
                icon: Icons.replay_rounded,
                onPressed: () {},
              ),
              AppButton(
                label: 'Отмена',
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
            ],
          ),
          const _Label('Размеры'),
          _Wrap(
            children: [
              AppButton(label: 'Small', size: AppButtonSize.sm, onPressed: () {}),
              AppButton(label: 'Medium', onPressed: () {}),
              AppButton(label: 'Large', size: AppButtonSize.lg, onPressed: () {}),
            ],
          ),
          const _Label('Состояния'),
          _Wrap(
            children: [
              AppButton(
                label: _loading ? 'Загружаю' : 'Запустить загрузку',
                loading: _loading,
                onPressed: _fakeLoad,
              ),
              const AppButton(label: 'Выключена'),
              const AppButton(
                label: 'Выключена',
                variant: AppButtonVariant.secondary,
              ),
              const AppButton(label: 'Выключена', variant: AppButtonVariant.ghost),
            ],
          ),
          const _Label('Во всю ширину'),
          AppButton(
            label: 'Начать урок',
            icon: Icons.headphones_rounded,
            size: AppButtonSize.lg,
            expand: true,
            onPressed: () {},
          ),
          const _Label('Иконочные — круглые и квадратные'),
          _Wrap(
            children: [
              AppIconButton(
                icon: Icons.play_arrow_rounded,
                semanticLabel: 'Воспроизвести',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.lg,
                onPressed: () {},
              ),
              AppIconButton(
                icon: Icons.pause_rounded,
                semanticLabel: 'Пауза',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppIconButton(
                icon: Icons.mic_rounded,
                semanticLabel: 'Записать',
                onPressed: () {},
              ),
              AppIconButton(
                icon: Icons.cut_rounded,
                semanticLabel: 'Обрезать',
                shape: AppIconButtonShape.square,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppIconButton(
                icon: Icons.tune_rounded,
                semanticLabel: 'Настройки',
                shape: AppIconButtonShape.square,
                size: AppButtonSize.sm,
                onPressed: () {},
              ),
              const AppIconButton(
                icon: Icons.delete_outline_rounded,
                semanticLabel: 'Удалить',
                shape: AppIconButtonShape.square,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fields(BuildContext context) {
    return _Section(
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
          const AppSlider(
            label: 'Выключенный',
            value: 0.5,
            onChanged: null,
          ),
        ],
      ),
    );
  }

  Widget _selection(BuildContext context) {
    return _Section(
      title: 'Выбор',
      caption: 'Флажки, переключатели, тумблеры и сегменты',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Флажки'),
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
          const _Label('Переключатели'),
          for (final speed in _Speed.values)
            AppRadio<_Speed>(
              value: speed,
              groupValue: _speed,
              label: switch (speed) {
                _Speed.slow => 'Медленно — 0.75×',
                _Speed.normal => 'Обычно — 1.0×',
                _Speed.fast => 'Быстро — 1.5×',
              },
              onChanged: (value) => setState(() => _speed = value),
            ),
          const _Label('Тумблеры'),
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
          const _Label('Сегменты'),
          AppSegmentedControl<_Speed>(
            value: _speed,
            onChanged: (value) => setState(() => _speed = value),
            segments: const [
              AppSegment(value: _Speed.slow, label: '0.75×'),
              AppSegment(value: _Speed.normal, label: '1.0×'),
              AppSegment(value: _Speed.fast, label: '1.5×'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips(BuildContext context) {
    return _Section(
      title: 'Чипы и бейджи',
      caption: 'Ярлыки, фильтры и статусы',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Чипы — заливка primary и мягкая'),
          _Wrap(
            children: [
              AppChip(label: 'Выбран', selected: true, onTap: () {}),
              AppChip(
                label: 'Выбран мягко',
                selected: true,
                style: AppChipStyle.onSoft,
                onTap: () {},
              ),
              AppChip(label: 'Не выбран', onTap: () {}),
              AppChip(
                label: 'С иконкой',
                icon: Icons.local_fire_department_rounded,
                onTap: () {},
              ),
              const AppChip(label: 'Просто ярлык'),
            ],
          ),
          const _Label('Фильтры — множественный выбор'),
          _Wrap(
            children: [
              for (final tag in const [
                'Идиомы',
                'Произношение',
                'Аудирование',
                'Бизнес',
              ])
                AppFilterChip(
                  label: tag,
                  selected: _filters.contains(tag),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _filters.add(tag);
                    } else {
                      _filters.remove(tag);
                    }
                  }),
                ),
            ],
          ),
          const _Label('Бейджи'),
          const _Wrap(
            children: [
              AppBadge(label: 'Новый', icon: Icons.auto_awesome_rounded),
              AppBadge(
                label: 'Пора повторить',
                variant: AppBadgeVariant.due,
                icon: Icons.schedule_rounded,
              ),
              AppBadge(
                label: 'Серия 7 дней',
                variant: AppBadgeVariant.hot,
                icon: Icons.local_fire_department_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lists(BuildContext context) {
    final c = context.colors;
    return _Section(
      title: 'Списки и карточки',
      caption: 'Строка урока и карточка-контейнер',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Column(
              children: [
                AppListRow(
                  index: 1,
                  title: 'Small talk at the airport',
                  subtitle: 'Повседневное общение · 12 сегментов',
                  trailingTime: '04:17',
                  selected: true,
                  semanticLabel: 'Урок 1, Small talk at the airport, играет',
                  onTap: () {},
                ),
                AppListRow(
                  index: 2,
                  title: 'Ordering coffee',
                  subtitle: 'Повседневное общение · 8 сегментов',
                  trailingTime: '02:48',
                  onTap: () {},
                ),
                AppListRow(
                  index: 3,
                  title: 'Job interview basics',
                  subtitle: 'Деловой английский · 21 сегмент',
                  trailing: const AppBadge(
                    label: 'Новый',
                    variant: AppBadgeVariant.fresh,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppCard(
            onTap: () {},
            semanticLabel: 'Карточка прогресса',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Нажимаемая карточка',
                        style: AppText.h2.copyWith(color: c.text),
                      ),
                    ),
                    const AppBadge(
                      label: 'Серия 7 дней',
                      variant: AppBadgeVariant.hot,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  'На наведении поднимается с тени e1 до e2, с клавиатуры '
                  'получает кольцо фокуса.',
                  style: AppText.body.copyWith(color: c.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlays(BuildContext context) {
    return _Section(
      title: 'Оверлеи',
      caption: 'Модальный лист и всплывающие сообщения',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Wrap(
            children: [
              AppButton(
                label: 'Модальный лист',
                icon: Icons.vertical_align_bottom_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showSheet(context),
              ),
            ],
          ),
          const _Label('Сообщения'),
          _Wrap(
            children: [
              AppButton(
                label: 'Обычное',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.ghost,
                onPressed: () => showAppSnackbar(
                  context,
                  message: 'Черновик сохранён',
                  actionLabel: 'Открыть',
                  onAction: () {},
                ),
              ),
              AppButton(
                label: 'Успех',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.ghost,
                onPressed: () => showAppSnackbar(
                  context,
                  message: 'Урок сохранён',
                  variant: AppSnackbarVariant.success,
                ),
              ),
              AppButton(
                label: 'Внимание',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.ghost,
                onPressed: () => showAppSnackbar(
                  context,
                  message: 'Микрофон занят другим приложением',
                  variant: AppSnackbarVariant.warning,
                ),
              ),
              AppButton(
                label: 'Ошибка',
                size: AppButtonSize.sm,
                variant: AppButtonVariant.ghost,
                onPressed: () => showAppSnackbar(
                  context,
                  message: 'Не удалось прочитать аудиофайл',
                  variant: AppSnackbarVariant.danger,
                  actionLabel: 'Ещё раз',
                  onAction: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Скорость воспроизведения',
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final speed in _Speed.values)
              AppRadio<_Speed>(
                value: speed,
                groupValue: _speed,
                label: switch (speed) {
                  _Speed.slow => 'Медленно — 0.75×',
                  _Speed.normal => 'Обычно — 1.0×',
                  _Speed.fast => 'Быстро — 1.5×',
                },
                onChanged: (value) {
                  setState(() => _speed = value);
                  setSheetState(() {});
                },
              ),
            const SizedBox(height: AppSpacing.s5),
            AppButton(
              label: 'Готово',
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Раздел витрины: заголовок, пояснение и карточка с содержимым.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.caption});

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h1.copyWith(color: c.text)),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(caption!, style: AppText.caption.copyWith(color: c.text3)),
          ],
          const SizedBox(height: AppSpacing.s5),
          AppCard(child: child),
        ],
      ),
    );
  }
}

/// Подпись над группой примеров внутри раздела.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s5,
        bottom: AppSpacing.s3,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.caption.copyWith(color: context.colors.text3),
      ),
    );
  }
}

/// Ряд примеров, переносящийся на узких экранах.
class _Wrap extends StatelessWidget {
  const _Wrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
