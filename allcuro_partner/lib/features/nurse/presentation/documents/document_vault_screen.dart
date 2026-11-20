import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/pick_photo.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/upload_tile.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/onboarding_view_model.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DocumentVaultScreen({super.key, required this.onBack});

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  String? _uploadingId;

  /// Photo of the certificate → private `kyc-documents` bucket → recorded on
  /// the partner row for ALLCURO's review.
  Future<void> _upload(ComplianceDocItem doc) async {
    final file = await pickPhoto(context, title: 'Upload ${doc.title.split('(').first.trim()}');
    if (file == null || !mounted) return;
    setState(() => _uploadingId = doc.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(partnerOnboardingProvider.notifier).uploadPractitionerDoc(doc, file);
      messenger.showSnackBar(
        SnackBar(content: Text('Uploaded ${doc.title}'), backgroundColor: AppColors.success),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.destructive));
    } finally {
      if (mounted) setState(() => _uploadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              subtitle: 'Upload your certificates for ALLCURO review',
              onBack: widget.onBack,
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
                                ? 'Aadhaar & registration submitted at sign-up'
                                : '${identity.registrationLabel} ${identity.registrationNumber} checked with the council '
                                    'register · Aadhaar ${identity.maskedAadhaar} card photo submitted',
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
                        fileName: doc.isUploaded ? doc.fileName : null,
                        uploading: _uploadingId == doc.id,
                        onTap: _uploadingId == null ? () => _upload(doc) : null,
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
