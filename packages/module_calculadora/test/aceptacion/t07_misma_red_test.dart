// Pasos de aceptación de t07_misma_red.feature.
import 'package:gherkart/gherkart.dart';

import 'comun.dart';
import 'pasos_calculadora.dart';

void main() => correrFeature(
  't07_misma_red.feature',
  StepRegistry<void>.fromMap(pasosCalculadora),
);
