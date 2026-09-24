import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../logic/cubit/in_app_gallery_cubit.dart';
import '../../../widgets/media_thumbnail.dart';
import '../../../widgets/pick_camera_widget.dart';
import '../../photo_editor/photo_editor_screen.dart';

class InAppGalleryGrid extends StatelessWidget {
  const InAppGalleryGrid({
    super.key,
    required this.controller,
    required this.mediaList,
    required this.selectedMedia,
    required this.isImagesTab,
    this.imageQuality,
    required this.maxSelection,
    this.selectionCheckboxWidget,
    this.cameraWidget,
    this.editedFiles = const {},
    this.enablePhotoEdit = true,
    this.editButtonBuilder,
    this.customPhotoEditor,
  });
  final ScrollController controller;
  final List<AssetEntity> mediaList;
  final List<AssetEntity> selectedMedia;
  final bool isImagesTab;
  final int? imageQuality;
  final int? maxSelection;
  final Widget? selectionCheckboxWidget;
  final Widget? cameraWidget;
  final Map<String, File> editedFiles;
  final bool enablePhotoEdit;
  final Widget Function(
    BuildContext context,
    AssetEntity asset,
    VoidCallback onEdit,
  )?
  editButtonBuilder;
  final Future<File?> Function(
    BuildContext context,
    File originalFile,
    AssetEntity asset,
  )?
  customPhotoEditor;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InAppGalleryCubit>();
    final itemCount = mediaList.length + 1;

    return RefreshIndicator(
      onRefresh: () async {
        cubit.reset();
        await Future.wait([cubit.getImages(), cubit.getVideos()]);
      },
      child: GridView.builder(
        controller: controller,
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 5,
          crossAxisSpacing: 0.33,
          mainAxisSpacing: 1.25,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return PickCameraWidget(
              imageQuality: imageQuality,
              cameraWidget: cameraWidget,
              isVideo: !isImagesTab,
              pickedImage: (image) {
                if (image != null) {
                  cubit.onCameraSelect(
                    context,
                    image,
                    isVideo: !isImagesTab,
                    maxSelection: maxSelection,
                  );
                }
              },
            );
          }

          final mediaIndex = index - 1;
          final media = mediaList[mediaIndex];
          final isSelected = selectedMedia.contains(media);
          final editedFile = editedFiles[media.id];

          return MediaThumbnail(
            asset: media,
            isSelected: isSelected,
            selectionCheckboxWidget: selectionCheckboxWidget,
            editedFile: editedFile,
            enablePhotoEdit: enablePhotoEdit,
            editButtonBuilder: editButtonBuilder,
            onEdit: () async {
              final file = editedFile ?? await media.file;
              if (file == null) return;
              if (!context.mounted) return;

              final File? result;
              if (customPhotoEditor != null) {
                result = await customPhotoEditor!(context, file, media);
              } else {
                result = await PhotoEditorScreen.open(
                  context: context,
                  file: file,
                  asset: media,
                  initialQuality: imageQuality,
                  theme: Theme.of(context),
                );
              }

              if (result != null) {
                cubit.setEditedFile(media, result, maxSelection: maxSelection);
              }
            },
            onSelected: () {
              cubit.onMediaSelect(media, maxSelection: maxSelection);
            },
          );
        },
      ),
    );
  }
}
