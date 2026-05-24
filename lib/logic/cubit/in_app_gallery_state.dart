part of 'in_app_gallery_cubit.dart';

/// Represents the state of the In-App Gallery.
class InAppGalleryState {
  /// Total number of images in the device gallery.
  final int imageAssetCount;

  /// Total number of videos in the device gallery.
  final int videoAssetCount;

  /// Paginated list of images fetched from the gallery.
  final List<AssetEntity> galleryImages;

  /// Paginated list of videos fetched from the gallery.
  final List<AssetEntity> galleryVideos;

  /// List of currently selected media items.
  final List<AssetEntity> selectedMedia;

  /// Whether the gallery is currently fetching the initial load of items.
  final bool isLoading;

  /// Current pagination page for images.
  final int imagePage;

  /// Current pagination page for videos.
  final int videoPage;

  /// Whether there are more images to fetch.
  final bool hasMoreImages;

  /// Whether there are more videos to fetch.
  final bool hasMoreVideos;

  /// Whether a heavy processing task (e.g., compression) is ongoing.
  final bool isProcessing;

  /// Current index of the file being processed.
  final int processingCurrent;

  /// Total number of files being processed.
  final int processingTotal;

  InAppGalleryState({
    required this.imageAssetCount,
    required this.videoAssetCount,
    required this.galleryImages,
    required this.galleryVideos,
    required this.selectedMedia,
    required this.isLoading,
    required this.imagePage,
    required this.videoPage,
    required this.hasMoreImages,
    required this.hasMoreVideos,
    required this.isProcessing,
    required this.processingCurrent,
    required this.processingTotal,
  });

  /// Factory constructor for the initial empty state.
  factory InAppGalleryState.initial() {
    return InAppGalleryState(
      imageAssetCount: 0,
      videoAssetCount: 0,
      galleryImages: [],
      galleryVideos: [],
      selectedMedia: [],
      isLoading: true,
      imagePage: 0,
      videoPage: 0,
      hasMoreImages: true,
      hasMoreVideos: true,
      isProcessing: false,
      processingCurrent: 0,
      processingTotal: 0,
    );
  }

  InAppGalleryState copyWith({
    int? imageAssetCount,
    int? videoAssetCount,
    List<AssetEntity>? galleryImages,
    List<AssetEntity>? galleryVideos,
    List<AssetEntity>? selectedMedia,
    bool? isLoading,
    int? imagePage,
    int? videoPage,
    bool? hasMoreImages,
    bool? hasMoreVideos,
    bool? isProcessing,
    int? processingCurrent,
    int? processingTotal,
  }) {
    return InAppGalleryState(
      imageAssetCount: imageAssetCount ?? this.imageAssetCount,
      videoAssetCount: videoAssetCount ?? this.videoAssetCount,
      galleryImages: galleryImages ?? this.galleryImages,
      galleryVideos: galleryVideos ?? this.galleryVideos,
      selectedMedia: selectedMedia ?? this.selectedMedia,
      isLoading: isLoading ?? this.isLoading,
      imagePage: imagePage ?? this.imagePage,
      videoPage: videoPage ?? this.videoPage,
      hasMoreImages: hasMoreImages ?? this.hasMoreImages,
      hasMoreVideos: hasMoreVideos ?? this.hasMoreVideos,
      isProcessing: isProcessing ?? this.isProcessing,
      processingCurrent: processingCurrent ?? this.processingCurrent,
      processingTotal: processingTotal ?? this.processingTotal,
    );
  }
}
