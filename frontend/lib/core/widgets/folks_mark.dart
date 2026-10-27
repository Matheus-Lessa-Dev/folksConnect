import 'package:flutter/material.dart';

/// Simbolo da marca original, exibido pelo recorte usado na navegacao do Figma.
/// O PNG original permanece intacto: o recorte e feito apenas no layout.
class FolksMark extends StatelessWidget {
  const FolksMark({super.key, this.size = 33});
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = size / 604;
    return Semantics(
      label: 'Folks',
      image: true,
      child: SizedBox(
        width: size,
        height: size * 600 / 604,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 1973 * scale,
            maxWidth: 1973 * scale,
            minHeight: 747 * scale,
            maxHeight: 747 * scale,
            child: Transform.translate(
              offset: Offset(-120 * scale, -70 * scale),
              child: Image.asset(
                'assets/brand/folks-white.png',
                width: 1973 * scale,
                height: 747 * scale,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
