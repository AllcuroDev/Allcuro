import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../auth/presentation/onboarding_view_model.dart';
import '../signup/nurse_signup_steps_b.dart' show skillTags;
import '../home/nurse_home_view_model.dart';
import '../nurse_providers.dart';

const _days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _shiftTimeOptions = <String>[
  'Morning (08:00 AM – 02:00 PM)',
  'Evening (02:00 PM – 08:00 PM)',
  '12-Hr Day (08:00 AM – 08:00 PM)',
  'Night Shift (08:00 PM – 08:00 AM)',
  '24-Hr Live-in Care',
];

class AvailabilityScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const AvailabilityScreen({super.key, required this.onBack});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  late bool _isOnDuty;
  late String _selectedTiming;

  // Partner-entered: nothing is selected or blocked until the nurse sets it.
  final Set<String> _activeDaySlots = {};
  final List<DateTime> _blockedDates = [];
  late final TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(nurseRepositoryProvider);
    _isOnDuty = repo.isOnDuty;
    _selectedTiming = repo.currentShiftTiming;
    final rate = ref.read(partnerOnboardingProvider).nurseDailyRate;
    _rateController = TextEditingController(text: rate > 0 ? rate.toInt().toString() : '');
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    final current = [...ref.read(partnerOnboardingProvider).nurseSkills];
    if (current.contains(skill)) {
      current.remove(skill);
    } else {
      current.add(skill);
    }
    ref.read(partnerOnboardingProvider.notifier).setNurseSkills(current);
  }

  void _toggleDuty(bool value) async {
    setState(() => _isOnDuty = value);
    await ref.read(nurseHomeViewModelProvider.notifier).toggleDutyStatus(value, timing: _selectedTiming);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '🟢 You are now ON-DUTY and visible to patients.' : '⚪ You are now OFF-DUTY.'),
          backgroundColor: value ? AppColors.success : AppColors.mutedForeground,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectTiming(String timing) async {
    setState(() => _selectedTiming = timing);
    await ref.read(nurseHomeViewModelProvider.notifier).toggleDutyStatus(_isOnDuty, timing: timing);
  }

  void _toggleDaySlot(String day, String slot) {
    final key = '$day-$slot';
    setState(() {
      if (_activeDaySlots.contains(key)) {
        _activeDaySlots.remove(key);
      } else {
        _activeDaySlots.add(key);
      }
    });
  }

  Future<void> _addLeaveDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _blockedDates.add(picked));
    }
  }

  void _removeLeaveDate(int index) {
    setState(() => _blockedDates.removeAt(index));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Duty Status & Availability',
              subtitle: 'Set your shifts, timing slots and leave days',
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _buildDutyToggleCard(),
                  const SizedBox(height: 14),
                  _buildSkillsCard(),
                  const SizedBox(height: 14),
                  _buildDefaultShiftTimingCard(),
                  const SizedBox(height: 14),
                  _buildWeeklySlotGrid(),
                  const SizedBox(height: 14),
                  _buildLeaveDatesCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDutyToggleCard() {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isOnDuty ? AppColors.successSoft : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOnDuty ? Icons.radar_rounded : Icons.pause_circle_outline,
              color: _isOnDuty ? AppColors.success : AppColors.mutedForeground,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isOnDuty ? 'On-Duty (Available)' : 'Off-Duty (Resting)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnDuty ? AppColors.success : AppColors.mutedForeground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isOnDuty ? 'Receiving shift requests for: $_selectedTiming' : 'Paused. You will not get new urgent requests.',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOnDuty,
            onChanged: _toggleDuty,
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    final skills = ref.watch(partnerOnboardingProvider).nurseSkills;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Daily Rate',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick what you are experienced in — this decides which requests you are matched with.',
            style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skillTags
                .map((tag) => _SlotChip(label: tag, selected: skills.contains(tag), onTap: () => _toggleSkill(tag)))
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Expected rate per day (₹)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => ref
                .read(partnerOnboardingProvider.notifier)
                .setNurseDailyRate(double.tryParse(v.trim()) ?? 0),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultShiftTimingCard() {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Preferred Shift Timing',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._shiftTimeOptions.map((opt) {
            final isSelected = _selectedTiming == opt || _selectedTiming.contains(opt.split(' ')[0]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _selectTiming(opt),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.5) : AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDeep : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklySlotGrid() {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Shift Schedule',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap slots to toggle availability for the upcoming week.',
            style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          for (final day in _days)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Morning',
                      'Evening',
                      '12-Hr Day',
                      'Night Shift',
                      '24-Hr',
                    ].map((slot) {
                      final key = '$day-$slot';
                      final isSelected = _activeDaySlots.any((s) => s.startsWith('$day-$slot') || s == key);
                      return _SlotChip(
                        label: slot,
                        selected: isSelected,
                        onTap: () => _toggleDaySlot(day, slot),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveDatesCard() {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Blocked Leave Dates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
              TextButton.icon(
                onPressed: _addLeaveDate,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (_blockedDates.isEmpty)
            const Text('No leave dates blocked.', style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blockedDates.asMap().entries.map((entry) {
                return Chip(
                  label: Text(_formatDate(entry.value), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.secondary,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => _removeLeaveDate(entry.key),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
