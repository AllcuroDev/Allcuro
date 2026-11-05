import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/utils/currency.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/quick_login_sheet.dart';
import '../../data/models/nurse.dart';
import 'nurses_list_view_model.dart';

class NursesListScreen extends ConsumerStatefulWidget {
  final String? initialService;

  const NursesListScreen({super.key, this.initialService});

  @override
  ConsumerState<NursesListScreen> createState() => _NursesListScreenState();
}

class _NursesListScreenState extends ConsumerState<NursesListScreen> {
  late String _selectedFilter;

  static const _defaultFilters = [
    'All Nurses',
    'Elderly Care',
    'Post-Op Recovery',
    'ICU / Critical Care',
    'Palliative',
    'Pediatric',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialService?.trim().isNotEmpty == true
        ? widget.initialService!.trim()
        : 'All Nurses';
  }

  List<String> get _filters {
    if (widget.initialService != null &&
        widget.initialService!.trim().isNotEmpty &&
        !_defaultFilters.contains(widget.initialService!.trim())) {
      return [widget.initialService!.trim(), ..._defaultFilters];
    }
    return _defaultFilters;
  }

  List<Nurse> _filterNurses(List<Nurse> nurses) {
    if (_selectedFilter == 'All Nurses') {
      return nurses;
    }
    final q = _selectedFilter.toLowerCase();

    return nurses.where((n) {
      final lowerTags = n.tags.map((t) => t.toLowerCase()).toList();
      final lowerLevel = n.level.toLowerCase();
      final lowerHighlights = n.highlights.map((h) => h.toLowerCase()).toList();

      if (q.contains('catheter')) {
        return lowerTags.any((t) => t.contains('catheter'));
      }
      if (q.contains('ryles') || q.contains('tube')) {
        return lowerTags.any((t) => t.contains('ryle') || t.contains('catheter'));
      }
      if (q.contains('wound') || q.contains('dressing')) {
        return lowerTags.any((t) => t.contains('wound'));
      }
      if (q.contains('injection')) {
        return lowerTags.any((t) => t.contains('injection'));
      }
      if (q.contains('iv')) {
        return lowerTags.any((t) => t.contains('iv') || t.contains('cannula'));
      }
      if (q.contains('tracheostomy')) {
        return lowerTags.any((t) => t.contains('tracheostomy') || t.contains('ventilator') || t.contains('icu'));
      }
      if (q.contains('suction')) {
        return lowerTags.any((t) => t.contains('suction') || t.contains('tracheostomy') || t.contains('ventilator') || t.contains('icu'));
      }
      if (q.contains('vital')) {
        return lowerTags.any((t) => t.contains('vital') || t.contains('general nursing'));
      }
      if (q.contains('elder')) {
        return lowerTags.any((t) => t.contains('elder'));
      }
      if (q.contains('post-op')) {
        return lowerTags.any((t) => t.contains('post-op') || t.contains('wound'));
      }
      if (q.contains('icu') || q.contains('critical')) {
        return lowerLevel.contains('critical') || lowerTags.any((t) => t.contains('icu') || t.contains('ventilator'));
      }
      if (q.contains('palliative')) {
        return lowerTags.any((t) => t.contains('palliative'));
      }
      if (q.contains('pediatric') || q.contains('baby') || q.contains('mother')) {
        return lowerTags.any((t) => t.contains('baby') || t.contains('pediatric') || t.contains('mother'));
      }
      if (q.contains('physio')) {
        return lowerLevel.contains('bpt') || lowerTags.any((t) => t.contains('physio'));
      }
      if (q.contains('general')) {
        return lowerTags.any((t) => t.contains('general') || t.contains('vitals') || t.contains('elderly'));
      }
      if (q.contains('nebulization') || q.contains('oxygen')) {
        return lowerTags.any((t) => t.contains('ventilator') || t.contains('general') || t.contains('vitals'));
      }

      return lowerTags.any((t) => t.contains(q)) ||
          lowerLevel.contains(q) ||
          lowerHighlights.any((h) => h.contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nursesAsync = ref.watch(nursesListViewModelProvider);
    final isFiltered = _selectedFilter != 'All Nurses';

    return AppShell(
      currentPath: '/nurses',
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          ScreenHeader(
            title: isFiltered ? '$_selectedFilter Nurses' : 'Nurses & Attendants',
            subtitle: isFiltered
                ? 'Certified nurses specialized in $_selectedFilter'
                : '100% police-verified & background checked care professionals',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _filters[i];
                final isSelected = filter == _selectedFilter;
                return InkWell(
                  onTap: () => setState(() => _selectedFilter = filter),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.secondaryForeground,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          nursesAsync.when(
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
                  'Could not load nurses',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ),
            data: (allNurses) {
              final nurses = _filterNurses(allNurses);

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFiltered) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing ${nurses.length} nurse${nurses.length == 1 ? '' : 's'} qualified for $_selectedFilter',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _selectedFilter = 'All Nurses'),
                              child: const Text(
                                'Show All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (nurses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.person_search_rounded, size: 48, color: AppColors.mutedForeground),
                              const SizedBox(height: 12),
                              Text(
                                'No nurses found for "$_selectedFilter"',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try selecting another specialty or view all nurses',
                                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => setState(() => _selectedFilter = 'All Nurses'),
                                child: const Text('View All Nurses'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...nurses.map((n) => _NurseCard(nurse: n)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NurseCard extends ConsumerWidget {
  final Nurse nurse;

  const _NurseCard({required this.nurse});

  void _handleBooking(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authViewModelProvider);
    final isAuthenticated =
        authState.status == AuthStatus.onboarded || authState.status == AuthStatus.authenticated;

    void proceed() => context.push('/nurse-quick-booking');

    if (isAuthenticated) {
      proceed();
    } else {
      QuickLoginSheet.show(
        context,
        title: 'Quick Login to Book',
        subtitle: 'Enter your phone number to book ${nurse.name}',
        onSuccess: proceed,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = nurse;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Surface(
        onTap: () => context.push('/nurses/${n.id}'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Image.asset(
                    n.photo,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${n.level} · ${n.experience} yrs experience · ${n.employment.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: n.tags.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryForeground,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 4),
                      // One paragraph so it can ellipsize as a unit on
                      // narrow phones / large font scales.
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: '${n.rating}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                            children: [
                              const WidgetSpan(child: SizedBox(width: 4)),
                              TextSpan(
                                text: '(${n.reviews} reviews)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        text: inr(n.shifts.first.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                        children: const [
                          TextSpan(
                            text: ' / shift',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _handleBooking(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
