import 'package:flutter/material.dart';
import 'package:flutter_studyflow/features/tools/screens/pdf_generator_screen.dart';
import 'apa_generator_screen.dart';
import '../../tools/screens/laccei_tool_screen.dart';
import '../../tools/screens/pomodoro_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Herramientas 🛠️')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // HERRAMIENTA 1: APA
            _ToolCard(
              icon: Icons.format_quote,
              color: Colors.orange,
              title: "Generador APA",
              description: "Citas bibliográficas al instante.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ApaGeneratorScreen()),
                );
              },
            ),

            // HERRAMIENTA 2: CARÁTULA
            _ToolCard(
              icon: Icons.picture_as_pdf,
              color: Colors.redAccent,
              title: "Carátula PDF",
              description: "Informes de Labo y Trabajos.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PdfGeneratorScreen()),
                );
              },
            ),

            // HERRAMIENTA 3: LACCEI (CORREGIDO)
            _ToolCard(
              icon: Icons.article,
              color: Colors.blueAccent,
              title: "Plantilla LACCEI",
              description: "Formato paper estándar.",
              onTap: () {
                // 👇 2. AQUÍ ESTABA EL ERROR (Ahora ya navegamos)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LacceiToolScreen()),
                );
              },
            ),

            // HERRAMIENTA 4: POMODORO (Ahora sí funcional)
            _ToolCard(
              icon: Icons.timer,
              color: Colors.redAccent,
              title: "Reloj Pomodoro",
              description: "Técnica de estudio 25/5.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PomodoroScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar (Este se queda igual)
class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                // ignore: deprecated_member_use
                backgroundColor: color.withOpacity(0.2),
                radius: 30,
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
