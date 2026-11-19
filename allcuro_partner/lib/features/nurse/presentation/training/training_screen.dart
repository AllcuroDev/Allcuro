import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';

class _Course {
  final String title;
  final String duration;
  final int progress;

  const _Course({
    required this.title,
    required this.duration,
    required this.progress,
  });

  _Course copyWith({int? progress}) => _Course(
        title: title,
        duration: duration,
        progress: progress ?? this.progress,
      );
}

/// Nurse's training & certification screen — a demo-only list of
/// micro-courses pushed from the "More tools" grid. "Continue" just bumps
/// the local progress state; there's no real course player wired up.
class TrainingScreen extends StatefulWidget {
  final VoidCallback onBack;

  const TrainingScreen({super.key, required this.onBack});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final List<_Course> _courses = [
    _Course(title: 'Wound care essentials', duration: '45 min', progress: 0),
    _Course(title: 'Medication administration', duration: '30 min', progress: 0),
    _Course(title: 'Elderly mobility support', duration: '50 min', progress: 0),
    _Course(title: 'Infection control basics', duration: '25 min', progress: 0),
    _Course(title: 'Post-op recovery care', duration: '40 min', progress: 0),
  ];

  void _continue(int index) {
    setState(() {
      final current = _courses[index];
      final next = (current.progress + 25).clamp(0, 100);
      _courses[index] = current.copyWith(progress: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Training & certification',
              subtitle: 'Micro-courses that unlock skill-based pricing tiers',
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: _courses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final certified = course.progress >= 100;
                  return Surface(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                course.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (certified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: const Text(
                                  'Certified ✓',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () => _continue(index),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.duration,
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: course.progress / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.secondary,
                            color: certified ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
