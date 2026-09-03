import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'upload_progress.dart';

/// Плашка аудиофайла на экране создания: выбор файла или озвучка через ИИ, ход
/// загрузки и — когда файл принят — его имя с длительностью и кнопкой «Заменить».
class LessonFileChip extends StatelessWidget {
  const LessonFileChip({
    super.key,
    required this.fileName,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPick,
    required this.onCancelUpload,
    this.onSynthesize,
    this.canSynthesize = true,
    this.isSynthesizing = false,
    this.detail,
    this.helper,
  });

  /// Имя выбранного файла; `null` — файл ещё не выбирали.
  final String? fileName;

  /// Подпись под именем, например длительность.
  final String? detail;

  final bool isUploading;
  final double uploadProgress;

  /// Идёт озвучка через ИИ, а не загрузка файла: у неё нет процентов, поэтому
  /// подпись прогресса другая.
  final bool isSynthesizing;

  /// Выбрать или заменить файл. `null` — действие заперто (идёт отправка).
  final VoidCallback? onPick;
  final VoidCallback onCancelUpload;

  /// Озвучить текст через ИИ. `null` — озвучивать нечего (текст пуст) или идёт
  /// отправка: кнопка показана заперто, подсказывая, что нужен текст.
  final VoidCallback? onSynthesize;

  /// Доступна ли озвучка этому автору. `false` — кнопки нет вовсе: озвучивать
  /// вправе только владелец, остальным сервер ответит `403`.
  final bool canSynthesize;

  /// Подсказка про поддерживаемые форматы, когда файл ещё не выбран.
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isUploading) {
      return _Shell(
        child: UploadProgress(
          progress: uploadProgress,
          onCancelPressed: onCancelUpload,
          label: isSynthesizing ? 'Озвучиваем текст через ИИ…' : null,
        ),
      );
    }

    if (fileName == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Выберите аудио',
                  icon: Icons.audiotrack,
                  variant: AppButtonVariant.secondary,
                  onPressed: onPick,
                ),
              ),
              if (canSynthesize) ...[
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: AppButton(
                    label: 'Озвучить ИИ',
                    icon: Icons.auto_awesome,
                    variant: AppButtonVariant.secondary,
                    onPressed: onSynthesize,
                  ),
                ),
              ],
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              helper!,
              style: AppText.caption.copyWith(color: colors.text3),
            ),
          ],
        ],
      );
    }

    return _Shell(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(Icons.music_note, size: AppSizes.iconMd, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName!,
                  style: AppText.label.copyWith(color: colors.text),
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: AppText.caption.copyWith(color: colors.text3),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          // Озвучка доступна и когда файл уже выбран — заменит его. Предупреждение
          // о замене показывает экран создания.
          if (canSynthesize) ...[
            AppButton(
              label: 'Озвучить ИИ',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: onSynthesize,
            ),
            const SizedBox(width: AppSpacing.s2),
          ],
          AppButton(
            label: 'Заменить',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}

/// Общая рамка плашки: мягкая поверхность с пунктирным на вид контуром.
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: colors.borderStrong,
          width: AppSizes.borderThin,
        ),
      ),
      child: child,
    );
  }
}
