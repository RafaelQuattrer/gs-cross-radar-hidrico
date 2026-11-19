import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'state/radar_state.dart';
import 'screens/screens.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => RadarState()..load(),
    child: const RadarApp(),
  ),
);

class RadarApp extends StatelessWidget {
  const RadarApp({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<RadarState>();
    return MaterialApp(
      title: 'Radar Hídrico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff145e58),
          brightness: s.dark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: s.dark
            ? const Color(0xff112225)
            : const Color(0xfff3f7f5),
        cardTheme: const CardThemeData(elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/alertas': (_) => const AlertsScreen(),
        '/alerta': (_) => const AlertDetailScreen(),
        '/ocorrencias': (_) => const OccurrencesScreen(),
        '/nova': (_) => const FormScreen(),
        '/sobre': (_) => const AboutScreen(),
      },
    );
  }
}
