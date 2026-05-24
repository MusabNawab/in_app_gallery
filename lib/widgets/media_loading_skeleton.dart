import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MediaLoadingSkeleton extends StatelessWidget {
  const MediaLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        itemCount: 20,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 5,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemBuilder: (context, index) => Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
        ),
      ),
    );
  }
}
