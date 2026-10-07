// Pasos de aceptación de t02_clasificacion_ipv4.feature.
import 'package:gherkart/gherkart.dart';

import 'comun.dart';
import 'pasos_calculadora.dart';

void main() => correrFeature(
  't02_clasificacion_ipv4.feature',
  StepRegistry<void>.fromMap(pasosCalculadora),
);
