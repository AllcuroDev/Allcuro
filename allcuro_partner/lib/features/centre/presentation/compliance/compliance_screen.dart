import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../../auth/presentation/onboarding_view_model.dart';

class ComplianceScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const ComplianceScreen({super.key, required this.onBack});

  void _simulateUpload(BuildContext context, WidgetRef ref, ComplianceDocItem doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload ${doc.title.split('(').first.trim()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload PDF, JPG or PNG certificate (Max 15MB). Verified by ALLCURO compliance operations.',
              style: TextStyle(fontSize: 12.5, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
              ),
              title: const Text('Choose Document from Device', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Select file from local storage', style: TextStyle(fontSize: 12)),
              onTap: () {
                ref.read(partnerOnboardingProvider.notifier).markDocUploaded(
                      docId: doc.id,
                      isCentre: true,
                      fileName: '${doc.docType}.pdf',
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Uploaded new file for ${doc.title}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerOnboardingProvider);
    final docs = state.centreComplianceDocs;
    final uploadedCount = docs.where((d) => d.isUploaded).length;
    final allUploaded = uploadedCount == docs.length;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Regulatory & KYC Compliance',
              subtitle: 'Mandatory statutory clearances to activate facility beds',
              onBack: onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: allUploaded ? AppColors.successSoft : AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allUploaded ? Icons.verified_outlined : Icons.error_outline_rounded,
                          size: 18,
                          color: allUploaded ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            allUploaded
                                ? 'All $uploadedCount regulatory compliance documents uploaded'
                                : '$uploadedCount of ${docs.length} documents uploaded. Complete remaining for site visit.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: allUploaded ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final doc in docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Surface(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    doc.isUploaded ? '${doc.fileName} · ${doc.expiry}' : 'Not uploaded yet',
                                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                                  ),
                                  const SizedBox(height: 6),
                                  Tappable(
                                    onTap: () => _simulateUpload(context, ref, doc),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text(
                                        doc.isUploaded ? 'Re-upload / Update' : 'Upload Document',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: doc.isUploaded ? AppColors.successSoft : AppColors.warningSoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                doc.isVerified ? 'Verified' : (doc.isUploaded ? 'Uploaded' : 'Pending'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: doc.isUploaded ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
