import 'package:flutter/material.dart';
import 'package:vietmap_app/features/map/map_screen.dart';
import 'package:vietmap_app/logging/log_cleaner.dart';
import 'package:vietmap_app/logging/field_logger.dart';
import 'package:vietmap_app/features/simulation/simulation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clean old logs on startup
  await LogCleaner.cleanOldLogs();
  
  // Initialize field logger
  await FieldLogger.instance.init();
  
  runApp(const MyApp());
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
      routes: {
        '/simulation': (context) => const SimulationScreen(),
      },
      home: const MapScreen(),
    );
  }
}
