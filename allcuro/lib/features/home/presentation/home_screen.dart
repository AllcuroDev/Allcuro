import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/care_icon.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../auth/presentation/quick_login_sheet.dart';

import '../../services/data/master_services_catalog.dart';
import '../../services/data/services_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        subtitle: 'Enter your phone number to proceed with verified booking',
        onSuccess: onAuthenticated,
      );
    }
  }

  void _showAdvisorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFED6C00).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFFED6C00),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Advisory & Help Desk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Speak with an ALLCURO Care Coordinator',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: Color(0xFFED6C00), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Our medical team helps you select the exact clinician, shift duration, or medical care required for your loved one.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C2D12),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connecting to ALLCURO Clinical Helpline (+91 1800-ALLCURO)...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Call Clinical Coordinator Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '24/7 Free Consultation · Instant Response',
                            style: TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening WhatsApp chat with Care Advisory team...'),
                    backgroundColor: Color(0xFF25D366),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat on WhatsApp',
                            style: TextStyle(
                              color: Color(0xFF14532D),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Send prescription or question · Replies in 5 mins',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    ref.watch(servicesCatalogProvider); // rebuild once live services load

    final isGuest = authState.status == AuthStatus.unauthenticated || authState.status == AuthStatus.unknown;
    final userName = authState.userProfile['name'] ?? (isGuest ? 'Guest' : 'Customer');
    final initials = isGuest
        ? '👤'
        : (userName.isNotEmpty ? userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join() : 'AC');


    final matchingMasterServices = _searchQuery.isEmpty
        ? <MasterServiceItem>[]
        : MasterServicesCatalog.allServices.where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.mainCategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.subcategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.includes.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return AppShell(
      currentPath: '/',
      initials: initials,
      onProfileTap: () {
        if (isGuest) {
          QuickLoginSheet.show(
            context,
            title: 'Welcome to ALLCURO',
            subtitle: 'Log in to view your profile and saved bookings',
            onSuccess: () => context.go('/profile'),
          );
        } else {
          context.go('/profile');
        }
      },
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // -----------------------------------------------------------------
          // 1. TOP SEARCH BAR (Clean, modern, prominent)
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search injections, wound dressing, nurses, ICU beds...',
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
                      : Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                          child: const Icon(Icons.tune_rounded, size: 15, color: AppColors.ink),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),

          if (_searchQuery.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Matching Services (${matchingMasterServices.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            if (matchingMasterServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Center(
                  child: Text(
                    'No services found matching your search',
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: matchingMasterServices.length,
                  itemBuilder: (context, index) {
                    final service = matchingMasterServices[index];
                    return _HomeGridItem(
                      title: service.name,
                      icon: CareIcons.forService(service.id),
                      tone: CareTone.forCategory(service.mainCategory),
                      onTap: () => context.push('/services/${service.id}'),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ] else ...[
            // -----------------------------------------------------------------
            // 2. HEALTHCARE SERVICES (Nursing, Mother/Baby, Elder, Physio, Doctor, Centres, Equipments, See All)
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HealthCare Services',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/category-services/all'),
                    child: const Text(
                      'View all ➔',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 4,
                childAspectRatio: 0.82,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
                children: [
                  // 1. Nursing Services
                  _HomeGridItem(
                    title: 'Nursing Services',
                    icon: CareIllustrations.nursing,
                    onTap: () => context.push('/category-services/nursing'),
                  ),
                  // 2. Mother & Baby Care
                  _HomeGridItem(
                    title: 'Mother & Baby',
                    icon: CareIllustrations.motherBaby,
                    onTap: () => context.push('/category-services/mother-baby'),
                  ),
                  // 3. Elder Care
                  _HomeGridItem(
                    title: 'Elder Care',
                    icon: CareIllustrations.elderCare,
                    onTap: () => context.push('/category-services/elder-care'),
                  ),
                  // 4. Physiotherapy
                  _HomeGridItem(
                    title: 'Physiotherapy',
                    icon: CareIllustrations.physio,
                    onTap: () => context.push('/category-services/physiotherapy'),
                  ),
                  // 5. Doctor Visit
                  _HomeGridItem(
                    title: 'Doctor Visit',
                    icon: CareIllustrations.doctor,
                    onTap: () => context.push('/category-services/doctor-care'),
                  ),
                  // 6. Care Centres
                  _HomeGridItem(
                    title: 'Care Centres',
                    icon: CareIllustrations.careCentre,
                    onTap: () => context.push('/centres'),
                  ),
                  // 7. Caregivers
                  _HomeGridItem(
                    title: 'Caregivers',
                    icon: CareIllustrations.caregiver,
                    onTap: () => context.push('/category-services/caregiver'),
                  ),
                  // 8. See All
                  _HomeGridItem(
                    title: 'See All',
                    icon: CareIllustrations.seeAll,
                    isSeeAll: true,
                    onTap: () => context.push('/category-services/all'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 3. QUICK 45-MIN CARE PROMO BANNER (Minimal & Reduced Height)
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ExpressNurseBanner(
                onTap: () => _handleBookingGuard(() => context.push('/nurse-quick-booking')),
              ),
            ),

            const SizedBox(height: 18),

            // -----------------------------------------------------------------
            // 4. OUR NURSE CARE (8 Grid Items: 7 Clinical + 8th See All)
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Our Nurse Care',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.ink,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/category-services/nursing'),
                    child: const Text(
                      'View all ➔',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 4,
                childAspectRatio: 0.82,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
                children: [
                  _HomeGridItem(
                    title: 'Catheter Care',
                    icon: CareIcons.urineBag,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/catheter-care'),
                  ),
                  _HomeGridItem(
                    title: 'Ryles Tube',
                    icon: CareIcons.nasalTube,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/ryle-s-tube-care'),
                  ),
                  _HomeGridItem(
                    title: 'Wound Dressing',
                    icon: CareIcons.bandage,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/wound-dressing'),
                  ),
                  _HomeGridItem(
                    title: 'Injection',
                    icon: CareIcons.injection,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/injection-administration'),
                  ),
                  _HomeGridItem(
                    title: 'IV Care',
                    icon: CareIcons.ivDrip,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/iv-medication-administration'),
                  ),
                  _HomeGridItem(
                    title: 'Tracheostomy',
                    icon: CareIcons.lungs,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/tracheostomy-care'),
                  ),
                  _HomeGridItem(
                    title: 'Vital Monitoring',
                    icon: CareIcons.vitals,
                    tone: CareTone.nursing,
                    onTap: () => context.push('/services/vital-signs-check'),
                  ),
                  _HomeGridItem(
                    title: 'See All',
                    icon: CareIcons.seeAll,
                    tone: CareTone.neutral,
                    isSeeAll: true,
                    onTap: () => context.push('/category-services/nursing'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 22),

          // -----------------------------------------------------------------
          // 5. BANNER: EXPLORE OUR HEALTH CARE CENTRES
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CentresBanner(onTap: () => context.push('/centres')),
          ),
        ],

          // 4b. TALK TO OUR TEAM ADVISORY BANNER (Directly below Explore Health Care Centres)
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => _showAdvisorySheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF7ED),
                      Color(0xFFFFEDD5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: const Color(0xFFFED7AA),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFED6C00).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFED6C00),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFED6C00).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Talk to Our Team',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFED6C00),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Need advice or help choosing care? Speak with our clinical coordinators.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF7C2D12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED6C00).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: Color(0xFFED6C00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 5. POPULAR QUICK PROCEDURES AT HOME (30-Min & Hourly Direct Care)
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Popular Procedures at Home',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    Text(
                      '30m & 1h visits · Sterile kits · Fast arrival',
                      style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => context.push('/category-services/nursing'),
                  child: const Text(
                    'View all ➔',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickProcedureCard(
                        title: 'Injection & IV Care',
                        duration: '30 Mins',
                        icon: CareIcons.injection,
                        tag: 'Quick Visit',
                        onTap: () => context.push('/category-services/nursing'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickProcedureCard(
                        title: 'Wound Dressing',
                        duration: '45 Mins',
                        icon: CareIcons.bandage,
                        tag: 'Post-Op / Bedsores',
                        onTap: () => context.push('/category-services/nursing'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickProcedureCard(
                        title: 'Catheter / Tube Care',
                        duration: '45 Mins',
                        icon: CareIcons.urineBag,
                        tag: 'Sterile Care',
                        onTap: () => context.push('/category-services/nursing'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickProcedureCard(
                        title: 'Elderly Caregiver',
                        duration: '1h / Custom Shift',
                        icon: CareIcons.caregiver,
                        tag: 'Daily Assistance',
                        onTap: () => context.push('/category-services/caregiver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 6. HOW HOME CARE WORKS (3-step stepper)
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'How Home Care Works',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                Text(
                  'Hospital-standard medical attention in 3 simple steps',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _HowItWorksStep(
                  title: 'Choose service & duration',
                  subtitle: '30-min quick visits, hourly attention, or full 12/24-hour shifts.',
                  icon: CareIcons.clipboard,
                ),
                _HowItWorksStep(
                  title: 'Verified clinician assigned',
                  subtitle: 'A degree-certified, police-verified nurse or caregiver comes to your door.',
                  icon: CareIcons.nursing,
                ),
                _HowItWorksStep(
                  title: 'Supervised care at home',
                  subtitle: 'Real-time vitals logging with a senior medical supervisor on call.',
                  icon: CareIcons.homeNurse,
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 7. WHY FAMILIES TRUST ALLCURO (Trust & Safety Guarantees)
          // -----------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Why Families Trust ALLCURO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                Text(
                  'Clinical excellence, patient dignity, and rigorous safety protocols',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: const [
                Row(
                  children: [
                    Expanded(
                      child: _WhyTrustCard(
                        icon: Icons.shield_rounded,
                        iconColor: Color(0xFF10B981),
                        title: '100% Verified',
                        subtitle: 'Police & State Nursing Council verified credentials',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _WhyTrustCard(
                        icon: Icons.access_time_filled_rounded,
                        iconColor: Color(0xFF0284C7),
                        title: 'Flexible Slots',
                        subtitle: '30 min quick care, custom hours, or full shifts',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _WhyTrustCard(
                        icon: Icons.payments_rounded,
                        iconColor: Color(0xFFED6C00),
                        title: 'Transparent Pricing',
                        subtitle: 'Standardized rates with zero hidden hospital markups',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _WhyTrustCard(
                        icon: Icons.medical_services_rounded,
                        iconColor: Color(0xFF8B5CF6),
                        title: 'Clinical Oversight',
                        subtitle: 'Continuous doctor & nursing supervisor on call',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 8. ALLCURO BRANDING, ICON & TRUST FOOTER (At the Bottom of App)
          // -----------------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                // ALLCURO Icon & Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.monitor_heart_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ALLCURO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Healthcare, Made Simple.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 20),

                // Trust Grid Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TrustBadgeItem(
                      icon: Icons.verified_user_rounded,
                      title: '100% Verified',
                      subtitle: 'HPR & Background Checked',
                    ),
                    _TrustBadgeItem(
                      icon: Icons.apartment_rounded,
                      title: 'Audited Centres',
                      subtitle: 'Quality Inspected',
                    ),
                    _TrustBadgeItem(
                      icon: Icons.support_agent_rounded,
                      title: '24/7 Clinical Desk',
                      subtitle: 'Emergency Support',
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 14),

                Text(
                  '© 2026 ALLCURO Healthcare Technologies Pvt. Ltd.\nAyushman Bharat Digital Mission (ABDM) Compliant Partner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.mutedForeground.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME GRID ITEM (Nurse Care & Healthcare Services Grid)
// ---------------------------------------------------------------------------
class _HomeGridItem extends StatelessWidget {
  final String title;

  /// A [CareIllustrations] asset, or a [CareIcons] glyph when [tone] is set.
  final String icon;

  /// Tints a line-icon tile; leave null to show a category illustration.
  final CareTone? tone;
  final VoidCallback onTap;
  final bool isSeeAll;

  const _HomeGridItem({
    required this.title,
    required this.icon,
    this.tone,
    required this.onTap,
    this.isSeeAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tone == null ? CareIllustrationTile(asset: icon) : CareIconTile(asset: icon, tone: tone!),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSeeAll ? FontWeight.w700 : FontWeight.w500,
              height: 1.18,
              color: isSeeAll ? AppColors.primary : const Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// EXPRESS 45-MIN NURSE BANNER (saffron gradient, shimmer sweep, pulsing bolt,
// rotating live ticker, press feedback)
// ---------------------------------------------------------------------------
class _ExpressNurseBanner extends StatefulWidget {
  final VoidCallback onTap;

  const _ExpressNurseBanner({required this.onTap});

  @override
  State<_ExpressNurseBanner> createState() => _ExpressNurseBannerState();
}

class _ExpressNurseBannerState extends State<_ExpressNurseBanner> with TickerProviderStateMixin {
  static const _saffron = Color(0xFFEE6D01);
  static const _saffronLight = Color(0xFFFF9A3C);
  static const _saffronDeep = Color(0xFFC85A00);

  static const _tickerLines = [
    '12 nurses available near you',
    'Avg. arrival today · 32 mins',
    'GNM / ANM verified · HPR registered',
  ];

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();
  Timer? _tickerTimer;
  int _tickerIndex = 0;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _tickerIndex = (_tickerIndex + 1) % _tickerLines.length);
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_saffronLight, _saffron, _saffronDeep],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _saffron.withValues(alpha: _pressed ? 0.18 : 0.32),
                blurRadius: _pressed ? 8 : 18,
                offset: Offset(0, _pressed ? 3 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              children: [
                // Decorative rings
                Positioned(
                  right: -30,
                  top: -40,
                  child: _ring(130, 0.10),
                ),
                Positioned(
                  right: 40,
                  bottom: -50,
                  child: _ring(100, 0.08),
                ),
                // Shimmer sweep
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, _) {
                      final t = _shimmer.value * 2.4 - 0.7;
                      return IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(t - 0.4, -1),
                              end: Alignment(t + 0.4, 1),
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      _buildBolt(),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCopy()),
                      const SizedBox(width: 8),
                      _buildCta(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: alpha), width: 14),
        ),
      );

  Widget _buildBolt() {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Transform.scale(
              scale: 0.75 + 0.45 * _pulse.value,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35 * (1 - _pulse.value)),
                ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _saffronDeep.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: const CareIcon(CareIcons.quick, color: _saffron, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCopy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Text(
            'EXPRESS CARE',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Need a nurse in 45 mins?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFB9F6CA),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB9F6CA).withValues(alpha: 0.8 * (1 - _pulse.value)),
                      blurRadius: 6,
                      spreadRadius: 2 * _pulse.value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  _tickerLines[_tickerIndex],
                  key: ValueKey(_tickerIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCta() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.translate(
        offset: Offset(2 * (1 - (2 * _pulse.value - 1).abs()), 0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(color: _saffronDeep.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Book',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: _saffronDeep),
            ),
            SizedBox(width: 3),
            Icon(Icons.arrow_forward_rounded, size: 15, color: _saffronDeep),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXPLORE HEALTH CARE CENTRES BANNER (photo card with brand-green scrim)
// ---------------------------------------------------------------------------
class _CentresBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CentresBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        height: 156,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/centre-1.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.4, 0),
              cacheWidth: 900,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xF20C341E), Color(0xB30C341E), Color(0x000C341E)],
                  stops: [0.0, 0.5, 0.95],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFFBBF7D0)),
                        SizedBox(width: 4),
                        Text(
                          'Field audited',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Explore Health Care\nCentres',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ICU step-down, rehab & senior living',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFD7EBDD)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View centres',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QUICK PROCEDURE CARD
// ---------------------------------------------------------------------------
class _QuickProcedureCard extends StatelessWidget {
  final String title;
  final String duration;
  final String icon;
  final String tag;
  final VoidCallback onTap;

  const _QuickProcedureCard({
    required this.title,
    required this.duration,
    required this.icon,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: CareIcon(icon, color: AppColors.primary, size: 21),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              tag,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOW IT WORKS STEP
// ---------------------------------------------------------------------------
class _HowItWorksStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final bool isLast;

  const _HowItWorksStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail: icon node + connector to the next step
          SizedBox(
            width: 40,
            child: Column(
              children: [
                CareIconTile(
                  asset: icon,
                  tone: CareTone.nursing,
                  width: 40,
                  height: 40,
                  iconSize: 22,
                  radius: 20,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WHY TRUST US CARD
// ---------------------------------------------------------------------------
class _WhyTrustCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _WhyTrustCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.mutedForeground,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TRUST BADGE FOOTER ITEM
// ---------------------------------------------------------------------------
class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustBadgeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink)),
        Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AppColors.mutedForeground)),
      ],
    );
  }
}
