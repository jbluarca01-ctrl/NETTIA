// Pasos de aceptación de t05_bloque_y_and.feature.
import 'package:gherkart/gherkart.dart';

import 'comun.dart';
import 'pasos_calculadora.dart';

void main() => correrFeature(
  't05_bloque_y_and.feature',
  StepRegistry<void>.fromMap(pasosCalculadora),
);
