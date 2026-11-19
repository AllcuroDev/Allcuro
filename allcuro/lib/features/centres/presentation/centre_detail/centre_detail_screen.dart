import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/allcuro_chip.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/partner_avatar.dart';
import '../../../../core/ui/score_bar.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../../../core/utils/currency.dart';
import '../../data/models/centre.dart';
import 'centre_detail_view_model.dart';

/// Ports `src/routes/centres.$centreId.tsx`.
class CentreDetailScreen extends ConsumerWidget {
  final String centreId;

  const CentreDetailScreen({super.key, required this.centreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centreAsync = ref.watch(centreDetailViewModelProvider(centreId));
    final path = '/centres/$centreId';

    return centreAsync.when(
      loading: () => AppShell(
        currentPath: path,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => _NotFound(path: path),
      data: (centre) => centre == null
          ? _NotFound(path: path)
          : _CentreDetail(centre: centre, path: path),
    );
  }
}

class _NotFound extends StatelessWidget {
  final String path;

  const _NotFound({required this.path});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPath: path,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Centre unavailable',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/centres'),
              child: const Text('Back to centres'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentreDetail extends StatelessWidget {
  final Centre centre;
  final String path;

  const _CentreDetail({required this.centre, required this.path});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentPath: path,
      bottomBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STARTING FROM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  if (centre.pricePerDay <= 0)
                    const Text(
                      'Price on request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                    )
                  else
                  Text.rich(
                    TextSpan(
                      text: inr(centre.pricePerDay),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      children: const [
                        TextSpan(
                          text: ' / day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push('/centre-booking/${centre.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Check Availability',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: NetworkPhoto(url: centre.photo, icon: Icons.apartment_rounded),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Tappable(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/centres');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '←',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              if (centre.photoCount > 1)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '1 / ${centre.photoCount} PHOTOS',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        centre.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [centre.locality, centre.city].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                if (centre.reviews == 0)
                  const Text(
                    'New on ALLCURO · no reviews yet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
                  )
                else
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      centre.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${centre.reviews} verified reviews)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (centre.licence.isNotEmpty)
                      Text(
                        'LICENCE NO. ${centre.licence}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Registered under Clinical Establishment Act',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        [
                          if (centre.since > 0) 'Operating since ${centre.since}',
                          if (centre.staffRatio.isNotEmpty) 'Staff-to-patient ${centre.staffRatio}',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (centre.about.isNotEmpty)
                  _Section(
                    title: 'About',
                    child: Text(
                      centre.about,
                      style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.ink),
                    ),
                  ),
                if (centre.bedsLeft > 0 && centre.bedsLeft <= 3) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Text(
                      'Only ${centre.bedsLeft} beds left this week',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentForeground,
                      ),
                    ),
                  ),
                ],
                if (centre.scores.isNotEmpty)
                _Section(
                  title: 'Quality sub-scores',
                  child: Column(
                    children: centre.scores
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScoreBar(label: s.label, value: s.value),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (centre.roomTypes.isNotEmpty)
                  _Section(
                    title: 'Room types',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: centre.roomTypes.map(AllcuroChip.new).toList(),
                    ),
                  ),
                if (centre.services.isNotEmpty)
                _Section(
                  title: 'Services included',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: centre.services.map(AllcuroChip.new).toList(),
                  ),
                ),
                if (centre.pricePerDay > 0 || centre.pricePerMonth > 0)
                _Section(
                  title: 'Pricing',
                  child: Row(
                    children: [
                      Expanded(
                        child: Surface(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Per day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              Text(
                                centre.pricePerDay > 0 ? inr(centre.pricePerDay) : 'On request',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Surface(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Per month',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              Text(
                                centre.pricePerMonth > 0 ? inr(centre.pricePerMonth) : 'On request',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppColors.ink,
                        ),
                        label: const Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.event_note_outlined,
                          size: 16,
                          color: AppColors.ink,
                        ),
                        label: const Text(
                          'Visit first',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
