import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';

/// A discount campaign option (reference content).
class _Campaign {
  final String name;
  final String description;

  const _Campaign({required this.name, required this.description});
}

const _campaigns = <_Campaign>[
  _Campaign(name: '10% off first booking', description: 'Applies automatically to a family\'s first placement.'),
  _Campaign(name: 'Free assessment visit', description: 'Waive the initial in-home assessment fee.'),
  _Campaign(name: 'Referral bonus', description: 'Discount for families referred by an existing client.'),
];

/// Promotions & paid visibility, pushed from the centre home tools grid.
/// Toggles are local opt-in requests only — nothing is billed or activated,
/// and there are no campaign results until a promotions backend exists.
class PromotionsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PromotionsScreen({super.key, required this.onBack});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  bool _featured = false;
  late final _campaignEnabled = List<bool>.filled(_campaigns.length, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Promotions',
              subtitle: 'Opt into paid visibility and discount campaigns',
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Surface(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Featured placement',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Appear at the top of search results in your area. ALLCURO confirms pricing before anything is billed.',
                                style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _featured,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) {
                            setState(() => _featured = v);
                            if (v) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request noted. ALLCURO will contact you before activating it.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Discount campaigns',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _campaigns.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CampaignRow(
                        campaign: _campaigns[i],
                        enabled: _campaignEnabled[i],
                        onChanged: (v) => setState(() => _campaignEnabled[i] = v),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Campaign results',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const EmptyState(
                    message: 'No campaign results yet. Views and bookings from promotions will appear here once a campaign runs.',
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

class _CampaignRow extends StatelessWidget {
  final _Campaign campaign;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _CampaignRow({
    required this.campaign,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  campaign.description,
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: enabled,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
