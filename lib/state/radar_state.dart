import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RadarAlert {
  final String id, title, level, evidence, confidence, limitation;
  const RadarAlert(
    this.id,
    this.title,
    this.level,
    this.evidence,
    this.confidence,
    this.limitation,
  );
}

String? validateDistrict(String? v) => (v?.trim().length ?? 0) < 3
    ? 'Informe um bairro com pelo menos 3 caracteres.'
    : null;
String? validateDescription(String? v) => (v?.trim().length ?? 0) < 10
    ? 'Descreva a situação com pelo menos 10 caracteres.'
    : null;
String volumeLevel(double v) => v <= 30.019085
    ? 'Crítico'
    : v <= 32.53807
    ? 'Alerta'
    : v <= 38.34082
    ? 'Atenção'
    : 'Normal';

class RadarState extends ChangeNotifier {
  Map<String, dynamic>? data;
  List<Map<String, dynamic>> occurrences = [];
  bool loading = true,
      offline = false,
      dark = false,
      consent = false,
      scenario = false;
  String? error;
  SharedPreferences? _prefs;
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      dark = _prefs!.getBool('dark') ?? false;
      consent = _prefs!.getBool('consent') ?? false;
      occurrences = (jsonDecode(
        _prefs!.getString('occurrences') ?? '[]',
      ) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      try {
        const url = String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://localhost:3001/api/territorio',
        );
        final r = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 4));
        if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        if (j is! Map || j['historico'] is! List) {
          throw const FormatException('Dados incompatíveis');
        }
        data = Map<String, dynamic>.from(j);
        offline = false;
        await _prefs!.setString('cache', jsonEncode(data));
      } catch (_) {
        offline = true;
        data = Map<String, dynamic>.from(
          jsonDecode(
            _prefs!.getString('cache') ??
                await rootBundle.loadString('assets/territorio.json'),
          ),
        );
      }
    } catch (_) {
      error = 'Não foi possível carregar os dados locais. Tente novamente.';
    }
    loading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> get history => ((data?['historico'] ?? []) as List)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  Map<String, dynamic> get prediction =>
      Map<String, dynamic>.from(data?['previsao'] ?? {});
  double get volume =>
      scenario ? 28 : (prediction['volume_atual_pct'] as num? ?? 0).toDouble();
  double get forecast => scenario
      ? 26
      : (prediction['volume_previsto_pct'] as num? ?? 0).toDouble();
  List<RadarAlert> get alerts {
    if (data == null || history.isEmpty) return [];
    final p = prediction;
    final rain = (p['chuva_30d_mm'] as num? ?? 0).toDouble();
    final flow = (p['balanco_parcial_7d_m3s'] as num? ?? 0).toDouble();
    return [
      RadarAlert(
        'volume',
        'Estoque previsto em sete dias',
        volumeLevel(forecast),
        'Volume atual ${volume.toStringAsFixed(2)}%. Projeção ${forecast.toStringAsFixed(2)}% para ${p['data_alvo']}. Limiares históricos: atenção ≤38,34%; alerta ≤32,54%; crítico ≤30,02%.',
        scenario ? 'Cenário sintético de teste, sem probabilidade estimada.' : 'Ridge teve MAE de 0,65 p.p. no teste. Faixa empírica ±1,77 p.p.; cobertura retrospectiva 92,8%, sem garantia futura.',
        'Não representa cada bairro. Chuva futura e mudanças operacionais alteram a projeção. Limiares exploratórios, não oficiais.',
      ),
      if (rain > 100)
        RadarAlert(
          'chuva',
          'Acompanhar a chuva acumulada',
          'Informativo',
          '$rain mm nos últimos 30 dias. Regra de acompanhamento: acumulado acima de 100 mm.',
          'Regra descritiva sobre medidas oficiais; não é probabilidade de enchente.',
          'Chuva agregada não identifica impactos em ruas ou moradias.',
        ),
      if (flow > 0)
        RadarAlert(
          'fluxo',
          'Verificar diferença entre vazões',
          'Informativo',
          'Diferença média afluente menos captada em sete dias: ${flow.toStringAsFixed(2)} m³/s. Regra: diferença positiva.',
          'Indicador calculado sobre observações; depende da qualidade dos boletins.',
          'Balanço parcial. Não inclui todas as perdas, transferências ou descargas.',
        ),
    ];
  }

  Future<void> toggleDark(bool v) async {
    dark = v;
    await _prefs?.setBool('dark', v);
    notifyListeners();
  }

  void toggleScenario(bool v) {
    scenario = v;
    notifyListeners();
  }

  Future<void> accept(bool v) async {
    consent = v;
    await _prefs?.setBool('consent', v);
    notifyListeners();
  }

  Future<void> addOccurrence(
    String district,
    String category,
    String description,
  ) async {
    if (!consent) throw StateError('Consentimento necessário.');
    if (validateDistrict(district) != null ||
        validateDescription(description) != null) {
      throw ArgumentError('Confira os campos.');
    }
    occurrences.insert(0, {
      'bairro': district.trim(),
      'categoria': category,
      'descricao': description.trim(),
      'data': DateTime.now().toIso8601String(),
    });
    await _prefs!.setString('occurrences', jsonEncode(occurrences));
    notifyListeners();
  }

  Future<void> clearOccurrences() async {
    occurrences = [];
    consent = false;
    await _prefs?.remove('occurrences');
    await _prefs?.setBool('consent', false);
    notifyListeners();
  }
}
