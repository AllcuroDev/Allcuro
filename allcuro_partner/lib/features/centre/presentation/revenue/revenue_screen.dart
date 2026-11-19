import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';

/// Revenue overview for a homecare centre, pushed from the centre home
/// screen's tools grid. There's no bookings / settlements backend yet, so
/// this shows an honest empty state; booking totals and settlement history
/// will be listed here once admissions are recorded.
class RevenueScreen extends StatelessWidget {
  final VoidCallback onBack;

  const RevenueScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Revenue', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No revenue yet',
                    message:
                        'Settlements appear here after your first admission through ALLCURO. '
                        'Payouts go to the bank account you add in Bank Payout.',
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
