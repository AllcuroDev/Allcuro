import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/care_icon.dart';
import '../data/master_services_catalog.dart';
import '../data/services_repository.dart';

/// Major service category item representation
class MajorServiceItem {
  final String title;
  final String image;
  final String route;
  final String subtitle;
  final String badge;
  final int serviceCount;

  const MajorServiceItem({
    required this.title,
    required this.image,
    required this.route,
    required this.subtitle,
    required this.badge,
    required this.serviceCount,
  });
}

/// Dynamic Category Services Screen displaying either:
/// 1. All Major Services (when category == 'all') matching the home screen style,
///    where clicking any major service navigates into that specific category.
/// 2. The sub-services belonging to a particular category (Nursing, Elder Care, etc.).
class CategoryServicesScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryServicesScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends ConsumerState<CategoryServicesScreen> {
  String _selectedSubcategory = 'All';

  static const List<MajorServiceItem> _allMajorServices = [
    MajorServiceItem(
      title: 'Nursing Services',
      image: CareIllustrations.nursing,
      route: '/category-services/nursing',
      subtitle: 'Catheter, IV, injections, wound care & vital monitoring',
      badge: 'Clinical',
      serviceCount: 18,
    ),
    MajorServiceItem(
      title: 'Mother & Baby',
      image: CareIllustrations.motherBaby,
      route: '/category-services/mother-baby',
      subtitle: 'Postnatal recovery, lactation guidance & newborn care',
      badge: 'Maternal',
      serviceCount: 12,
    ),
    MajorServiceItem(
      title: 'Elder Care',
      image: CareIllustrations.elderCare,
      route: '/category-services/elder-care',
      subtitle: 'Assisted bathing, mobility, daily companionship & support',
      badge: 'Geriatric',
      serviceCount: 14,
    ),
    MajorServiceItem(
      title: 'Physiotherapy',
      image: CareIllustrations.physio,
      route: '/category-services/physiotherapy',
      subtitle: 'Mobility rehab, stroke recovery & post-op therapy',
      badge: 'Rehab',
      serviceCount: 8,
    ),
    MajorServiceItem(
      title: 'Doctor Visit',
      image: CareIllustrations.doctor,
      route: '/category-services/doctor-care',
      subtitle: 'Doctor & geriatric physician consultations at home',
      badge: 'Home Visit',
      serviceCount: 4,
    ),
    MajorServiceItem(
      title: 'Care Centres',
      image: CareIllustrations.careCentre,
      route: '/centres',
      subtitle: 'Verified assisted living, hospice & recovery facilities',
      badge: 'Centres',
      serviceCount: 6,
    ),
    MajorServiceItem(
      title: 'Caregivers',
      image: CareIllustrations.caregiver,
      route: '/category-services/caregiver',
      subtitle: 'Compassionate bedside care, feeding & daily mobility',
      badge: 'Trained',
      serviceCount: 10,
    ),
    MajorServiceItem(
      title: 'Diagnostics & Labs',
      image: CareIllustrations.diagnostics,
      route: '/category-services/diagnostics',
      subtitle: 'Doorstep blood sample collection & home ECG tests',
      badge: 'Doorstep',
      serviceCount: 4,
    ),
    MajorServiceItem(
      title: 'Medical Equipment',
      image: CareIllustrations.equipment,
      route: '/equipment',
      subtitle: 'Rent or buy hospital beds, oxygen & wheelchairs',
      badge: 'Rent/Buy',
      serviceCount: 9,
    ),
    MajorServiceItem(
      title: 'Diet & Wellness',
      image: CareIllustrations.wellness,
      route: '/category-services/wellness',
      subtitle: 'Clinical dietitian meal planning & wellness consultations',
      badge: 'Nutrition',
      serviceCount: 4,
    ),
  ];

