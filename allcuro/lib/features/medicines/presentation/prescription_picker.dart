import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'medicine_cart_view_model.dart';

const _maxBytes = 10 * 1024 * 1024;

/// Lets the user pick a prescription (photo or PDF), checks its size and
/// starts the pharmacist review. Returns true when a file was attached.
Future<bool> pickPrescription(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<FileType>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return false;

  PlatformFile? file;
  try {
    file = source == FileType.image
        ? await FilePicker.pickFile(type: FileType.image)
        : await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png']);
  } catch (_) {
    if (context.mounted) _snack(context, 'Could not open your files. Please try again.');
    return false;
  }
  if (file == null || !context.mounted) return false;

  final size = file.lengthSync() ?? await file.length() ?? 0;
  if (!context.mounted) return false;
  if (size > _maxBytes) {
    _snack(context, 'That file is over 10 MB. Please choose a smaller photo or PDF.');
    return false;
  }

  final isPdf = (file.extension ?? '').toLowerCase() == 'pdf';
  final preview = isPdf ? null : await file.readAsBytes();

  unawaited(
    ref.read(medicineCartProvider.notifier).attachPrescription(
          PrescriptionFile(name: file.name, sizeBytes: size, isPdf: isPdf, previewBytes: preview),
        ),
  );
  return true;
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const Text(
                'Upload prescription',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              const Text(
                'A licensed pharmacist reads it and adds your medicines to the cart. '
                'Make sure the doctor\'s name, date and medicines are clearly visible.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 16),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Photo of prescription',
                subtitle: 'Choose from your gallery',
                onTap: () => Navigator.pop(context, FileType.image),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'PDF or file',
                subtitle: 'PDF, JPG or PNG · up to 10 MB',
                onTap: () => Navigator.pop(context, FileType.custom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
