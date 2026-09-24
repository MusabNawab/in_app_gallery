import 'package:flutter/material.dart';

import 'editor_aspect_ratio.dart';

/// Crop tab widget displaying aspect ratio options, custom ratio button, and helper text.
class EditorCropTab extends StatelessWidget {
  final List<EditorAspectRatio> aspectRatios;
  final EditorAspectRatio? customUserRatio;
  final EditorAspectRatio selectedAspectRatio;
  final ValueChanged<EditorAspectRatio> onAspectRatioSelected;
  final VoidCallback onCustomRatioPressed;
  final Color primaryColor;

  const EditorCropTab({
    super.key,
    required this.aspectRatios,
    this.customUserRatio,
    required this.selectedAspectRatio,
    required this.onAspectRatioSelected,
    required this.onCustomRatioPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final allRatios = [
      ...aspectRatios,
      ?customUserRatio,
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Aspect ratio buttons list
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: allRatios.length + 1, // +1 for "Custom..." button
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == allRatios.length) {
                  // "Custom Ratio..." button
                  return ActionChip(
                    avatar: const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    label: const Text('Custom...'),
                    backgroundColor: const Color(0xFF2A2A2A),
                    labelStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    onPressed: onCustomRatioPressed,
                  );
                }

                final ratio = allRatios[index];
                final isSelected = selectedAspectRatio == ratio;
                return ChoiceChip(
                  showCheckmark: false,
                  avatar: Icon(
                    ratio.icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  label: Text(ratio.label),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    onAspectRatioSelected(ratio);
                  },
                );
              },
            ),
          ),

          // Helper instruction text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                Icon(
                  selectedAspectRatio.isFree
                      ? Icons.open_with_rounded
                      : Icons.aspect_ratio_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedAspectRatio.isFree
                        ? 'Free Crop: Drag corners & edges freely to crop any area'
                        : 'Ratio locked to ${selectedAspectRatio.label}. Drag to frame',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
