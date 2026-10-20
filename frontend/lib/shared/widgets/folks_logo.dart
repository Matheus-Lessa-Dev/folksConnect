import 'package:flutter/material.dart';

/// Original Figma artwork, extracted without redrawing or changing proportions.
class FolksLogo extends StatelessWidget {
  const FolksLogo({super.key});

  static const asset = 'assets/branding/folks-white.png';
  static const width = 180.0;
  static const height = 218.0;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Folks RH',
      filterQuality: FilterQuality.high,
    );
  }
}
