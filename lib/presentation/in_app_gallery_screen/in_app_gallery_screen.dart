import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../logic/cubit/in_app_gallery_cubit.dart';
import '../../utils/in_app_gallery_utils.dart';
import '../../utils/permission_access_utils.dart';
import '../../constants/constants.dart';
import '../../widgets/media_loading_skeleton.dart';
import 'widgets/default_compression_dialog.dart';
import 'widgets/in_app_gallery_appbar.dart';
import 'widgets/in_app_gallery_grid.dart';
import 'widgets/in_app_gallery_tab_bar.dart';
import 'widgets/permissions_denied_widget.dart';

/// A fully customizable and robust in-app gallery screen for picking images and videos.
///
/// Use this screen to allow users to select media from their device gallery.
/// It supports video compression, max selection limits, custom themes, and custom UI components.
class InAppGalleryScreen extends StatefulWidget {
  /// Whether to allow compressing videos before returning them.
  /// If true, videos will be compressed to save space. Default is false.
  final bool allowVideoCompression;

  /// If true, the gallery will only show images. Default is false.
  final bool? onlyImages;

  /// If true, the gallery will only show videos. Default is false.
  final bool? onlyVideos;

  /// Custom app bar builder. Receives the current number of selected files.
  final PreferredSizeWidget Function(int fileCount)? appBar;

  /// Custom widget to display the camera option in the grid.
  final Widget? cameraWidget;

  /// Custom widget to use as the selection checkbox for media items.
  final Widget? selectionCheckboxWidget;

  /// Custom widget to display when gallery or camera permissions are denied.
  final Widget? permissionDeniedWidget;

  /// Custom widget to display when there are no media files found on the device.
  final Widget? noMediaWidget;

  /// Custom compression dialog widget shown while videos/images are being processed.
  /// Receives the build context and a stream of the compression progress (0.0 to 1.0).
  final Widget Function(BuildContext context, Stream<double> progressStream)?
  compressionDialogWidget;

  /// Quality of the compressed image. Range is 0 to 100.
  /// If null, no image compression is applied.
  final int? imageQuality;

  /// Maximum number of items the user can select.
  final int? maxSelection;

  /// Callback triggered when a selected video exceeds the 500 MB size limit
  /// and cannot be compressed. Provides the filename of the oversized video.
  final Function(String filename)? onVideoSizeExceeded;

  /// Primary color used for the default theme (AppBar, Checkboxes, etc.).
  final Color? primaryColor;

  /// Secondary color used for the default theme.
  final Color? secondaryColor;

  /// Size of the tab bar indicator if both images and videos are shown.
  final TabBarIndicatorSize? tabBarIndicatorSize;

  /// Custom theme data to override the default colors and styles.
  final ThemeData? theme;

  /// Title displayed on the default App Bar.
  final String title;

  const InAppGalleryScreen({
    super.key,
    this.allowVideoCompression = false,
    this.onlyImages = false,
    this.onlyVideos = false,
    this.appBar,
    this.cameraWidget,
    this.selectionCheckboxWidget,
    this.permissionDeniedWidget,
    this.noMediaWidget,
    this.compressionDialogWidget,
    this.imageQuality,
    this.maxSelection,
    this.onVideoSizeExceeded,
    this.primaryColor,
    this.secondaryColor,
    this.tabBarIndicatorSize = TabBarIndicatorSize.tab,
    this.theme,
    this.title = 'Gallery',
  });

  @override
  State<InAppGalleryScreen> createState() => _InAppGalleryScreenState();
}

