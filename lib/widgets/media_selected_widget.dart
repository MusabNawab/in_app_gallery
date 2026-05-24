import 'package:flutter/material.dart';

class MediaSelectedWidget extends StatelessWidget {
  const MediaSelectedWidget({super.key, required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.secondary;
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? selectedColor : Colors.grey,
      ),
      child: isSelected
          ? const Center(
              child: Icon(Icons.check, color: Colors.white, size: 15),
            )
          : null,
    );
  }
}
