import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Shared chrome for a multi-step sign-up wizard: a back button, a linear
/// step-progress bar with "N / total", the current step's content
/// cross-fading in, and a bottom action bar. Used by both the nurse and
/// centre sign-up flows so they read as one consistent pattern.
class WizardScaffold extends StatelessWidget {
  final VoidCallback onBack;
  final int stepIndex;
  final int stepCount;
  final Widget step;
  final Widget bottomBar;

  const WizardScaffold({
    super.key,
    required this.onBack,
    required this.stepIndex,
    required this.stepCount,
    required this.step,
    required this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: onBack),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: (stepIndex + 1) / stepCount,
                          minHeight: 6,
                          backgroundColor: AppColors.primaryForeground.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${stepIndex + 1}/$stepCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryForeground.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(key: ValueKey(stepIndex), child: step),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.2)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: bottomBar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryForeground.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primaryForeground),
        ),
      ),
    );
  }
}

/// A step's title + optional subtitle, in the shared heading style. Every
/// step widget starts with one of these.
class WizardStepHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const WizardStepHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: appHeadingStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.primaryForeground,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.primaryForeground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small uppercase section label used to group fields within a step (e.g.
/// "Identity documents" vs "Educational documents").
class WizardSectionLabel extends StatelessWidget {
  final String label;

  const WizardSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.primaryForeground.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// The pill-shaped bordered text field used throughout the sign-up
/// wizards — a plain-language wrapper around [TextField] so step widgets
/// don't repeat the decoration boilerplate.
class WizardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  /// Read-only with a lock icon — for values that come from a verified ID
  /// and can't be edited.
  final bool locked;

  const WizardTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.primaryForeground.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: locked,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryForeground.withValues(alpha: locked ? 0.75 : 1),
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: locked
                ? Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primaryForeground.withValues(alpha: 0.6))
                : null,
            hintStyle: TextStyle(
              color: AppColors.primaryForeground.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.primaryForeground.withValues(alpha: locked ? 0.06 : 0.12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
              borderSide: locked
                  ? BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25))
                  : const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single-select pill choice — used for gender, employment type,
/// ownership type, etc. across the sign-up wizards.
class WizardChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WizardChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      side: BorderSide(
        color: selected
            ? AppColors.primarySoft
            : AppColors.primaryForeground.withValues(alpha: 0.25),
      ),
    );
    return Material(
      color: selected
          ? AppColors.primaryForeground.withValues(alpha: 0.2)
          : AppColors.primaryForeground.withValues(alpha: 0.08),
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.primaryForeground
                  : AppColors.primaryForeground.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-of-step primary action button — "Continue" on most steps,
/// relabelled ("Submit for verification", etc.) on the last one.
class WizardPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const WizardPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentForeground,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.accentForeground.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accentForeground),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

/// Low-emphasis text action under [WizardPrimaryButton] — e.g. "Skip for now".
class WizardSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const WizardSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Read-only card of details that were fetched from a verified source
/// (Aadhaar e-KYC, a council register) — shown with a check badge so it's
/// clear these can't be edited.
class WizardVerifiedCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const WizardVerifiedCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryForeground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 18, color: AppColors.primarySoft),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryForeground),
                ),
              ),
              Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.primaryForeground.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12.5, color: AppColors.primaryForeground.withValues(alpha: 0.65)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryForeground,
                      ),
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

/// One document-upload row for the sign-up wizards — a dark-glass twin of
/// `core/ui/upload_tile.dart`'s `UploadTile`, which stays opaque-white for
/// its other call site (the main app's document vault, still light-themed).
/// There's no real file picker/storage backend yet — [onTap] is expected to
/// simulate an upload (set a fake file name after a short delay); this
/// widget only renders the state.
class WizardUploadTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final bool uploading;
  final VoidCallback? onTap;

  const WizardUploadTile({
    super.key,
    required this.label,
    this.fileName,
    this.uploading = false,
    this.onTap,
  });

  bool get _uploaded => fileName != null;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xxxl),
      side: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.2)),
    );
    return Material(
      color: AppColors.primaryForeground.withValues(alpha: 0.1),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: uploading ? null : onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _uploaded
                      ? AppColors.success.withValues(alpha: 0.25)
                      : AppColors.primaryForeground.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _uploaded ? Icons.check_circle_rounded : Icons.upload_file_outlined,
                  size: 20,
                  color: _uploaded
                      ? AppColors.primaryForeground
                      : AppColors.primaryForeground.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryForeground,
                      ),
                    ),
                    Text(
                      _uploaded ? fileName! : 'Not uploaded yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _uploaded ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.primaryForeground.withValues(alpha: _uploaded ? 0.9 : 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (uploading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primaryForeground,
                  ),
                )
              else
                Text(
                  _uploaded ? 'Replace' : 'Upload',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primarySoft,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
