import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

part 'in_app_gallery_state.dart';

/// Cubit responsible for managing the state of the InAppGalleryScreen.
/// Fetches images and videos, and keeps track of selected media.
class InAppGalleryCubit extends Cubit<InAppGalleryState> {
  InAppGalleryCubit() : super(InAppGalleryState.initial());

  void reset() {
    emit(InAppGalleryState.initial());
  }

  /// Fetches a paginated list of images from the device gallery.
  Future<void> getImages({bool loadMore = false}) async {
    if (loadMore && !state.hasMoreImages) return;

    if (!loadMore) {
      emit(state.copyWith(isLoading: true));
    }

    final page = loadMore ? state.imagePage + 1 : 0;

    final assetCount = await PhotoManager.getAssetCount(
      type: RequestType.image,
    );
    final entities = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: 80,
      type: RequestType.image,
    );

    final newImages = loadMore
        ? [...state.galleryImages, ...entities]
        : entities;
    final hasMore = newImages.length < assetCount;

    emit(
      state.copyWith(
        imageAssetCount: assetCount,
        galleryImages: newImages,
        imagePage: page,
        hasMoreImages: hasMore,
        isLoading: false,
      ),
    );
  }

  /// Fetches a paginated list of videos from the device gallery.
  Future<void> getVideos({bool loadMore = false}) async {
    if (loadMore && !state.hasMoreVideos) return;

    if (!loadMore && state.galleryVideos.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }

    final page = loadMore ? state.videoPage + 1 : 0;

    final assetCount = await PhotoManager.getAssetCount(
      type: RequestType.video,
    );
    final entities = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: 80,
      type: RequestType.video,
    );

    final newVideos = loadMore
        ? [...state.galleryVideos, ...entities]
        : entities;
    final hasMore = newVideos.length < assetCount;

    emit(
      state.copyWith(
        videoAssetCount: assetCount,
        galleryVideos: newVideos,
        videoPage: page,
        hasMoreVideos: hasMore,
        isLoading: false,
      ),
    );
  }

  /// Toggles the selection state of a media file.
  /// Respects the [maxSelection] limit if provided.
  void onMediaSelect(AssetEntity file, {int? maxSelection}) {
    final updatedSelection = List<AssetEntity>.from(state.selectedMedia);

    if (updatedSelection.contains(file)) {
      updatedSelection.remove(file);
    } else {
      if (maxSelection != null && updatedSelection.length >= maxSelection) {
        // Can't select more than maxSelection
        return;
      }
      updatedSelection.add(file);
    }

    emit(state.copyWith(selectedMedia: updatedSelection));
  }

  /// Saves a newly taken photo from the camera to the gallery and selects it.
  void onCameraSelect(BuildContext context, File file) async {
    try {
      final newEntity = await PhotoManager.editor.saveImageWithPath(
        file.path,
        title: file.path.split('/').last,
      );

      final updatedGallery = List<AssetEntity>.from(state.galleryImages);
      final updatedSelection = List<AssetEntity>.from(state.selectedMedia);

      updatedGallery.insert(0, newEntity);
      updatedSelection.add(newEntity);

      emit(
        state.copyWith(
          galleryImages: updatedGallery,
          selectedMedia: updatedSelection,
        ),
      );
    } catch (e) {
      // Handle error gracefully
    }
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
