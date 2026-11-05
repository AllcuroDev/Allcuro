import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/scaled_tile_grid_delegate.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../auth/presentation/quick_login_sheet.dart';

class NurseServiceGridItem {
  final String id;
  final String name;
  final String category;
  final String query;
  final String? imageAsset;
  final IconData? icon;
  final String subtitle;

  const NurseServiceGridItem({
    required this.id,
    required this.name,
    required this.category,
    required this.query,
    this.imageAsset,
    this.icon,
    required this.subtitle,
  });
}

class AllNurseServicesScreen extends ConsumerStatefulWidget {
  const AllNurseServicesScreen({super.key});

  @override
  ConsumerState<AllNurseServicesScreen> createState() => _AllNurseServicesScreenState();
}

class _AllNurseServicesScreenState extends ConsumerState<AllNurseServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<NurseServiceGridItem> _services = [
    NurseServiceGridItem(
      id: 'catheter-care',
      name: 'Catheter Care',
      category: 'Clinical Care',
      query: 'Catheter Care',
      imageAsset: 'assets/images/services/catheter_care.jpg',
      icon: Icons.medical_services_rounded,
      subtitle: 'Foley insertion & sterile bag change',
    ),
    NurseServiceGridItem(
      id: 'ryles-tube',
      name: 'Ryles Tube',
      category: 'Clinical Care',
      query: 'Ryles Tube',
      imageAsset: 'assets/images/services/ryles_tube.jpg',
      icon: Icons.medication_liquid_rounded,
      subtitle: 'NG tube insertion & feeding support',
    ),
    NurseServiceGridItem(
      id: 'wound-dressing',
      name: 'Wound Dressing',
      category: 'Clinical Care',
      query: 'Wound Dressing',
      imageAsset: 'assets/images/services/wound_dressing.jpg',
      icon: Icons.healing_rounded,
      subtitle: 'Surgical & ulcer sterile dressings',
    ),
    NurseServiceGridItem(
      id: 'injection',
      name: 'Injection',
      category: 'Clinical Care',
      query: 'Injection',
      imageAsset: 'assets/images/services/injection.jpg',
      icon: Icons.vaccines_rounded,
      subtitle: 'IM, SC & prescribed insulin doses',
    ),
    NurseServiceGridItem(
      id: 'iv-care',
      name: 'IV Care',
      category: 'Clinical Care',
      query: 'IV Care',
      imageAsset: 'assets/images/services/iv_care.jpg',
      icon: Icons.water_drop_rounded,
      subtitle: 'Cannula insertion & saline drip infusion',
    ),
    NurseServiceGridItem(
      id: 'tracheostomy',
      name: 'Tracheostomy',
      category: 'Critical & Post-Op',
      query: 'Tracheostomy',
      imageAsset: 'assets/images/services/tracheostomy.jpg',
      icon: Icons.masks_rounded,
      subtitle: 'Inner cannula cleansing & suctioning',
    ),
    NurseServiceGridItem(
      id: 'suction',
      name: 'Suction Care',
      category: 'Critical & Post-Op',
      query: 'Suction',
      icon: Icons.air_rounded,
      subtitle: 'Oral, nasal & endotracheal clearance',
    ),
    NurseServiceGridItem(
      id: 'post-op',
      name: 'Post-Op Care',
      category: 'Critical & Post-Op',
      query: 'Post-Op',
      imageAsset: 'assets/images/services/wound_dressing.jpg',
      icon: Icons.health_and_safety_rounded,
      subtitle: 'Suture removal & post-surgery recovery',
    ),
    NurseServiceGridItem(
      id: 'vital-monitoring',
      name: 'Vital Monitoring',
      category: 'General & Support',
      query: 'Vital Monitoring',
      imageAsset: 'assets/images/services/vital_monitoring.jpg',
      icon: Icons.monitor_heart_rounded,
      subtitle: 'BP, Sugar, SpO2 & vitals assessment',
    ),
    NurseServiceGridItem(
      id: 'mother-and-baby',
      name: 'Mother & Baby',
      category: 'Maternal & Newborn',
      query: 'Mother & Baby',
      imageAsset: 'assets/images/services/baby_care.jpg',
      icon: Icons.child_care_rounded,
      subtitle: 'Newborn bath, lactation & mother care',
    ),
    NurseServiceGridItem(
      id: 'general-nursing',
      name: 'General Nursing',
      category: 'General & Support',
      query: 'General Nursing',
      imageAsset: 'assets/images/services/nursing_services.jpg',
      icon: Icons.medical_information_rounded,
      subtitle: 'Routine bedside care & medication timing',
    ),
    NurseServiceGridItem(
      id: 'physiotherapy',
      name: 'Physiotherapy',
      category: 'Rehabilitation',
      query: 'Physiotherapy',
      imageAsset: 'assets/images/services/physiotherapy.jpg',
      icon: Icons.accessibility_new_rounded,
      subtitle: 'Neuro, orthopedic & mobility therapy',
    ),
    NurseServiceGridItem(
      id: 'elderly-care',
      name: 'Elderly Care',
      category: 'General & Support',
      query: 'Elderly Care',
      imageAsset: 'assets/images/services/care_centres.jpg',
      icon: Icons.elderly_rounded,
      subtitle: 'Assisted hygiene, mobility & companionship',
    ),
    NurseServiceGridItem(
      id: 'nebulization',
      name: 'Nebulization',
      category: 'Clinical Care',
      query: 'Nebulization',
      icon: Icons.air_outlined,
      subtitle: 'Bronchodilator aerosol & oxygen titration',
    ),
    NurseServiceGridItem(
      id: 'icu-critical',
      name: 'ICU Critical Care',
      category: 'Critical & Post-Op',
      query: 'ICU / Critical Care',
      icon: Icons.local_hospital_rounded,
      subtitle: 'Ventilator management & stepdown care',
    ),
    NurseServiceGridItem(
      id: 'palliative',
      name: 'Palliative Care',
      category: 'General & Support',
      query: 'Palliative',
      icon: Icons.favorite_rounded,
      subtitle: 'Pain relief & compassionate comfort care',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBookingGuard(VoidCallback onAuthenticated) {
    final authState = ref.read(authViewModelProvider);
    final isAuthenticated = authState.status == AuthStatus.onboarded || authState.status == AuthStatus.authenticated;

    if (isAuthenticated) {
      onAuthenticated();
    } else {
      QuickLoginSheet.show(
        context,
        title: 'Quick Login to Book',
        subtitle: 'Enter your phone number to proceed with verified nurse booking',
        onSuccess: onAuthenticated,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Clinical Care',
      'Critical & Post-Op',
      'General & Support',
      'Maternal & Newborn',
      'Rehabilitation',
    ];

    final filtered = _services.where((item) {
      final matchesCat = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.query.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();

    return AppShell(
      currentPath: '/nurse-services',
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Nurse Care Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Select a service to view specialized verified nurses',
                        style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: 'Search catheter, ryles tube, wound, IV...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.mutedForeground),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedForeground, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.mutedForeground),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Category Pills
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.card,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Service Items Grid (Identical layout & styling to Home screen)
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: AppColors.mutedForeground.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No matching clinical services found',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Try searching with keywords like catheter, wound, or injection',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                // Icon box (68) + gap (8) + two label lines.
                gridDelegate: ScaledTileGridDelegate(
                  crossAxisCount: 4,
                  childAspectRatio: 0.70,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 14,
                  minTileHeight: labelTileHeight(context, fixedHeight: 68 + 8, fontSize: 11.5, lineHeight: 1.18),
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _ServiceGridTile(
                    title: item.name,
                    imageAsset: item.imageAsset,
                    icon: item.icon,
                    onTap: () {
                      context.push('/nurses?service=${Uri.encodeComponent(item.query)}');
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 24),

          // Urgent Nurse Assistance Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need nurse in 30–45 mins?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Instant dispatch of nearby verified nurses',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _handleBookingGuard(() => context.push('/nurse-quick-booking'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Book Express', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SERVICE GRID TILE (Matches Home Screen Grid Item Aesthetic Exactly)
// ---------------------------------------------------------------------------
class _ServiceGridTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final String? imageAsset;

  const _ServiceGridTile({
    required this.title,
    this.icon,
    required this.onTap,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 68,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Center(
              child: imageAsset != null
                  ? Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      cacheWidth: 150,
                      cacheHeight: 150,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => Icon(
                        icon ?? Icons.medical_services_rounded,
                        size: 28,
                        color: const Color(0xFF475569),
                      ),
                    )
                  : Icon(
                      icon ?? Icons.medical_services_rounded,
                      size: 28,
                      color: const Color(0xFF475569),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.18,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
