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
        ),
      ),
    );

    if (result != null && result is List) {
      setState(() {
        _selectedMedia = List<File>.from(result);
      });
    }
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
            ElevatedButton(
              onPressed: _openGallery,
              child: const Text('Open Gallery'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _selectedMedia.isEmpty
                  ? const Center(child: Text('No media selected'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          _selectedMedia[index],
                          fit: BoxFit.cover,
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
