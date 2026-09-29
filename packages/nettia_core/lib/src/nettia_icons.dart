import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/widgets.dart';

/// Íconos de Nettia (Fluent System Icons, de Microsoft). Un único punto de
/// acceso: los módulos no importan el paquete de íconos directamente.
abstract final class NettiaIcons {
  // Módulos
  static const IconData calculadora = FluentIcons.calculator_24_regular;
  static const IconData comandos = FluentIcons.window_console_20_regular;
  static const IconData asistente = FluentIcons.bot_sparkle_24_regular;
  static const IconData guia = FluentIcons.task_list_ltr_24_regular;

  // Sistema
  static const IconData ajustes = FluentIcons.settings_24_regular;
  static const IconData apariencia = FluentIcons.paint_brush_24_regular;
  static const IconData acercaDe = FluentIcons.info_24_regular;
  static const IconData clave = FluentIcons.key_24_regular;
  static const IconData conexion = FluentIcons.plug_connected_24_regular;
  static const IconData offline = FluentIcons.cloud_off_24_regular;
  static const IconData motorIa = FluentIcons.bot_24_regular;
  static const IconData preferencias = FluentIcons.flash_24_regular;
  static const IconData perfil = FluentIcons.person_24_regular;
  static const IconData estudiante = FluentIcons.hat_graduation_24_regular;
  static const IconData profesional = FluentIcons.briefcase_24_regular;

  // Acciones
  static const IconData copiar = FluentIcons.copy_24_regular;
  static const IconData enviar = FluentIcons.arrow_up_24_filled;
  static const IconData detener = FluentIcons.stop_24_filled;
  static const IconData mostrar = FluentIcons.eye_24_regular;
  static const IconData ocultar = FluentIcons.eye_off_24_regular;
  static const IconData guardar = FluentIcons.checkmark_24_regular;
  static const IconData validado = FluentIcons.checkmark_circle_24_regular;
  static const IconData aviso = FluentIcons.warning_24_regular;
  static const IconData menu = FluentIcons.navigation_24_regular;

  // Dispositivos (guía y comandos)
  static const IconData pc = FluentIcons.desktop_24_regular;
  static const IconData router = FluentIcons.router_24_regular;
  static const IconData switchRed = FluentIcons.server_24_regular;
  static const IconData diagrama = FluentIcons.diagram_24_regular;
  static const IconData libro = FluentIcons.book_open_24_regular;
}
