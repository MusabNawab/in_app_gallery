import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitDialogPlayer extends StatefulWidget {
  final String url;

  const MediaKitDialogPlayer({super.key, required this.url});

  @override
  State<MediaKitDialogPlayer> createState() => _MediaKitDialogPlayerState();
}

class _MediaKitDialogPlayerState extends State<MediaKitDialogPlayer> {
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.url));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            MaterialVideoControlsTheme(
              normal: const MaterialVideoControlsThemeData(
                bottomButtonBarMargin: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
              ),
              fullscreen: const MaterialVideoControlsThemeData(
                bottomButtonBarMargin: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
              ),
              child: Video(controller: controller),
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
          ],
        ),
      ),
    );
  }
}

void showVideoPlayerDialog(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (context) => MediaKitDialogPlayer(url: url),
  );
}
