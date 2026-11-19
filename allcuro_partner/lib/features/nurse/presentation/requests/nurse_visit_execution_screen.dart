import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../data/models/nurse_visit_model.dart';
import 'nurse_visit_view_model.dart';

class NurseVisitExecutionScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NurseVisitExecutionScreen({
    super.key,
    required this.onBack,
  });

  @override
  ConsumerState<NurseVisitExecutionScreen> createState() =>
      _NurseVisitExecutionScreenState();
}

class _NurseVisitExecutionScreenState
    extends ConsumerState<NurseVisitExecutionScreen> {
  // Vital logging controllers
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _sugarController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();

  // OTP controller for completion
  final _otpController = TextEditingController();
  String? _otpError;
  bool _isCompleting = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Re-render every second so the elapsed-time clock ticks.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  /// Seconds since check-in, from the visit's real check-in time.
  int _elapsedSince(DateTime? from, [DateTime? to]) {
    if (from == null) return 0;
    return (to ?? DateTime.now()).difference(from).inSeconds.clamp(0, 1 << 31);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bpController.dispose();
    _pulseController.dispose();
    _sugarController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showEmergencySosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.sosRedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.sosRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Emergency SOS',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.sosRed, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Triggering SOS will broadcast your live GPS location to ALLCURO Emergency Response HQ and dial 24x7 clinical support.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your current location will be shared with the response team.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                const SnackBar(
                  content: Text('🚨 SOS Alert Dispatched! ALLCURO Team is dialing you.'),
                  backgroundColor: AppColors.sosRed,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.phone_in_talk, size: 16),
            label: const Text('Call Allcuro SOS Desk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtpModal(BuildContext context, NurseVisit visit) {
    _otpController.clear();
    setState(() => _otpError = null);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Visit & Check-Out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        Text(
                          'Ask the patient / family for their 4-digit completion OTP',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '• • • •',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.background,
                  errorText: _otpError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleting
                      ? null
                      : () async {
                          final code = _otpController.text.trim();
                          if (code.length != 4) {
                            setModalState(() => _otpError = 'Please enter a 4-digit OTP');
                            return;
                          }
                          setModalState(() => _isCompleting = true);
                          final success = await ref
                              .read(nurseVisitViewModelProvider.notifier)
                              .verifyAndCompleteWithOtp(code);
                          setModalState(() => _isCompleting = false);

                          if (success && context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Visit completed and checked out.'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else {
                            setModalState(() => _otpError = 'Invalid OTP. Please verify with patient.');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  child: _isCompleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Verify OTP & Finalise Shift',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitAsync = ref.watch(nurseVisitViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: visitAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error loading visit: $err')),
          data: (visit) => visit == null
              ? Column(
                  children: [
                    ScreenHeader(title: 'Active visit', onBack: widget.onBack),
                    const Expanded(
                      child: EmptyState(
                        icon: Icons.medical_services_outlined,
                        title: 'No active visit',
                        message: "When you accept a booking and start the visit, you'll check in and log care here.",
                      ),
                    ),
                  ],
                )
              : Column(
            children: [
              _buildTopHeader(visit),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  children: [
                    _buildPatientOverviewCard(visit),
                    const SizedBox(height: 14),
                    _buildVerificationAndArrivalCard(visit),
                    const SizedBox(height: 14),
                    _buildTimeTrackingCard(visit),
                    const SizedBox(height: 14),
                    _buildVitalSignsLogger(visit),
                    const SizedBox(height: 14),
                    _buildClinicalChecklistCard(visit),
                    const SizedBox(height: 20),
                    _buildActionFooter(visit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(NurseVisit visit) {
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
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      visit.bookingId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: visit.status == VisitStatus.completed
                            ? AppColors.successSoft
                            : (visit.status == VisitStatus.inProgress
                                ? AppColors.coralSoft
                                : AppColors.amberSoft),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        visit.status == VisitStatus.completed
                            ? 'COMPLETED'
                            : (visit.status == VisitStatus.inProgress
                                ? 'IN PROGRESS'
                                : (visit.status == VisitStatus.reached ? 'REACHED' : 'EN ROUTE')),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: visit.status == VisitStatus.completed
                              ? AppColors.success
                              : (visit.status == VisitStatus.inProgress ? AppColors.coral : AppColors.warning),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  visit.serviceType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          // Panic SOS Button
          Tappable(
            onTap: () => _showEmergencySosDialog(context),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sosRed,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sosRed.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'SOS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientOverviewCard(NurseVisit visit) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  visit.patientName.split(' ').map((e) => e[0]).take(2).join(),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${visit.patientName} (${visit.patientAge}y, ${visit.patientGender})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.medicalCondition,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.coral),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.address,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.3),
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
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📍 Opening Google Maps route to ${visit.address}...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation_outlined, size: 16, color: AppColors.primary),
                  label: const Text('Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📞 Dialing patient family: ${visit.patientPhone}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk, size: 16),
                  label: const Text('Call Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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

  Widget _buildVerificationAndArrivalCard(NurseVisit visit) {
    final isReached = visit.status != VisitStatus.assigned && visit.status != VisitStatus.enRoute;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pin_drop_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Arrival Verification & GPS Check',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
              ),
              const Spacer(),
              if (isReached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 12),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VerificationBadge(
                  title: 'GPS Geofence',
                  subtitle: isReached ? 'Within 30m of patient' : 'Required upon arrival',
                  isDone: visit.isGpsVerified || isReached,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerificationBadge(
                  title: 'Selfie Check',
                  subtitle: isReached ? 'Face match passed' : 'Mandatory live check',
                  isDone: visit.isSelfieVerified || isReached,
                ),
              ),
            ],
          ),
          if (!isReached) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(nurseVisitViewModelProvider.notifier).verifyArrivalAndSelfie();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Arrival GPS & Live Selfie Verified! You can now check in.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text("I've Reached — Take Selfie & Verify GPS", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTrackingCard(NurseVisit visit) {
    final isInProgress = visit.status == VisitStatus.inProgress;
    final isCompleted = visit.status == VisitStatus.completed;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isInProgress ? AppColors.coralSoft : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: isInProgress ? AppColors.coral : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Shift Duration' : (isInProgress ? 'Clinical Timer Running' : 'Shift Status'),
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isInProgress
                      ? _formatTimer(_elapsedSince(visit.checkInTime))
                      : (isCompleted
                          ? _formatTimer(_elapsedSince(visit.checkInTime, visit.checkOutTime))
                          : 'Not checked in yet'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isInProgress ? AppColors.coral : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (visit.status == VisitStatus.reached)
            ElevatedButton(
              onPressed: () async {
                await ref.read(nurseVisitViewModelProvider.notifier).checkIn();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⏱️ Checked-in! Clinical timer has started.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsLogger(NurseVisit visit) {
    final vitals = visit.vitalsLog;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline, color: AppColors.coral, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Digital Vitals Logging',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
              ),
              const Spacer(),
              if (vitals != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text('Logged', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VitalInputCell(
                  label: 'BP (mmHg)',
                  controller: _bpController,
                  hint: '120/80',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalInputCell(
                  label: 'Pulse (bpm)',
                  controller: _pulseController,
                  hint: '72',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalInputCell(
                  label: 'Sugar (mg/dL)',
                  controller: _sugarController,
                  hint: '110',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VitalInputCell(
                  label: 'Temp (°F)',
                  controller: _tempController,
                  hint: '98.6',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VitalInputCell(
                  label: 'SpO2 (%)',
                  controller: _spo2Controller,
                  hint: '99',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final pulse = int.tryParse(_pulseController.text.trim());
                    final sugar = int.tryParse(_sugarController.text.trim());
                    final temp = double.tryParse(_tempController.text.trim());
                    final spo2 = int.tryParse(_spo2Controller.text.trim());
                    if (_bpController.text.trim().isEmpty ||
                        pulse == null ||
                        sugar == null ||
                        temp == null ||
                        spo2 == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter all vitals before saving.')),
                      );
                      return;
                    }

                    final log = VitalSignsLog(
                      bloodPressure: _bpController.text.trim(),
                      pulse: pulse,
                      bloodSugar: sugar,
                      temperature: temp,
                      spO2: spo2,
                      loggedAt: DateTime.now(),
                    );
                    await ref.read(nurseVisitViewModelProvider.notifier).logVitals(log);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vitals recorded.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Save Vitals', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalChecklistCard(NurseVisit visit) {
    final c = visit.checklist;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinical Checklist & Procedures',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
              ),
              Text(
                '${c.completedCount}/${c.totalCount} Done',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ChecklistRow(
            title: 'Vital signs logged (BP, Sugar, Pulse, Temp)',
            isDone: c.vitalsLogged,
            onChanged: (val) {
              ref.read(nurseVisitViewModelProvider.notifier).updateChecklist(
                    c.copyWith(vitalsLogged: val ?? false),
                  );
            },
          ),
          _ChecklistRow(
            title: 'Administering IV antibiotics (Cefuroxime)',
            isDone: c.ivAntibioticsAdministered,
            onChanged: (val) {
              ref.read(nurseVisitViewModelProvider.notifier).updateChecklist(
                    c.copyWith(ivAntibioticsAdministered: val ?? false),
                  );
            },
          ),
          _ChecklistRow(
            title: 'Dressing changes for surgical wounds',
            isDone: c.surgicalWoundDressed,
            onChanged: (val) {
              ref.read(nurseVisitViewModelProvider.notifier).updateChecklist(
                    c.copyWith(surgicalWoundDressed: val ?? false),
                  );
            },
          ),
          _ChecklistRow(
            title: 'Toilet care assistance & personal hygiene',
            isDone: c.toiletCareAssisted,
            onChanged: (val) {
              ref.read(nurseVisitViewModelProvider.notifier).updateChecklist(
                    c.copyWith(toiletCareAssisted: val ?? false),
                  );
            },
          ),
          _ChecklistRow(
            title: 'Injections & IV drip monitoring',
            isDone: c.injectionsGiven,
            onChanged: (val) {
              ref.read(nurseVisitViewModelProvider.notifier).updateChecklist(
                    c.copyWith(injectionsGiven: val ?? false),
                  );
            },
          ),
          _ChecklistRow(
            title: 'Exercise & physiotherapy support',
            isDone: c.exerciseMobilitySupported,
            onChanged: (val) {
              ref.read(nurseVisitViewModelProvider.notifier).updateChecklist(
                    c.copyWith(exerciseMobilitySupported: val ?? false),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(NurseVisit visit) {
    if (visit.status == VisitStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift Completed Successfully', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
                  Text('Payment verified & report filed with Allcuro ops.', style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showOtpModal(context, visit),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock, size: 18),
            SizedBox(width: 8),
            Text(
              'Complete Visit & Enter Patient OTP',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;

  const _VerificationBadge({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone ? AppColors.successSoft.withValues(alpha: 0.5) : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDone ? AppColors.success : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isDone ? AppColors.success : AppColors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AppColors.mutedForeground), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalInputCell extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _VitalInputCell({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String title;
  final bool isDone;
  final ValueChanged<bool?> onChanged;

  const _ChecklistRow({
    required this.title,
    required this.isDone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isDone,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                color: isDone ? AppColors.ink : AppColors.mutedForeground,
                decoration: isDone ? TextDecoration.none : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
