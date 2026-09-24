import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'in_app_gallery_video_player.dart';
import 'media_container_widget.dart';

class MediaThumbnail extends StatefulWidget {
  const MediaThumbnail({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.onSelected,
    this.selectionCheckboxWidget,
    this.editedFile,
    this.enablePhotoEdit = true,
    this.onEdit,
    this.editButtonBuilder,
  });

  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onSelected;
  final Widget? selectionCheckboxWidget;
  final File? editedFile;
  final bool enablePhotoEdit;
  final VoidCallback? onEdit;
  final Widget Function(
    BuildContext context,
    AssetEntity asset,
    VoidCallback onEdit,
  )?
  editButtonBuilder;

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
  }

  @override
  void didUpdateWidget(covariant MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _thumbnailFuture = widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );
    }
  }

  void _handleLongPress() async {
    final file = widget.editedFile ?? await widget.asset.file;
    if (file == null) return;
    if (!mounted) return;

    if (widget.asset.type == AssetType.video) {
      showVideoPlayerDialog(context, file.path);
    } else {
      showImagePreviewDialog(
        context,
        file.path,
        onEdit: widget.enablePhotoEdit ? widget.onEdit : null,
      );
    }
  }

  // --- ADDED: Helper method to format duration into MM:SS ---
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isVideo = widget.asset.type == AssetType.video;
    final isEdited = widget.editedFile != null;
    final showEditButton =
        widget.isSelected &&
        !isVideo &&
        widget.enablePhotoEdit &&
        widget.onEdit != null;

    Widget buildImageContent(Widget imageWidget) {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,

          // Edited Badge
          if (isEdited)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_fix_high, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'Edited',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isVideo) // Duration badge
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  spacing: 5,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    Text(
                      _formatDuration(widget.asset.videoDuration),
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    Widget? buildEditButtonWidget() {
      if (!showEditButton) return null;
      if (widget.editButtonBuilder != null) {
        return widget.editButtonBuilder!(
          context,
          widget.asset,
          widget.onEdit!,
        );
      }
      return Positioned(
        bottom: 10,
        left: 8,
        child: GestureDetector(
          onTap: widget.onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MediaContainer(
      isSelected: widget.isSelected,
      showCheckbox: true,
      pickedImage: widget.onSelected,
      onLongPress: _handleLongPress,
      selectionCheckboxWidget: widget.selectionCheckboxWidget,
      editWidget: buildEditButtonWidget(),

      image: isEdited
          ? buildImageContent(
              Image.file(
                widget.editedFile!,
                fit: BoxFit.cover,
                key: ValueKey(widget.editedFile!.path),
              ),
            )
          : FutureBuilder<Uint8List?>(
              future: _thumbnailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data != null) {
                  return buildImageContent(
                    Image.memory(snapshot.data!, fit: BoxFit.cover),
                  );
                }
                return const Center(child: Icon(Icons.video_file));
              },
            ),
    );
  }
}

void showImagePreviewDialog(
  BuildContext context,
  String path, {
  VoidCallback? onEdit,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            if (onEdit != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    tooltip: 'Edit Photo',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
