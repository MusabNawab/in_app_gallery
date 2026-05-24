import 'package:flutter/material.dart';

import 'media_selected_widget.dart';

class MediaContainer extends StatelessWidget {
  const MediaContainer({
    super.key,
    required this.image,
    required this.isSelected,
    this.showCheckbox = true,
    this.onLongPress,
    required this.pickedImage,
    this.selectionCheckboxWidget,
  });

  final Widget image;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback pickedImage;
  final VoidCallback? onLongPress;
  final Widget? selectionCheckboxWidget;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: pickedImage,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (showCheckbox)
            selectionCheckboxWidget ??
                Positioned(
                  bottom: 15,
                  right: 18,
                  child: MediaSelectedWidget(isSelected: isSelected),
                ),
        ],
      ),
    );
  }
}
