import 'package:flutter/material.dart';

/// Shared, bundled brand artwork for the splash and welcome screens.
class RentMarkBrandArtwork extends StatelessWidget {
  final double height;

  const RentMarkBrandArtwork({super.key, required this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Center(
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/branding/rentmark_welcome.png',
            fit: BoxFit.contain,
            semanticLabel: 'RentMark. Rent, connect, share.',
          ),
        ),
      ),
    ),
  );
}
