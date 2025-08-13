// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

Color getColorForGrado(String grado) {
  switch (grado) {
    case 'Maternal':
      return Colors.blue;
    case 'Kínder 1':
      return Colors.amber.shade500;
    case 'Kínder 2':
      return Colors.red.shade600;
    case 'Kínder 3':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
