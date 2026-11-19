import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centered message for a screen or list with nothing in it yet (no visit
/// requests, no earnings, no reviews…) — shared across nurse and centre
/// screens so the empty-state look stays consistent. Pass [icon] and
/// [title] for a full-screen empty state; with just [message] it renders as
/// a compact inline note.
class EmptyState extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;

  const EmptyState({super.key, required this.message, this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
            ],
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
