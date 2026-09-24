import 'dart:io';

import 'package:flutter/material.dart';

class InAppGalleryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const InAppGalleryAppBar({
    super.key,
    required this.title,
    required this.fileCount,
    required this.onDone,
    this.onEdit,
  });

  final String title;
  final int fileCount;
  final VoidCallback onDone;
  final VoidCallback? onEdit;
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          Navigator.pop(context, <File>[]);
        },
      ),
      actions: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Edit Selected Photo',
            onPressed: onEdit,
          ),
        if (fileCount > 0)
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Done',
            onPressed: onDone,
          ),
      ],
    );
  }
}
