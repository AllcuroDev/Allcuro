import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/site_contact.dart';
import '../theme/app_theme.dart';

/// Friendly placeholder for a list with nothing in it yet (e.g. no approved
/// partners). Adds the care-desk number from site settings when known so the
/// customer still has a way to get help.
class EmptyState extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Shows "Call our care desk on …" under the message when a number is set.
  final bool showCareDesk;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.showCareDesk = true,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = showCareDesk ? ref.watch(careDeskPhoneProvider) : '';
    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.mutedForeground),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 14),
              CareDeskButton(phone: phone),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// "Call care desk · +91 …" — copies the number (the app has no dialer
/// plugin) and confirms with a snackbar.
class CareDeskButton extends StatelessWidget {
  final String phone;

  const CareDeskButton({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: phone));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('ALLCURO care desk: $phone (number copied)')),
        );
      },
      icon: const Icon(Icons.call_rounded, size: 16),
      label: Text(
        'Call care desk · $phone',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
