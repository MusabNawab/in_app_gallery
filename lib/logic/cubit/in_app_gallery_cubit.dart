import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

part 'in_app_gallery_state.dart';

/// Cubit responsible for managing the state of the InAppGalleryScreen.
/// Fetches images and videos, and keeps track of selected media.
class InAppGalleryCubit extends Cubit<InAppGalleryState> {
  InAppGalleryCubit() : super(InAppGalleryState.initial());

  bool _isLoadingMoreImages = false;
  bool _isLoadingMoreVideos = false;

  void reset() {
    _isLoadingMoreImages = false;
    _isLoadingMoreVideos = false;
    emit(InAppGalleryState.initial());
  }

  /// Fetches a paginated list of images from the device gallery.
  Future<void> getImages({bool loadMore = false}) async {
    if (loadMore) {
      if (!state.hasMoreImages || _isLoadingMoreImages) return;
      _isLoadingMoreImages = true;
    } else {
      emit(state.copyWith(isLoading: true));
    }

    try {
      final page = loadMore ? state.imagePage + 1 : 0;
      const pageSize = 80;

      final assetCount = await PhotoManager.getAssetCount(
        type: RequestType.image,
      );
      final entities = await PhotoManager.getAssetListPaged(
        page: page,
        pageCount: pageSize,
        type: RequestType.image,
      );

      final existingImages = loadMore ? state.galleryImages : <AssetEntity>[];
      final existingIds = existingImages.map((e) => e.id).toSet();

      final uniqueNewEntities = entities
          .where((e) => !existingIds.contains(e.id))
          .toList();
      final updatedImages = [...existingImages, ...uniqueNewEntities];

      final hasMore =
          entities.isNotEmpty &&
          (entities.length == pageSize) &&
          (updatedImages.length < assetCount);

      emit(
        state.copyWith(
          imageAssetCount: assetCount,
          galleryImages: updatedImages,
          imagePage: page,
          hasMoreImages: hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    } finally {
      if (loadMore) {
        _isLoadingMoreImages = false;
      }
    }
  }

  /// Fetches a paginated list of videos from the device gallery.
  Future<void> getVideos({bool loadMore = false}) async {
    if (loadMore) {
      if (!state.hasMoreVideos || _isLoadingMoreVideos) return;
      _isLoadingMoreVideos = true;
    } else {
      if (state.galleryVideos.isEmpty) {
        emit(state.copyWith(isLoading: true));
      }
    }

    try {
      final page = loadMore ? state.videoPage + 1 : 0;
      const pageSize = 80;

      final assetCount = await PhotoManager.getAssetCount(
        type: RequestType.video,
      );
      final entities = await PhotoManager.getAssetListPaged(
        page: page,
        pageCount: pageSize,
        type: RequestType.video,
      );

      final existingVideos = loadMore ? state.galleryVideos : <AssetEntity>[];
      final existingIds = existingVideos.map((e) => e.id).toSet();

      final uniqueNewEntities = entities
          .where((e) => !existingIds.contains(e.id))
          .toList();
      final updatedVideos = [...existingVideos, ...uniqueNewEntities];

      final hasMore =
          entities.isNotEmpty &&
          (entities.length == pageSize) &&
          (updatedVideos.length < assetCount);

      emit(
        state.copyWith(
          videoAssetCount: assetCount,
          galleryVideos: updatedVideos,
          videoPage: page,
          hasMoreVideos: hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    } finally {
      if (loadMore) {
        _isLoadingMoreVideos = false;
      }
    }
  }

  /// Toggles the selection state of a media file.
  /// Respects the [maxSelection] limit if provided.
  void onMediaSelect(AssetEntity file, {int? maxSelection}) {
    final updatedSelection = List<AssetEntity>.from(state.selectedMedia);

    if (updatedSelection.contains(file)) {
      updatedSelection.remove(file);
    } else {
      if (maxSelection == 1) {
        updatedSelection.clear();
        updatedSelection.add(file);
      } else if (maxSelection != null &&
          updatedSelection.length >= maxSelection) {
        // Can't select more than maxSelection
        return;
      } else {
        updatedSelection.add(file);
      }
    }

    emit(state.copyWith(selectedMedia: updatedSelection));
  }

  /// Saves a newly taken photo or video from the camera to the gallery and selects it.
  void onCameraSelect(
    BuildContext context,
    File file, {
    bool isVideo = false,
    int? maxSelection,
  }) async {
    try {
      final title = file.path.split('/').last;
      final newEntity = isVideo
          ? await PhotoManager.editor.saveVideo(file, title: title)
          : await PhotoManager.editor.saveImageWithPath(
              file.path,
              title: title,
            );

      final updatedGallery = List<AssetEntity>.from(
        isVideo ? state.galleryVideos : state.galleryImages,
      );
      final updatedSelection = List<AssetEntity>.from(state.selectedMedia);

      updatedGallery.insert(0, newEntity);

      if (maxSelection == 1) {
        updatedSelection.clear();
        updatedSelection.add(newEntity);
      } else if (maxSelection != null &&
          updatedSelection.length >= maxSelection) {
        // Limit reached, do not auto-add to selection
      } else {
        updatedSelection.add(newEntity);
      }

      emit(
        isVideo
            ? state.copyWith(
                galleryVideos: updatedGallery,
                selectedMedia: updatedSelection,
              )
            : state.copyWith(
                galleryImages: updatedGallery,
                selectedMedia: updatedSelection,
              ),
      );
    } catch (e) {
      // Handle error gracefully
    }
  }

  /// Sets an edited file override for a specific [AssetEntity].
  /// Automatically ensures the asset is selected.
  void setEditedFile(AssetEntity file, File editedFile, {int? maxSelection}) {
    final updatedEditedFiles = Map<String, File>.from(state.editedFiles);
    updatedEditedFiles[file.id] = editedFile;

    final updatedSelection = List<AssetEntity>.from(state.selectedMedia);
    if (!updatedSelection.contains(file)) {
      if (maxSelection == 1) {
        updatedSelection.clear();
        updatedSelection.add(file);
      } else if (maxSelection != null &&
          updatedSelection.length >= maxSelection) {
        // Can't exceed max selection
      } else {
        updatedSelection.add(file);
      }
    }

    emit(
      state.copyWith(
        editedFiles: updatedEditedFiles,
        selectedMedia: updatedSelection,
      ),
    );
  }

  /// Removes an edited file override for a specific [AssetEntity].
  void removeEditedFile(AssetEntity file) {
    final updatedEditedFiles = Map<String, File>.from(state.editedFiles);
    updatedEditedFiles.remove(file.id);
    emit(state.copyWith(editedFiles: updatedEditedFiles));
  }

  /// Sets the processing state when compressing and finalizing selected media.
  void setProcessing(
    bool isProcessing, {
    int processingCurrent = 0,
    int processingTotal = 0,
  }) {
    emit(
      state.copyWith(
        isProcessing: isProcessing,
        processingCurrent: processingCurrent,
        processingTotal: processingTotal,
      ),
    );
  }
}
