import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/screens/design_gallery/sections/gallery_buttons_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_chips_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_fields_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_header.dart';
import 'package:shado/screens/design_gallery/sections/gallery_icons_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_lists_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_overlays_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_selection_section.dart';
import 'package:shado/screens/design_gallery/sections/gallery_typography_section.dart';
import 'package:shado/theme/theme.dart';

/// Design gallery: every component grouped by section on a single screen.
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  /// Gallery route; open without signing in.
  static const String routePath = '/design';

  @override
  Widget build(BuildContext context) {
    final pad = context.responsive(
      mobile: AppSpacing.s4,
      tablet: AppSpacing.s6,
      desktop: AppSpacing.s8,
    );

    return Scaffold(
      backgroundColor: context.colors.bg,
      // The app bar is only needed when there is somewhere to go back to.
      appBar: context.canPop()
          ? AppBar(
              backgroundColor: context.colors.bg,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContent,
            ),
            child: ListView(
              padding: EdgeInsets.all(pad),
              children: const [
                GalleryHeader(),
                SizedBox(height: AppSpacing.s8),
                GalleryTypographySection(),
                GalleryIconsSection(),
                GalleryButtonsSection(),
                GalleryFieldsSection(),
                GallerySelectionSection(),
                GalleryChipsSection(),
                GalleryListsSection(),
                GalleryOverlaysSection(),
                SizedBox(height: AppSpacing.s16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
