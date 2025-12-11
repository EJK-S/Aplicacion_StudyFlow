import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_data_service.dart'; // Importa tu nuevo servicio
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  // <--- Haz el main async
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Hive
  final dataService = HiveDataService();
  await dataService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        // Un tema oscuro básico para cuidar tus ojos de programador
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      themeMode: ThemeMode.system, // Usa el tema de tu sistema
      home: const DashboardScreen(), // Nuestra pantalla inicial
    );
  }
}
