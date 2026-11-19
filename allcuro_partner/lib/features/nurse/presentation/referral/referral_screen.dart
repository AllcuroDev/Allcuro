import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';

/// Nurse's referral screen, pushed from the "More tools" grid. There's no
/// referral programme backend yet — no codes are issued and nothing is
/// tracked — so this shows an honest empty state instead of a made-up code
/// and referral list.
class ReferralScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ReferralScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Refer a colleague', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.card_giftcard_outlined,
                    title: 'No referrals yet',
                    message:
                        "Referral codes aren't available yet. When the referral programme launches, "
                        "your code and the colleagues you've referred will appear here.",
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
