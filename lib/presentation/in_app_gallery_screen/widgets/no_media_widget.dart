import 'package:flutter/material.dart';

import '../../../../constants/constants.dart';

class NoMediaWidget extends StatelessWidget {
  const NoMediaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            Constants.noMediaFound,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Constants.noMediaFoundSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
