import 'package:flutter/material.dart';
import 'package:flutter_studyflow/features/courses/screens/tools_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // CABECERA DEL MENÚ (Tu "Perfil" rápido)
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            accountName: Text("Jean Carlo",
                style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("Universidad Nacional Mayor de San Marcos"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
            ),
          ),

          // OPCIONES DEL MENÚ
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Mis Ciclos'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú
              // Ya estamos aquí, no hacemos nada más
            },
          ),
          ListTile(
            leading: const Icon(Icons.build_circle), // Icono de herramientas
            title: const Text('Herramientas (PDF/APA)'),
            onTap: () {
              Navigator.pop(context);
              // Navegar a pantalla de herramientas (Semana 3)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ToolsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Mi Horario'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Próximamente: Horario")));
            },
          ),
          const Divider(), // Línea separadora
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              // Navegar a Settings
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Próximamente: Modo Oscuro y Perfil")));
            },
          ),
        ],
      ),
    );
  }
}
