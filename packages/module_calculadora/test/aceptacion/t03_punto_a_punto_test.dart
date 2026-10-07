// Pasos de aceptación de t03_punto_a_punto.feature.
import 'package:gherkart/gherkart.dart';

import 'comun.dart';
import 'pasos_calculadora.dart';

void main() => correrFeature(
  't03_punto_a_punto.feature',
  StepRegistry<void>.fromMap(pasosCalculadora),
);
