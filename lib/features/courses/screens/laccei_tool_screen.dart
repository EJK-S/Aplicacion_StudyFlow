import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart'; // Ideal para abrir el link oficial

class LacceiToolScreen extends StatelessWidget {
  const LacceiToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Formato LACCEI")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TARJETA DE RESUMEN
          Card(
            color: Colors.blueGrey.shade900,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.article, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Estructura Estándar",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text("Paper Doble Columna",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text("Reglas de Oro 📏",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),

          _buildRuleTile("Papel", "Carta (Letter) 8.5\" x 11\""),
          _buildRuleTile("Márgenes",
              "Superior: 1.9cm | Inferior: 2.54cm\nIzquierdo: 1.9cm | Derecho: 1.9cm"),
          _buildRuleTile("Fuente", "Times New Roman"),
          _buildRuleTile("Título", "24 pts, Centrado, Sin negrita"),
          _buildRuleTile("Autores", "11 pts, Centrado"),
          _buildRuleTile("Cuerpo", "10 pts, Justificado, Espacio simple"),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Aquí podrías poner un link al Word oficial si usas url_launcher
              Clipboard.setData(const ClipboardData(
                  text:
                      "https://laccei.org/index.php/publications/laccei-template/"));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Link copiado al portapapeles")));
            },
            icon: const Icon(Icons.link),
            label: const Text("Copiar Link de Plantilla Oficial"),
          )
        ],
      ),
    );
  }

  Widget _buildRuleTile(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      subtitle: Text(value),
      leading: const Icon(Icons.check_circle_outline, size: 20),
    );
  }
}
