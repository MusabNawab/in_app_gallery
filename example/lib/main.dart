import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_gallery/in_app_gallery.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In App Gallery Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<File> _selectedMedia = [];

  Future<void> _openGallery() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InAppGalleryScreen(
          title: 'Select Media',
          maxSelection: 10,
          allowVideoCompression: true,
          imageQuality: 70,
        ),
      ),
    );

    if (result != null && result is List) {
      setState(() {
        _selectedMedia = List<File>.from(result);
      });
    }
  }

  bool _isVideoFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm') ||
        ext.endsWith('.3gp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In App Gallery Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Open Gallery'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedMedia.isEmpty
                  ? const Center(child: Text('No media selected'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        final file = _selectedMedia[index];
                        final isVideo = _isVideoFile(file.path);
                        final fileSize = file.lengthSync();
                        final sizeText = InAppGalleryUtils.formatBytes(
                          fileSize,
                        );

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (isVideo)
                                GestureDetector(
                                  onTap: () {
                                    showVideoPlayerDialog(context, file.path);
                                  },
                                  child: Container(
                                    color: Colors.black87,
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Video Preview',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image, size: 40),
                                    );
                                  },
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '${isVideo ? 'Video' : 'Image'} • $sizeText',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
