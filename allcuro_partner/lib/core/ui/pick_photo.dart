import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

/// A photo the partner picked, ready to upload.
class PickedPhoto {
  final Uint8List bytes;
  final String fileName;

  const PickedPhoto(this.bytes, this.fileName);
}

/// Asks camera or gallery (the web build goes straight to the file picker),
/// then returns the photo — resized to keep uploads small — or null if the
/// partner cancelled.
Future<PickedPhoto?> pickPhoto(BuildContext context, {required String title}) async {
  ImageSource? source = ImageSource.gallery;
  if (!kIsWeb) {
    source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
  if (source == null) return null;
  try {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 85);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
    return PickedPhoto(bytes, name);
  } catch (e) {
    debugPrint('[pickPhoto] $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the camera or gallery. Check the app permissions and try again.'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
    return null;
  }
}
