import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nettia_core/nettia_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sin perfil guardado, hasProfile es falso', () async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    expect(UserProfileService.instance.hasProfile, isFalse);
    expect(UserProfileService.instance.profile, isNull);
  });

  test('el perfil elegido se guarda y se recupera al recargar', () async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    await UserProfileService.instance.setProfile(UserProfile.profesional);

    // Simula un nuevo arranque: se lee otra vez desde el almacenamiento.
    await UserProfileService.instance.load();
    expect(UserProfileService.instance.profile, UserProfile.profesional);
  });

  test('un valor guardado desconocido se trata como sin perfil', () async {
    SharedPreferences.setMockInitialValues({'nettia_user_profile': 'otro'});
    await UserProfileService.instance.load();
    expect(UserProfileService.instance.hasProfile, isFalse);
  });

  test('un valor guardado con tipo inválido no lanza y deja el perfil vacío', () async {
    SharedPreferences.setMockInitialValues({'nettia_user_profile': 123});
    await UserProfileService.instance.load();
    expect(UserProfileService.instance.hasProfile, isFalse);
    expect(UserProfileService.instance.profile, isNull);
  });

  test('un valor guardado con tipo inválido se reporta con debugPrint', () async {
    final mensajes = <String>[];
    final original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => mensajes.add(m ?? '');
    addTearDown(() => debugPrint = original);

    SharedPreferences.setMockInitialValues({'nettia_user_profile': 123});
    await UserProfileService.instance.load();

    expect(mensajes, hasLength(1));
    expect(mensajes.single, startsWith('Nettia: no se pudo cargar el perfil de usuario: '));
  });

  test('elegir el mismo perfil otra vez no notifica de nuevo', () async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    await UserProfileService.instance.setProfile(UserProfile.estudiante);

    var avisos = 0;
    void oyente() => avisos++;
    UserProfileService.instance.addListener(oyente);
    addTearDown(() => UserProfileService.instance.removeListener(oyente));

    await UserProfileService.instance.setProfile(UserProfile.estudiante);
    expect(avisos, 0);

    await UserProfileService.instance.setProfile(UserProfile.profesional);
    expect(avisos, 1);
  });

  test('hoy ambos perfiles ven todos los módulos', () {
    for (final p in UserProfile.values) {
      for (final m in NettiaModulo.values) {
        expect(p.puedeUsar(m), isTrue, reason: '$p / $m');
      }
    }
  });

  test('una función solo profesional se oculta al estudiante', () {
    expect(UserProfile.estudiante.permite(soloProfesional: true), isFalse);
    expect(UserProfile.profesional.permite(soloProfesional: true), isTrue);
    expect(UserProfile.estudiante.permite(soloProfesional: false), isTrue);
  });

  testWidgets('la pantalla de selección usa los tamaños y colores del mockup', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: ProfileSelectionScreen(onSelected: () {}),
      ),
    );

    final logo = tester.widget<NettiaLogo>(find.byType(NettiaLogo));
    expect(logo.size, 56);

    expect(tester.widget<Text>(find.text('Estudiante')).style?.fontSize, 16);
    expect(tester.widget<Text>(find.text('Profesional')).style?.fontSize, 16);

    final descripciones = tester.widgetList<Text>(find.byType(Text)).where(
          (t) => t.style?.fontSize == 12.5,
        );
    expect(descripciones, isNotEmpty);

    final materiales = tester.widgetList<Material>(find.byType(Material));
    final conAlpha = materiales.where((m) {
      final color = m.color;
      return color != null && (color.a - 0.10).abs() < 0.01;
    });
    expect(conAlpha, isNotEmpty);
  });

  testWidgets('la pantalla de selección guarda el perfil y avisa', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    var avisado = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: ProfileSelectionScreen(onSelected: () => avisado = true),
      ),
    );
    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Profesional'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);

    await tester.tap(find.text('Profesional'));
    await tester.pump();
    await tester.pump();

    expect(UserProfileService.instance.profile, UserProfile.profesional);
    expect(avisado, isTrue);
  });

  testWidgets('tocar "Estudiante" guarda ese perfil y avisa', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    var avisado = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: ProfileSelectionScreen(onSelected: () => avisado = true),
      ),
    );

    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.profile, UserProfile.estudiante);
    expect(avisado, isTrue);
  });

  testWidgets('si la pantalla se desmonta mientras guarda, no avisa', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    await UserProfileService.instance.setProfile(UserProfile.estudiante);
    var avisado = false;
    final oculta = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: ValueListenableBuilder<bool>(
          valueListenable: oculta,
          builder: (_, o, _) =>
              o ? const SizedBox() : ProfileSelectionScreen(onSelected: () => avisado = true),
        ),
      ),
    );

    void desmontar() {
      oculta.value = true;
      tester.binding.drawFrame();
    }

    UserProfileService.instance.addListener(desmontar);
    addTearDown(() => UserProfileService.instance.removeListener(desmontar));

    await tester.tap(find.text('Profesional'));
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.profile, UserProfile.profesional);
    expect(avisado, isFalse);
  });

  testWidgets('tocar dos veces mientras guarda no dispara el guardado dos veces', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.instance.load();
    var vecesAvisado = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: NetworkTheme.darkTheme,
        home: ProfileSelectionScreen(onSelected: () => vecesAvisado++),
      ),
    );

    await tester.tap(find.text('Profesional'));
    await tester.tap(find.text('Profesional'));
    await tester.pumpAndSettle();

    expect(vecesAvisado, 1);
  });
}
