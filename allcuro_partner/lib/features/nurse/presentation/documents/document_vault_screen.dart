import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/upload_tile.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/onboarding_view_model.dart';

class DocumentVaultScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const DocumentVaultScreen({super.key, required this.onBack});

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
              'Upload PDF, JPG or PNG (Max 15MB). Verified by State Nursing Council automated registry.',
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
              subtitle: const Text('Select certificate from storage', style: TextStyle(fontSize: 12)),
              onTap: () {
                ref.read(partnerOnboardingProvider.notifier).markDocUploaded(
                      docId: doc.id,
                      isCentre: false,
                      fileName: '${doc.docType}_verified_${DateTime.now().year}.pdf',
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
    final docs = state.nurseDocs;
    final identity = ref.watch(authViewModelProvider).valueOrNull?.practitionerIdentity;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Document Vault & KYC',
              subtitle: 'Keep registrations current — verified profiles receive 3x more bookings',
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
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            identity == null
                                ? 'Aadhaar & registration verified at sign-up — no uploads needed'
                                : 'Aadhaar ${identity.maskedAadhaar} & ${identity.registrationLabel} '
                                    '${identity.registrationNumber} verified at sign-up — no uploads needed',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final doc in docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UploadTile(
                        label: doc.title,
                        fileName: doc.fileName,
                        onTap: () => _simulateUpload(context, ref, doc),
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
