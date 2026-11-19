import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class RadarPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  const RadarPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: children
              .expand((w) => [w, const SizedBox(height: 16)])
              .toList(),
        ),
      ),
    ),
  );
}

class MetricCard extends StatelessWidget {
  final String title, value, detail;
  final IconData icon;
  final VoidCallback? onTap;
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.detail,
    this.icon = Icons.water_drop_outlined,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(detail),
          ],
        ),
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  const Notice(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class HistoryChart extends StatelessWidget {
  final List<double> values;
  final String label, first, last;
  const HistoryChart({
    super.key,
    required this.values,
    required this.label,
    required this.first,
    required this.last,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 18),
          Semantics(
            label:
                '$label. De $first a $last. Mínimo ${values.reduce(math.min).toStringAsFixed(2)}; máximo ${values.reduce(math.max).toStringAsFixed(2)}.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 170,
                child: CustomPaint(
                  painter: _Line(values, Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 20,
            children: [Text(first), Text(last)],
          ),
        ],
      ),
    ),
  );
}

class _Line extends CustomPainter {
  final List<double> values;
  final Color color;
  _Line(this.values, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final range = max - min == 0 ? 1 : max - min;
    final grid = Paint()
      ..color = color.withValues(alpha: .15)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1),
          y = size.height - 10 - (values[i] - min) / range * (size.height - 20);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _Line old) =>
      old.values != values || old.color != color;
}