class _InAppGalleryScreenState extends State<InAppGalleryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late InAppGalleryCubit _cubit;
  late TabController _tabController;
  final ScrollController _imagesScrollController = ScrollController();
  final ScrollController _videosScrollController = ScrollController();

  bool _isCheckingPermission = true;
  bool _hasPermission = false;

  bool get _showImages => widget.onlyVideos == true ? false : true;
  bool get _showVideos => widget.onlyImages == true ? false : true;
  int get _tabCount => (_showImages && _showVideos) ? 2 : 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PhotoManager.setIgnorePermissionCheck(true);
    _cubit = InAppGalleryCubit();
    _checkPermissions();

    _tabController = TabController(length: _tabCount, vsync: this);

    _imagesScrollController.addListener(() {
      onScroll(_imagesScrollController, () => _cubit.getImages(loadMore: true));
    });

    _videosScrollController.addListener(() {
      onScroll(_videosScrollController, () => _cubit.getVideos(loadMore: true));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _imagesScrollController.dispose();
    _videosScrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final hasGallery = await PermissionAccessUtils.checkGalleryPermissions();

    if (mounted) {
      setState(() {
        _hasPermission = hasGallery;
        _isCheckingPermission = false;
      });

      if (_hasPermission) {
        if (_showImages && _cubit.state.galleryImages.isEmpty) {
          _cubit.getImages();
        }
        if (_showVideos && _cubit.state.galleryVideos.isEmpty) {
          _cubit.getVideos();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Theme(
        data:
            widget.theme ??
            ThemeData(
              primaryColor: widget.primaryColor ?? Constants.primaryColor,
              appBarTheme: AppBarTheme(
                backgroundColor: widget.primaryColor ?? Constants.primaryColor,
                foregroundColor: Colors.white,
              ),
              colorScheme: ColorScheme.light(
                primary: widget.primaryColor ?? Constants.primaryColor,
                secondary: widget.secondaryColor ?? Constants.secondaryColor,
              ),
            ),
        child: BlocConsumer<InAppGalleryCubit, InAppGalleryState>(
          listenWhen: (previous, current) =>
              previous.isProcessing != current.isProcessing,
          listener: (context, state) {
            if (state.isProcessing) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return BlocProvider.value(
                    value: context.read<InAppGalleryCubit>(),
                    child: PopScope(
                      canPop: false,
                      child: widget.compressionDialogWidget != null
                          ? widget.compressionDialogWidget!(
                              dialogContext,
                              InAppGalleryUtils.progressStream,
                            )
                          : DefaultCompressionDialog(
                              progressStream: InAppGalleryUtils.progressStream,
                            ),
                    ),
                  );
                },
              );
            } else {
              // Ensure we pop the dialog using the root navigator so we don't pop the screen!
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          builder: (context, state) {
            final fileCount = state.selectedMedia.length;
            return Scaffold(
              appBar: widget.appBar != null
                  ? widget.appBar!(fileCount)
                  : InAppGalleryAppBar(
                      title: widget.title,
                      fileCount: fileCount,
                      onDone: () async {
                        context.read<InAppGalleryCubit>().setProcessing(true);
                        try {
                          final files =
                              await InAppGalleryUtils.onSelectionCompleted(
                                imageQuality: widget.imageQuality,
                                selectedMedia: state.selectedMedia,
                                allowVideoCompression:
                                    widget.allowVideoCompression,
                                onVideoSizeExceeded: (filename) {
                                  if (widget.onVideoSizeExceeded != null) {
                                    widget.onVideoSizeExceeded!(filename);
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: Constants.videoSizeExceeded(
                                        filename,
                                      ),
                                      backgroundColor: Colors.yellow,
                                      textColor: Colors
                                          .black, // Added for better contrast
                                    );
                                  }
                                },
                                onProgress: (current, total) {
                                  context
                                      .read<InAppGalleryCubit>()
                                      .setProcessing(
                                        true,
                                        processingCurrent: current,
                                        processingTotal: total,
                                      );
                                },
                              );

                          if (context.mounted) {
                            context.read<InAppGalleryCubit>().setProcessing(
                              false,
                            );
                            Navigator.pop(context, files);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.read<InAppGalleryCubit>().setProcessing(
                              false,
                            );
                          }
                        }
                      },
                    ),
              body: SafeArea(
                child: _isCheckingPermission
                    ? const Center(child: CircularProgressIndicator())
                    : !_hasPermission
                    ? PermissionsDeniedWidget(
                        permissionDeniedWidget: widget.permissionDeniedWidget,
                      )
                    : Column(
                        children: [
                          if (_tabCount > 1)
                            InAppGalleryTabBar(
                              tabController: _tabController,
                              tabBarIndicatorSize: widget.tabBarIndicatorSize,
                            ),
                          Expanded(
                            child:
                                BlocBuilder<
                                  InAppGalleryCubit,
                                  InAppGalleryState
                                >(
                                  builder: (context, state) {
                                    if (state.isLoading) {
                                      return const MediaLoadingSkeleton();
                                    }

                                    final selectedMedia = state.selectedMedia;

                                    if (_tabCount == 1) {
                                      if (_showImages) {
                                        return InAppGalleryGrid(
                                          mediaList: state.galleryImages,
                                          selectedMedia: selectedMedia,
                                          imageQuality: widget.imageQuality,
                                          maxSelection: widget.maxSelection,
                                          controller: _imagesScrollController,
                                          isImagesTab: true,
                                          selectionCheckboxWidget:
                                              widget.selectionCheckboxWidget,
                                          cameraWidget: widget.cameraWidget,
                                          noMediaWidget: widget.noMediaWidget,
                                        );
                                      } else {
                                        return InAppGalleryGrid(
                                          mediaList: state.galleryVideos,
                                          selectedMedia: selectedMedia,
                                          imageQuality: widget.imageQuality,
                                          maxSelection: widget.maxSelection,
                                          controller: _videosScrollController,
                                          isImagesTab: false,
                                          selectionCheckboxWidget:
                                              widget.selectionCheckboxWidget,
                                          noMediaWidget: widget.noMediaWidget,
                                        );
                                      }
                                    }

                                    return TabBarView(
                                      controller: _tabController,
                                      children: [
                                        InAppGalleryGrid(
                                          mediaList: state.galleryImages,
                                          selectedMedia: selectedMedia,
                                          imageQuality: widget.imageQuality,
                                          maxSelection: widget.maxSelection,
                                          controller: _imagesScrollController,
                                          isImagesTab: true,
                                          selectionCheckboxWidget:
                                              widget.selectionCheckboxWidget,
                                          cameraWidget: widget.cameraWidget,
                                          noMediaWidget: widget.noMediaWidget,
                                        ),
                                        InAppGalleryGrid(
                                          mediaList: state.galleryVideos,
                                          selectedMedia: selectedMedia,
                                          imageQuality: widget.imageQuality,
                                          maxSelection: widget.maxSelection,
                                          controller: _videosScrollController,
                                          isImagesTab: false,
                                          selectionCheckboxWidget:
                                              widget.selectionCheckboxWidget,
                                          noMediaWidget: widget.noMediaWidget,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  void onScroll(ScrollController controller, VoidCallback onMaxExtent) {
    if (_imagesScrollController.position.pixels >=
        _imagesScrollController.position.maxScrollExtent - 200) {
      onMaxExtent();
    }
  }
}
