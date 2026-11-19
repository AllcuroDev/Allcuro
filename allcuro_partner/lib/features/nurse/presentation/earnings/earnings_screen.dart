import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';

/// Nurse's earnings screen, pushed from the "More tools" grid. There's no
/// bookings / payouts backend yet, so this shows an honest empty state
/// instead of numbers; per-visit payouts and monthly statements will be
/// listed here once completed visits are recorded.
class EarningsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const EarningsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Earnings', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No earnings yet',
                    message:
                        'Payouts appear here after your first completed visit. '
                        'Monthly statements and payslips will be available once you have earnings.',
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
