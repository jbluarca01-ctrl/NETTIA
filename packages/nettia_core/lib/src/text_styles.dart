import 'package:flutter/material.dart';

/// Fallbacks de fuente monoespaciada: 'monospace' sólo resuelve en Android.
const List<String> kMonoFallback = <String>[
  'monospace',
  'Roboto Mono',
  'Menlo',
  'Courier New',
  'Courier',
];

/// Fondo tenue para código en línea (const en lugar de withOpacity()).
const Color kInlineCodeBg = Color(0x0F000000);
