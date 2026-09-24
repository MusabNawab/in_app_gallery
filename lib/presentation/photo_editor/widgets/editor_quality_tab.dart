import 'package:flutter/material.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

/// Quality & resize tab widget with JPEG quality slider and modal triggers for resolution and filter.
class EditorQualityTab extends StatelessWidget {
  final Color primaryColor;
  final int quality;
  final ValueChanged<int> onQualityChanged;
  final int targetMaxDimension;
  final BicubicFilter filter;
  final VoidCallback onResolutionPickerPressed;
  final VoidCallback onFilterPickerPressed;

  const EditorQualityTab({
    super.key,
    required this.primaryColor,
    required this.quality,
    required this.onQualityChanged,
    required this.targetMaxDimension,
    required this.filter,
    required this.onResolutionPickerPressed,
    required this.onFilterPickerPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quality Slider
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  'JPEG Quality',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: quality.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 18,
                    activeColor: primaryColor,
                    inactiveColor: Colors.white24,
                    onChanged: (val) => onQualityChanged(val.toInt()),
                  ),
                ),
                Text(
                  '$quality%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Presets: Resolution and Filter buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Resolution preset
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.photo_size_select_actual_rounded,
                    size: 15,
                  ),
                  label: Text(
                    targetMaxDimension == 0
                        ? 'Full Res'
                        : '${targetMaxDimension}px',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: onResolutionPickerPressed,
                ),

                // Filter selector
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_vintage_rounded, size: 15),
                  label: Text(
                    'Filter: ${filter.name}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: onFilterPickerPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
