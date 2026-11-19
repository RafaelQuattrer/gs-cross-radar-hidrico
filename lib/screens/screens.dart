import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/radar_state.dart';
import '../widgets/components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    if (s.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Carregando dados'),
        ),
      );
    }
    if (s.error != null) {
      return RadarPage(
        title: 'Radar Hídrico',
        children: [
          Notice(s.error!),
          FilledButton(
            onPressed: s.load,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }
    return RadarPage(
      title: 'Radar Hídrico',
      actions: [
        IconButton(
          tooltip: 'Sobre e preferências',
          onPressed: () => Navigator.pushNamed(context, '/sobre'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      children: [
        Text(
          'ANTECIPAR PARA CUIDAR',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(letterSpacing: 2),
        ),
        Text(
          'A água do território,\nem uma visão clara.',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${s.data?['territorio']}\nFotografia em ${s.data?['atualizadoEm']}',
        ),
        if (s.offline)
          const Notice(
            'Sem conexão com a API. Exibindo cache ou fotografia pública incluída no app.',
            icon: Icons.cloud_off_outlined,
          ),
        if (s.scenario)
          const Notice(
            'CENÁRIO SINTÉTICO ATIVO. Valores 28% e 26% apenas para demonstrar um alerta crítico.',
          ),
        MetricCard(
          title: 'Volume útil',
          value: '${s.volume.toStringAsFixed(2)}%',
          detail:
              'Previsão em 7 dias: ${s.forecast.toStringAsFixed(2)}% · ${volumeLevel(s.forecast)}',
          onTap: () =>
              Navigator.pushNamed(context, '/dashboard', arguments: 'volume'),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in [
              ('volume', 'Reservatórios', Icons.water),
              ('chuva', 'Chuva', Icons.cloud_outlined),
              ('vazao', 'Vazões', Icons.waves),
            ])
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/dashboard',
                  arguments: item.$1,
                ),
                icon: Icon(item.$3),
                label: Text(item.$2),
              ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/alertas'),
          icon: const Icon(Icons.notifications_outlined),
          label: Text('Ver ${s.alerts.length} sinais e alertas'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/ocorrencias'),
          icon: const Icon(Icons.edit_note),
          label: Text('Ocorrências locais (${s.occurrences.length})'),
        ),
        const MetricCard(
          title: 'Benefício social em avaliação',
          value: '7 dias',
          detail: 'Horizonte para planejar a verificação. No teste, 7 de 7 oportunidades de cruzamento foram antecipadas. Janelas sobrepostas, não crises independentes.',
          icon: Icons.groups_outlined,
        ),
        const Notice(
          'Alertas apoiam a análise. A decisão final é humana. Nenhuma ação sobre o abastecimento é executada pelo aplicativo.',
        ),
        TextButton(onPressed: s.load, child: const Text('Atualizar pela API')),
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    final key =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'volume';
    final h = s.history;
    final field = key == 'volume'
            ? 'volume_pct'
            : key == 'chuva'
            ? 'chuva_mm'
            : 'afluente_m3s',
        title = key == 'volume'
            ? 'Reservatórios'
            : key == 'chuva'
            ? 'Chuva no território'
            : 'Vazões do sistema',
        unit = key == 'volume'
            ? '%'
            : key == 'chuva'
            ? 'mm'
            : 'm³/s';
    if (h.isEmpty) {
      return RadarPage(
        title: title,
        children: const [
          Notice('Nenhum dado disponível para este território.'),
        ],
      );
    }
    final vals = h.map((r) => double.parse(r[field].toString())).toList();
    final change = vals.last - vals[vals.length - 8];
    return RadarPage(
      title: title,
      children: [
        Text(
          'Sistema Cantareira · últimos 60 dias',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        MetricCard(
          title: 'Última observação',
          value: '${vals.last.toStringAsFixed(2)} $unit',
          detail:
              'Variação em 7 dias: ${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} ${key == 'volume' ? 'p.p.' : unit}. Data ${h.last['data']}.',
        ),
        HistoryChart(
          values: vals,
          label: 'Histórico diário ($unit)',
          first: h.first['data'],
          last: h.last['data'],
        ),
        if (key == 'volume')
          MetricCard(
            title: 'Projeção para ${s.prediction['data_alvo']}',
            value: '${s.forecast.toStringAsFixed(2)}%',
            detail: s.scenario
                ? 'Demonstração sintética, sem intervalo estatístico.'
                : 'Ridge. Faixa empírica: 57,03% a 60,56%. A previsão ainda não foi observada.',
          ),
        if (key == 'chuva')
          MetricCard(
            title: 'Acumulado em 30 dias',
            value: '${s.prediction['chuva_30d_mm']} mm',
            detail:
                'Soma diária da precipitação, sem previsão de chuva futura.',
            icon: Icons.cloud_outlined,
          ),
        if (key == 'vazao')
          MetricCard(
            title: 'Captação mais recente',
            value:
                '${double.parse(h.last['captada_m3s']).toStringAsFixed(2)} m³/s',
            detail: 'Diferença afluente menos captada em 7 dias: 47,98 m³/s. Balanço parcial.',
            icon: Icons.waves,
          ),
        const Notice(
          'Fonte Sabesp. Dados agregados do sistema não estimam o abastecimento de um bairro específico.',
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(
            context,
            '/alerta',
            arguments: key == 'volume'
                ? 'volume'
                : key == 'chuva'
                ? 'chuva'
                : 'fluxo',
          ),
          child: const Text('Entender o sinal deste indicador'),
        ),
        ExpansionTile(
          title: const Text('Consultar valores em texto'),
          children: [
            for (final r in h.reversed.take(7))
              ListTile(
                title: Text('${r['data']}'),
                trailing: Text(
                  '${double.parse(r[field]).toStringAsFixed(2)} $unit',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    return RadarPage(
      title: 'Sinais e alertas',
      children: [
        const Notice(
          'Critérios exploratórios. Toda ação depende de revisão humana.',
        ),
        if (s.alerts.isEmpty) const Text('Nenhum alerta disponível.'),
        for (final a in s.alerts)
          Card(
            child: ListTile(
              isThreeLine: true,
              leading: Icon(
                a.level == 'Crítico' ? Icons.warning_amber : Icons.insights,
              ),
              title: Text(a.title),
              subtitle: Text(
                '${a.level}\nToque para ver evidência e limitações.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, '/alerta', arguments: a.id),
            ),
          ),
      ],
    );
  }
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    final id =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'volume';
    final matches = s.alerts.where((a) => a.id == id);
    if (matches.isEmpty) {
      return const RadarPage(
        title: 'Alerta',
        children: [Text('Alerta não encontrado.')],
      );
    }
    final a = matches.first;
    return RadarPage(
      title: 'Detalhe do alerta',
      children: [
        Text(
          a.level.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(a.title, style: Theme.of(context).textTheme.headlineMedium),
        const Text('EVIDÊNCIA', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(a.evidence),
        const Text(
          'CONFIANÇA E DESEMPENHO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(a.confidence),
        const Text('LIMITAÇÕES', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(a.limitation),
        const Notice(
          'Decisão final humana. Confira o boletim oficial e consulte a equipe responsável antes de qualquer medida.',
        ),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/nova'),
          child: const Text('Registrar observação local'),
        ),
      ],
    );
  }
}

class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    return RadarPage(
      title: 'Ocorrências locais',
      children: [
        const Notice(
          'Registros ficam neste dispositivo. Não são comunicados à Sabesp ou à prefeitura.',
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/nova'),
          icon: const Icon(Icons.add),
          label: const Text('Nova ocorrência'),
        ),
        if (s.occurrences.isEmpty)
          const Text(
            'Nenhuma ocorrência registrada. Use o botão acima para começar.',
          ),
        for (final o in s.occurrences)
          Card(
            child: ListTile(
              title: Text('${o['categoria']} · ${o['bairro']}'),
              subtitle: Text(
                '${o['descricao']}\n${o['data'].toString().substring(0, 10)}',
              ),
            ),
          ),
        if (s.occurrences.isNotEmpty)
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Apagar registros locais?'),
                  content: const Text(
                    'As ocorrências deste dispositivo serão removidas.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Apagar'),
                    ),
                  ],
                ),
              );
              if (ok == true) await s.clearOccurrences();
            },
            child: const Text('Apagar minhas ocorrências'),
          ),
      ],
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final form = GlobalKey<FormState>();
  final district = TextEditingController(),
      description = TextEditingController();
  String category = 'Vazamento';
  bool agreed = false, saving = false;
  @override
  void dispose() {
    district.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RadarPage(
    title: 'Nova ocorrência',
    children: [
      const Notice(
        'Informe apenas o bairro. Não escreva nomes, telefone, endereço exato ou dados pessoais.',
      ),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: district,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Bairro'),
              validator: validateDistrict,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                'Vazamento',
                'Desperdício',
                'Falta de água',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: description,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descrição sem dados pessoais',
              ),
              validator: validateDescription,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text(
                'Concordo em guardar esta ocorrência somente neste dispositivo e declaro não incluir dados pessoais.',
              ),
            ),
            if (!agreed)
              const Text('O consentimento é necessário para salvar.'),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate() || !agreed) return;
                      setState(() => saving = true);
                      try {
                        final s = context.read<RadarState>();
                        await s.accept(true);
                        await s.addOccurrence(
                          district.text,
                          category,
                          description.text,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ocorrência salva neste dispositivo.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível salvar. Tente novamente.',
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              child: Text(saving ? 'Salvando…' : 'Salvar ocorrência'),
            ),
          ],
        ),
      ),
    ],
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    return RadarPage(
      title: 'Sobre e preferências',
      children: [
        const Text(
          'Radar Hídrico',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const Text(
          'CitizenTech para acompanhar recursos hídricos. Público: gestores e cidadãos da RMSP. ODS 6 e 11.',
        ),
        SwitchListTile(
          title: const Text('Tema escuro'),
          value: s.dark,
          onChanged: s.toggleDark,
        ),
        SwitchListTile(
          title: const Text('Demonstrar cenário crítico sintético'),
          subtitle: const Text(
            'Altera apenas o alerta de volume; não muda os gráficos reais.',
          ),
          value: s.scenario,
          onChanged: s.toggleScenario,
        ),
        const Text(
          'Dados oficiais da Sabesp, fotografia em 19/11/2026. A API deste projeto serve essa fotografia, sem atualização automática da fonte. Modelo e indicadores calculados no trabalho de Data Science.',
        ),
        const Text(
          'Acessibilidade: texto escalável, rótulos semânticos, gráficos também em texto e contraste Material. Registros locais não são enviados a servidores. Não coletamos nome, contato ou localização precisa.',
        ),
        const Notice(
          'Para retirar o consentimento e apagar o conteúdo, use “Apagar minhas ocorrências”. Preferências e cache não contêm identificação pessoal.',
        ),
        const Text(
          'Rafael Quattrer Dalla Costa\nRM 562052\nFIAP · GS 2026.2 · Cross-Platform Application Development',
        ),
      ],
    );
  }
}
