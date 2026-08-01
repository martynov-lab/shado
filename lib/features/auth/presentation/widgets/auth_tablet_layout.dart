import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

import 'auth_brand_header.dart';

/// Планшет: карточка по центру — брендовая шапка и форма под ней.
class AuthTabletLayout extends StatelessWidget {
  const AuthTabletLayout({
    super.key,
    required this.form,
    required this.isRegistration,
  });

  final Widget form;
  final bool isRegistration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CustomScrollView(
      slivers: [
        // Карточка стоит по центру экрана, но на коротком окне сама уезжает
        // в прокрутку, а не обрезается.
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.overlayMaxWidth,
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadii.rXxl,
                    border: Border.all(
                      color: colors.border,
                      width: AppSizes.borderThin,
                    ),
                    boxShadow: context.shadows.e2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // Тянем шапку и форму на всю ширину карточки: иначе
                    // градиентная шапка сжимается по своему тексту и висит
                    // по центру с тёмными полями по бокам.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthBrandHeader(isRegistration: isRegistration),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.s6),
                        child: form,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
