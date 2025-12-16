import 'package:flutter/material.dart';
import 'package:flutter_studyflow/data/local/backup_service.dart';
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

          ListTile(
            leading: const Icon(Icons.save_alt,
                color: Colors.blueAccent), // Icono de guardar
            title: const Text('Exportar Datos (Backup)'),
            subtitle: const Text('Guarda tus notas en un archivo'),
            onTap: () async {
              // Cerramos el drawer primero
              Navigator.pop(context);

              // Llamamos al servicio
              // (Asegúrate de importar el archivo backup_service.dart arriba)
              await BackupService().exportData(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.restore_page, color: Colors.orangeAccent),
            title: const Text('Restaurar Datos'),
            subtitle: const Text('Importar archivo .json'),
            onTap: () async {
              Navigator.pop(context); // Cerrar menú

              // Alerta de seguridad antes de borrar todo
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("⚠️ ¿Restaurar copia?"),
                  content: const Text(
                      "Esto BORRARÁ todos los datos actuales y los reemplazará por los del archivo.\n\n¿Estás seguro?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancelar")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Cerrar alerta
                        BackupService().restoreData(context); // Iniciar proceso
                      },
                      child: const Text("SÍ, RESTAURAR",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
