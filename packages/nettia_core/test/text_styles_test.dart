import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';

void main() {
  test('kMonoFallback lista las fuentes monoespaciadas en orden', () {
    expect(kMonoFallback, ['monospace', 'Roboto Mono', 'Menlo', 'Courier New', 'Courier']);
  });

  test('kInlineCodeBg es negro con alfa 0x0F', () {
    expect(kInlineCodeBg, const Color(0x0F000000));
  });
}
