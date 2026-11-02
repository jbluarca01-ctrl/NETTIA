// Pasos de aceptación de t08_resumen_cidr.feature.
import 'package:gherkart/gherkart.dart';

import 'comun.dart';
import 'pasos_calculadora.dart';

void main() => correrFeature(
  't08_resumen_cidr.feature',
  StepRegistry<void>.fromMap(pasosCalculadora),
);
