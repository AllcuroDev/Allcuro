import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/allcuro_chip.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/partner_avatar.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/utils/currency.dart';
import '../../data/models/centre.dart';
import 'centres_list_view_model.dart';

const _filters = [
  'All Centres',
  'Elderly Care',
  'Rehabilitation',
  'Physiotherapy',
  'Palliative Care',
  'Dementia Care',
];

class CentresListScreen extends ConsumerWidget {
  const CentresListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centresAsync = ref.watch(centresListViewModelProvider);

    return AppShell(
      currentPath: '/centres',
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          ScreenHeader(
            title: 'Home Care Centres',
            subtitle: 'Physically inspected centres with 24/7 nursing',
            onBack: () => context.go('/'),
          ),
          if (centresAsync.valueOrNull?.isNotEmpty ?? false) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => AllcuroChip(_filters[i]),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: centresAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (error, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Could not load centres',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
              ),
              data: (centres) => centres.isEmpty
                  ? const EmptyState(
                      icon: Icons.apartment_rounded,
                      title: 'No care centres listed yet',
                      message: 'We are inspecting and onboarding care centres. '
                          'Call our care desk and we will help you find a bed.',
                    )
                  : Column(
                      children: centres.map((c) => _CentreCard(centre: c)).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CentreCard extends StatelessWidget {
  final Centre centre;

  const _CentreCard({required this.centre});

  @override
  Widget build(BuildContext context) {
    final c = centre;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Surface(
        onTap: () => context.push('/centres/${c.id}'),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NetworkPhoto(
                  url: c.photo,
                  height: 170,
                  width: double.infinity,
                  icon: Icons.apartment_rounded,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ALLCURO VERIFIED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (c.bedsLeft > 0 && c.bedsLeft <= 3)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.destructive,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'Only ${c.bedsLeft} beds left',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [c.type, c.locality.isNotEmpty ? c.locality : c.city]
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (c.reviews > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              c.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (c.staffRatio.isNotEmpty) 'Staff ratio ${c.staffRatio}',
                            if (c.since > 0) 'Est. ${c.since}',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      if (c.pricePerDay > 0)
                      Text.rich(
                        TextSpan(
                          text: inr(c.pricePerDay),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                          children: const [
                            TextSpan(
                              text: ' / day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
