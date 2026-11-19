import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/content/site_contact.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/partner_avatar.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../../bookings/data/models/booking.dart';
import '../../../bookings/presentation/bookings_view_model.dart';
import 'nurse_live_map.dart';

class NurseBookingTrackerScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const NurseBookingTrackerScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<NurseBookingTrackerScreen> createState() =>
      _NurseBookingTrackerScreenState();
}

class _NurseBookingTrackerScreenState
    extends ConsumerState<NurseBookingTrackerScreen> with SingleTickerProviderStateMixin {
  double _userRating = 5.0;
  final _reviewController = TextEditingController();
  bool _reviewSubmitted = false;

  // Simulated trip progress until real GPS pings come from the partner app.
  late final AnimationController _trip = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  )..forward(from: 0.08);

  @override
  void dispose() {
    _trip.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _openFullMap(Booking booking) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NurseLiveMapPage(progress: _trip, nurseName: booking.providerName),
    ));
  }

  void _showRatingModal(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          // Scrolls when the keyboard + large font scale exceed the sheet height.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Rate Your Nursing Experience',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAwaitingNurse(booking)
                      ? 'How was your ALLCURO visit?'
                      : 'How was your session with ${booking.providerName}?',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 36,
                      ),
                      onPressed: () {
                        setModalState(() => _userRating = star.toDouble());
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Write a review for your nurse...',
                    hintText: 'e.g. Very gentle with wound dressing, punctual and caring.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _reviewSubmitted = true);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⭐ Thank you for your feedback! Rating submitted.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    child: const Text('Submit Rating & Review', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    final careDesk = ref.read(careDeskPhoneProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text('Customer SOS Helpdesk', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.destructive)),
            ),
          ],
        ),
        content: const Text(
          'Connecting you with the ALLCURO care desk for immediate assistance. '
          'In a medical emergency, also call 108 for an ambulance.',
          style: TextStyle(fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(careDesk.isEmpty
                      ? 'Please call 108 for an ambulance in an emergency.'
                      : 'ALLCURO care desk: $careDesk'),
                  backgroundColor: AppColors.destructive,
                ),
              );
            },
            icon: const Icon(Icons.phone_in_talk, size: 16),
            label: const Text('Call SOS Helpline'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(singleBookingProvider(widget.bookingId));

    return AppShell(
      currentPath: '/bookings',
      child: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildTopHeader(booking),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The live map only appears once a real nurse is on the way.
                    if (booking.type == BookingType.nurse &&
                        !_isAwaitingNurse(booking) &&
                        booking.liveStatus != BookingLiveStatus.assigned &&
                        booking.liveStatus != BookingLiveStatus.completed) ...[
                      _buildLiveMapCard(booking),
                      const SizedBox(height: 14),
                    ],
                    _buildPatientOtpCard(booking),
                    const SizedBox(height: 14),
                    _buildLiveStepper(booking),
                    const SizedBox(height: 14),
                    _buildNurseProfileCard(booking),
                    const SizedBox(height: 14),
                    _buildLiveVitalsFeed(booking),
                    const SizedBox(height: 14),
                    _buildPatientDetailsCard(booking),
                    const SizedBox(height: 16),
                    _buildFooterActions(booking),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(Booking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/bookings');
              }
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        booking.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                Text(
                  booking.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Tappable(
            onTap: () => _showSosDialog(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.destructive,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMapCard(Booking booking) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: NurseLiveMap(
          progress: _trip,
          nurseName: booking.providerName,
          onExpand: () => _openFullMap(booking),
        ),
      ),
    );
  }

  Widget _buildPatientOtpCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143621), Color(0xFF26593B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'SERVICE VERIFICATION OTP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'CONFIDENTIAL',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 9.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              booking.otp,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share this 4-digit code with your ALLCURO nurse when they arrive, to confirm the visit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStepper(Booking booking) {
    final awaiting = _isAwaitingNurse(booking);
    // Index of the step currently under way (0 = waiting for assignment).
    final current = awaiting
        ? 0
        : switch (booking.liveStatus) {
            BookingLiveStatus.assigned => 1,
            BookingLiveStatus.enRoute => 1,
            BookingLiveStatus.reached => 2,
            BookingLiveStatus.inProgress => 3,
            BookingLiveStatus.completed => 5,
          };
    final steps = [
      (
        'Nurse assigned',
        awaiting ? 'Our care desk is matching a verified nurse for you' : booking.providerName,
      ),
      ('Nurse on the way', 'You will see live tracking here'),
      ('Arrival verified', 'Share your OTP when the nurse arrives'),
      ('Service in progress', 'Vitals and notes are logged by your nurse'),
      ('Service completed', 'Visit summary shared with you'),
    ];
    final statusLabel = awaiting
        ? 'Awaiting nurse'
        : switch (booking.liveStatus) {
            BookingLiveStatus.assigned => 'Nurse assigned',
            BookingLiveStatus.enRoute => 'On the way',
            BookingLiveStatus.reached => 'Arrived',
            BookingLiveStatus.inProgress => 'In progress',
            BookingLiveStatus.completed => 'Completed',
          };
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Visit Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.secondaryAccentBorder, width: 0.8),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.secondaryAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < steps.length; i++)
            _StepTile(
              title: steps[i].$1,
              subtitle: steps[i].$2,
              isDone: i < current,
              isCurrent: i == current,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildNurseProfileCard(Booking booking) {
    final awaiting = _isAwaitingNurse(booking);
    final phone = booking.providerPhone.isNotEmpty ? booking.providerPhone : ref.watch(careDeskPhoneProvider);
    final completed = booking.liveStatus == BookingLiveStatus.completed;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: awaiting || PartnerAvatar.initialsOf(booking.providerName).isEmpty
                    ? const Icon(Icons.medical_services_rounded, color: AppColors.primary)
                    : Text(
                        PartnerAvatar.initialsOf(booking.providerName),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            booking.providerName.isEmpty ? kAssignedNurseLabel : booking.providerName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.success, size: 16),
                      ],
                    ),
                    if (booking.providerQualifications.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        booking.providerQualifications,
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                      ),
                    ],
                    if (booking.providerRating > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            booking.providerRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              if (phone.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(awaiting ? 'ALLCURO care desk: $phone' : 'Call ${booking.providerName}: $phone'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk, size: 16),
                  label: Text(awaiting ? 'Call care desk' : 'Call nurse', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
              if (phone.isNotEmpty && completed) const SizedBox(width: 10),
              if (completed)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRatingModal(context, booking),
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: Text(_reviewSubmitted ? 'Thanks for rating' : 'Rate Nurse', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveVitalsFeed(Booking booking) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.monitor_heart, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Clinical Vitals',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              booking.vitalsSummary ?? 'Vitals will appear here once measured by your nurse.',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard(Booking booking) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient & Service Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
          const SizedBox(height: 10),
          Text(
            [
              booking.patientName.isEmpty ? 'Patient' : booking.patientName,
              if (booking.patientAge > 0 || booking.patientGender.isNotEmpty)
                '(${[if (booking.patientAge > 0) '${booking.patientAge}y', if (booking.patientGender.isNotEmpty) booking.patientGender].join(', ')})',
            ].join(' '),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
          ),
          if ((booking.condition ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(booking.condition!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 4),
          Text(booking.address, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }

  Widget _buildFooterActions(Booking booking) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.go('/bookings'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        child: const Text('Back to My Bookings', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
    );
  }
}

/// True while the care desk has not yet assigned a named nurse.
bool _isAwaitingNurse(Booking booking) =>
    booking.providerName.isEmpty || booking.providerName == kAssignedNurseLabel;

class _StepTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _StepTile({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isCurrent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.secondaryAccent
                    : (isDone ? AppColors.primary : AppColors.secondary),
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: AppColors.secondaryAccentBorder, width: 2.5)
                    : null,
              ),
              child: Icon(
                isCurrent
                    ? Icons.play_arrow_rounded
                    : (isDone ? Icons.check : Icons.circle),
                size: isDone ? 13 : (isCurrent ? 12 : 8),
                color: (isDone || isCurrent) ? Colors.white : AppColors.mutedForeground,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
                    color: isDone ? AppColors.ink : AppColors.mutedForeground,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
