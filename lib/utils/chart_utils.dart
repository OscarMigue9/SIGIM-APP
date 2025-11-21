import 'package:flutter/material.dart';

class ChartUtils {
  // Calcula cada cuántas etiquetas mostrar para evitar solapamiento
  static int stepForLabels({required int itemCount, double approxLabelWidth = 48, double availableWidth = 320}) {
    if (itemCount <= 0) return 1;
    final maxLabels = (availableWidth / approxLabelWidth).floor().clamp(1, itemCount);
    final step = (itemCount / maxLabels).ceil().clamp(1, itemCount);
    return step;
  }

  // Widget de texto con rotación y elipsis para ejes
  static Widget rotatedLabel(String text, {double angleDeg = -45, double fontSize = 10, double maxWidth = 60}) {
    return Transform.rotate(
      angle: angleDeg * 3.1415926535 / 180,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: fontSize, color: Colors.grey.shade800),
        ),
      ),
    );
  }
}
