import 'package:flutter/material.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';

import 'editor_aspect_ratio.dart';

/// Modal dialogs and bottom sheet pickers for [PhotoEditorScreen].
class EditorDialogs {
  EditorDialogs._();

  /// Displays an alert dialog for the user to input a custom width and height ratio.
  static Future<void> showCustomRatioDialog({
    required BuildContext context,
    required ValueChanged<EditorAspectRatio> onRatioApplied,
  }) async {
    final widthController = TextEditingController(text: '5');
    final heightController = TextEditingController(text: '4');

    return showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252525),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Custom Aspect Ratio',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter desired ratio (Width : Height)',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Width',
                        labelStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        labelStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(widthController.text.trim()) ?? 1.0;
                final h = double.tryParse(heightController.text.trim()) ?? 1.0;
                if (w > 0 && h > 0) {
                  final customRatio = EditorAspectRatio(
                    label:
                        '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1)}:${h.toStringAsFixed(h.truncateToDouble() == h ? 0 : 1)}',
                    icon: Icons.aspect_ratio_rounded,
                    type: CropAspectRatio.custom,
                    ratio: w / h,
                    widthRatio: w,
                    heightRatio: h,
                  );
                  Navigator.pop(dialogCtx);
                  onRatioApplied(customRatio);
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  /// Displays a modal bottom sheet to select the output resolution preset.
  static Future<void> showResolutionPicker({
    required BuildContext context,
    required int currentDimension,
    required ValueChanged<int> onDimensionSelected,
  }) async {
    const options = [
      {'label': 'Original Resolution', 'dim': 0},
      {'label': 'Full HD (1920px)', 'dim': 1920},
      {'label': 'HD (1080px)', 'dim': 1080},
      {'label': 'Standard (720px)', 'dim': 720},
      {'label': 'Thumbnail (512px)', 'dim': 512},
    ];

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Output Resolution',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...options.map((opt) {
                final dim = opt['dim'] as int;
                final isSelected = currentDimension == dim;
                return ListTile(
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blueAccent)
                      : null,
                  onTap: () {
                    onDimensionSelected(dim);
                    Navigator.pop(sheetCtx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Displays a modal bottom sheet to select the Bicubic interpolation filter.
  static Future<void> showFilterPicker({
    required BuildContext context,
    required BicubicFilter currentFilter,
    required ValueChanged<BicubicFilter> onFilterSelected,
  }) async {
    const filters = [
      {
        'filter': BicubicFilter.catmullRom,
        'title': 'Catmull-Rom (Default)',
        'desc': 'Sharp bicubic, same as OpenCV/PIL standard.',
      },
      {
        'filter': BicubicFilter.mitchell,
        'title': 'Mitchell-Netravali',
        'desc': 'Balanced between sharpness and smooth ringing.',
      },
      {
        'filter': BicubicFilter.cubicBSpline,
        'title': 'Cubic B-Spline',
        'desc': 'Smoother interpolation, softer transitions.',
      },
    ];

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bicubic Interpolation Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...filters.map((f) {
                final filter = f['filter'] as BicubicFilter;
                final isSelected = currentFilter == filter;
                return ListTile(
                  title: Text(
                    f['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    f['desc'] as String,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blueAccent)
                      : null,
                  onTap: () {
                    onFilterSelected(filter);
                    Navigator.pop(sheetCtx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
