import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import 'core_widgets.dart';

/// A photo queued for `POST /evidence`. Its Idempotency-Key is created when
/// the photo is added (the "queued item") and reused for upload retries;
/// [evidenceId] is remembered so a retried submit never re-uploads.
class PickedPhoto {
  PickedPhoto({required this.bytes, required this.filename, required this.contentType})
      : uploadKey = newIdempotencyKey(),
        capturedAt = DateTime.now();

  final Uint8List bytes;
  final String filename;
  final String contentType;
  final String uploadKey;
  final DateTime capturedAt;
  String? evidenceId;
}

String contentTypeFor(String filename) {
  final n = filename.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

/// Camera / gallery chooser. Images are downscaled so uploads stay well
/// under the 5 MiB evidence limit.
Future<PickedPhoto?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: DropzyColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera_rounded, color: DropzyColors.primary),
          title: const Text('Take a photo'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_rounded, color: DropzyColors.primary),
          title: const Text('Choose from gallery'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
  if (source == null) return null;
  try {
    final img = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 75);
    if (img == null) return null;
    final bytes = await img.readAsBytes();
    return PickedPhoto(bytes: bytes, filename: img.name, contentType: img.mimeType ?? contentTypeFor(img.name));
  } catch (_) {
    if (context.mounted) showToast(context, 'Could not open the camera or gallery.');
    return null;
  }
}

/// Thumbnail row with remove buttons and an "Add photo" tile.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos, required this.max, required this.onAdd, required this.onRemove});
  final List<PickedPhoto> photos;
  final int max;
  final VoidCallback? onAdd;
  final void Function(int index)? onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (var i = 0; i < photos.length; i++)
        Stack(clipBehavior: Clip.none, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(photos[i].bytes, width: 76, height: 76, fit: BoxFit.cover),
          ),
          if (onRemove != null)
            Positioned(
              right: -6,
              top: -6,
              child: InkWell(
                onTap: () => onRemove!(i),
                child: Container(
                  decoration: const BoxDecoration(color: DropzyColors.danger, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ]),
      if (photos.length < max)
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: DropzyColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DropzyColors.line),
            ),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_a_photo_rounded, color: DropzyColors.primary),
              SizedBox(height: 4),
              Text('Add', style: TextStyle(fontSize: 12, color: DropzyColors.inkSoft)),
            ]),
          ),
        ),
    ]);
  }
}
