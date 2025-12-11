import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vietmap_app/features/map/map_screen.dart';
import 'package:vietmap_app/logging/log_cleaner.dart';
import 'package:vietmap_app/logging/field_logger.dart';
import 'package:vietmap_app/features/simulation/simulation_screen.dart';
import 'package:vietmap_app/features/debug/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clean old logs on startup
  await LogCleaner.cleanOldLogs();
  
  // Initialize field logger
  await FieldLogger.instance.init();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VietMap App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MapScreen(),
        '/simulation': (context) => const SimulationScreen(),
        '/debug': (context) => const DebugScreen(),
      },
    );
  }
}
