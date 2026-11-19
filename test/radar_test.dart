import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:radar_hidrico/main.dart';
import 'package:radar_hidrico/state/radar_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> snapshot;
  setUpAll(() async {
    snapshot = jsonDecode(
      await rootBundle.loadString('assets/territorio.json'),
    ) as Map<String, dynamic>;
    for (final item in [
      ('Roboto', 'assets/fonts/Roboto-Regular.ttf'),
      ('MaterialIcons', 'assets/fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(item.$1)..addFont(rootBundle.load(item.$2));
      await loader.load();
    }
  });
  testWidgets('Ocorrências, preferências e fonte ampliada', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final data = snapshot;
    final state = RadarState()
      ..data = data
      ..loading = false;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const RadarApp()),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/ocorrencias');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/sobre');
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  test('Limiares e validação do formulário', () {
    expect(volumeLevel(28), 'Crítico');
    expect(volumeLevel(31), 'Alerta');
    expect(volumeLevel(37), 'Atenção');
    expect(volumeLevel(50), 'Normal');
    expect(validateDistrict('a'), isNotNull);
    expect(validateDistrict('Santana'), isNull);
    expect(validateDescription('curto'), isNotNull);
    expect(validateDescription('Vazamento perto da praça.'), isNull);
  });
  testWidgets('Fluxo real de telas, alertas e formulário em celular e tablet', (
    tester,
  ) async {
    final data = snapshot;
    for (final size in [const Size(390, 844), const Size(900, 1000)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final state = RadarState()
        ..data = data
        ..loading = false
        ..offline = true;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: state, child: const RadarApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Radar Hídrico'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width == 390) {}
      for (final name in ['Reservatórios', 'Chuva', 'Vazões']) {
        await tester.ensureVisible(find.text(name));
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (size.width == 390) {}
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      state.toggleScenario(true);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver 3 sinais e alertas'));
      await tester.tap(find.text('Ver 3 sinais e alertas'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Crítico'), findsOneWidget);
      if (size.width == 390) {}
      await tester.tap(find.text('Estoque previsto em sete dias'));
      await tester.pumpAndSettle();
      expect(find.text('CONFIANÇA E DESEMPENHO'), findsOneWidget);
      if (size.width == 390) {}
      await tester.scrollUntilVisible(
        find.text('Registrar observação local'),
        250,
      );
      await tester.tap(find.text('Registrar observação local'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Salvar ocorrência'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Salvar ocorrência'));
      await tester.pumpAndSettle();
      expect(find.textContaining('pelo menos 3'), findsOneWidget);
      if (size.width == 390) {}
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
