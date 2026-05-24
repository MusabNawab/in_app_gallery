import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/constants.dart';
import '../../../logic/cubit/in_app_gallery_cubit.dart';

class DefaultCompressionDialog extends StatelessWidget {
  const DefaultCompressionDialog({super.key, required this.progressStream});

  final Stream<double> progressStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Wrapping in a BackdropFilter adds a modern, glass-like blur to the background
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          decoration: BoxDecoration(
            color: theme
                .cardColor, // Adapts to Light/Dark mode instead of hardcoded black
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<double>(
                stream: progressStream,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? 0.0;
                  final isWaiting =
                      snapshot.connectionState == ConnectionState.waiting;

                  return SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: (isWaiting || progress <= 0)
                                ? null
                                : progress,
                            strokeWidth: 6,
                            // Adds rounded edges to the progress line
                            strokeCap: StrokeCap.round,
                            // Adds a subtle background track
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            color: colorScheme.primary,
                          ),
                        ),
                        if (!isWaiting && progress > 0)
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                Constants.processingMedia,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Added a subtle subtitle for a more complete UX
              BlocBuilder<InAppGalleryCubit, InAppGalleryState>(
                builder: (context, state) {
                  if (state.processingTotal <= 1) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    'Optimizing file ${state.processingCurrent}/${state.processingTotal}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
