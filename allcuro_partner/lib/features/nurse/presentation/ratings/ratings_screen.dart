import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';

/// Nurse's ratings & feedback screen, pushed from the "More tools" grid.
/// There's no reviews backend yet, so this shows an honest empty state;
/// family reviews (and replies to them) will be listed here once families
/// can rate completed visits.
class RatingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const RatingsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Ratings & feedback', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.star_outline_rounded,
                    title: 'No reviews yet',
                    message: 'Families can rate you after a completed visit. Their reviews will show up here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