  _CategoryMeta _getCategoryMeta(String key) {
    final k = key.toLowerCase().trim();
    if (k.contains('nurs')) {
      return const _CategoryMeta(
        title: 'Nursing Care',
        badge: 'Clinical & Advanced',
        subtitle: 'Verified home nursing, injections, catheter, wound & IV care',
        imageAsset: CareIllustrations.nursing,
        accentColor: AppColors.primary,
      );
    } else if (k.contains('baby') || k.contains('matern') || k.contains('mother')) {
      return const _CategoryMeta(
        title: 'Mother & Baby Care',
        badge: 'Maternal & Newborn',
        subtitle: 'Antenatal visits, postnatal recovery, newborn bath & hygiene',
        imageAsset: CareIllustrations.motherBaby,
        accentColor: Color(0xFF0F766E),
      );
    } else if (k.contains('elder')) {
      return const _CategoryMeta(
        title: 'Elder Care',
        badge: 'Assisted & Dignified',
        subtitle: 'Assisted bathing, mobility, daily companionship & vital monitoring',
        imageAsset: CareIllustrations.elderCare,
        accentColor: Color(0xFFD97706),
      );
    } else if (k.contains('caregiv')) {
      return const _CategoryMeta(
        title: 'Caregivers',
        badge: 'Compassionate Care',
        subtitle: 'Bedside assistance, bathing, mobility, feeding & daily companionship',
        imageAsset: CareIllustrations.caregiver,
        accentColor: Color(0xFFD97706),
      );
    } else if (k.contains('physio')) {
      return const _CategoryMeta(
        title: 'Physiotherapy',
        badge: 'Rehab & Mobility',
        subtitle: 'Comprehensive assessment, stroke recovery & mobility exercises',
        imageAsset: CareIllustrations.physio,
        accentColor: Color(0xFF2563EB),
      );
    } else if (k.contains('doc')) {
      return const _CategoryMeta(
        title: 'Doctor Visit',
        badge: 'Home Consultation',
        subtitle: 'Doctor and geriatric physician consultations at home',
        imageAsset: CareIllustrations.doctor,
        accentColor: Color(0xFF7C3AED),
      );
    } else if (k.contains('diag')) {
      return const _CategoryMeta(
        title: 'Diagnostics & Labs',
        badge: 'Lab at Doorstep',
        subtitle: 'ECG recording and professional blood sample collection',
        imageAsset: CareIllustrations.diagnostics,
        accentColor: Color(0xFF0891B2),
      );
    } else if (k.contains('well')) {
      return const _CategoryMeta(
        title: 'Wellness & Nutrition',
        badge: 'Diet & Lactation',
        subtitle: 'Personalised clinical dietitian and lactation guidance',
        imageAsset: CareIllustrations.wellness,
        accentColor: Color(0xFF059669),
      );
    } else {
      return const _CategoryMeta(
        title: 'All Homecare Services',
        badge: 'Major Services',
        subtitle: 'Explore our complete directory of certified home healthcare services',
        imageAsset: CareIllustrations.seeAll,
        accentColor: AppColors.primary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAll = widget.category.toLowerCase().trim() == 'all' ||
        widget.category.toLowerCase().trim() == 'all-services';

    if (isAll) {
      return _buildAllMajorServicesView(context);
    }

    return _buildSingleCategorySubservicesView(context);
  }

  /// View 1: When user clicks "See All" under Homecare / Healthcare services,
  /// displays ALL major services matching the home screen grid style.
  /// Clicking any major service takes the user into that particular service's sub-services.
  Widget _buildAllMajorServicesView(BuildContext context) {
    return AppShell(
      currentPath: '/category-services/all',
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'All Homecare Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '${_allMajorServices.length} Major Services',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Select any care service to view all available procedures & treatments',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Section Header: Major Services Grid (mirrors Home Screen grid)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Major Services',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Tap to view sub-services',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Grid of ALL Major Services (matching Home Screen 4-column layout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.82,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
              ),
              itemCount: _allMajorServices.length,
              itemBuilder: (context, index) {
                final item = _allMajorServices[index];
                return InkWell(
                  onTap: () => context.push(item.route),
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CareIllustrationTile(asset: item.image),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 4. Detailed Category List with Sub-Service Previews
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: const Text(
              'Browse Care Directory',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.ink,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allMajorServices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _allMajorServices[index];
                return InkWell(
                  onTap: () => context.push(item.route),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CareIllustrationTile(
                          asset: item.image,
                          width: 54,
                          height: 52,
                          radius: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item.serviceCount} Services',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 5. Helpdesk & Support Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSupportBanner(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// View 2: When user clicks on a particular service category,
  /// displays the sub-services inside that category.
  Widget _buildSingleCategorySubservicesView(BuildContext context) {
    final meta = _getCategoryMeta(widget.category);
    ref.watch(servicesCatalogProvider); // rebuild once live services load
    final allCategoryServices = MasterServicesCatalog.getByCategory(widget.category);

    // Extract unique subcategories
    final subcategories = ['All', ...allCategoryServices.map((s) => s.subcategory).toSet()];

    final filteredServices = allCategoryServices
        .where((s) => _selectedSubcategory == 'All' || s.subcategory == _selectedSubcategory)
        .toList();

    return AppShell(
      currentPath: '/category-services/${widget.category}',
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/category-services/all');
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              meta.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '${allCategoryServices.length} Services',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CareIllustrationTile(
                  asset: meta.imageAsset,
                  width: 44,
                  height: 44,
                  radius: 12,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Subcategory Pill Tabs (if multiple)
          if (subcategories.length > 2) ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subcategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final sub = subcategories[i];
                  final isSelected = sub == _selectedSubcategory;
                  return InkWell(
                    onTap: () => setState(() => _selectedSubcategory = sub),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        sub,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. Grid Structure: Sub-Services
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.72,
                crossAxisSpacing: 8,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return _CategoryServiceGridTile(
                  service: service,
                  onTap: () {
                    context.push('/services/${service.id}');
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // 4. Helpdesk & Support Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSupportBanner(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need custom clinical guidance?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.ink),
                ),
                SizedBox(height: 2),
                Text(
                  'Our care coordinators help plan your doctor & nursing regimen',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Metadata describing each top-level service category
class _CategoryMeta {
  final String title;
  final String badge;
  final String subtitle;
  final String imageAsset;
  final Color accentColor;

  const _CategoryMeta({
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.imageAsset,
    required this.accentColor,
  });
}

/// Single Service Tile in the Sub-Services Grid
class _CategoryServiceGridTile extends StatelessWidget {
  final MasterServiceItem service;
  final VoidCallback onTap;

  const _CategoryServiceGridTile({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Stack(
            clipBehavior: Clip.none,
            children: [
              CareIconTile(
                asset: CareIcons.forService(service.id),
                tone: CareTone.forCategory(service.mainCategory),
              ),

              // Micro Badge if available (e.g. Popular, Advanced, Value)
              if (service.badge.isNotEmpty)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: service.badge == 'Advanced'
                          ? const Color(0xFF7C3AED)
                          : (service.badge == 'Popular' ? AppColors.secondaryAccent : AppColors.primary),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      service.badge,
                      style: const TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Title
          Text(
            service.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(height: 3),

          // Price Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              service.price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
