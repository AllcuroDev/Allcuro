import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A partner's photo from Supabase storage, or their initials when they have
/// none (never a stock photo standing in for a real person).
class PartnerAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  const PartnerAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    this.size = 64,
    this.radius = AppRadius.xl,
    this.fallbackIcon = Icons.person_rounded,
  });

  static String initialsOf(String name) {
    final words = name
        .replaceAll(RegExp(r'^(dr|sister|mr|mrs|ms)\.?\s+', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(w[0]))
        .toList();
    if (words.isEmpty) return '';
    final first = words.first[0];
    final last = words.length > 1 ? words.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name, size: size, icon: fallbackIcon);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: photoUrl.startsWith('http')
            ? Image.network(
                photoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final double size;
  final IconData icon;

  const _Initials({required this.name, required this.size, required this.icon});

  @override
  Widget build(BuildContext context) {
    final initials = PartnerAvatar.initialsOf(name);
    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(icon, size: size * 0.45, color: AppColors.primary)
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
    );
  }
}

/// A catalog/centre photo from a URL, or a neutral placeholder tile.
class NetworkPhoto extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final IconData icon;

  const NetworkPhoto({super.key, required this.url, this.width, this.height, required this.icon});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.muted,
      alignment: Alignment.center,
      child: Icon(icon, size: 32, color: AppColors.mutedForeground),
    );
    if (!url.startsWith('http')) return placeholder;
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
