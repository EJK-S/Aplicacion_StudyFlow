import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/local/backup_service.dart';
// Importamos la nueva pantalla de configuración que crearemos en el Paso 2
import '../settings/settings_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos ValueListenable para que el nombre se actualice si lo cambias en Configuración
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. CABECERA (Perfil editable)
          ValueListenableBuilder(
            valueListenable:
                Hive.box('settingsBox').listenable(), // Escuchamos cambios
            builder: (context, Box box, _) {
              final userName = box.get('userName', defaultValue: 'Estudiante');
              final university =
                  box.get('university', defaultValue: 'Mi Universidad');

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    image: DecorationImage(
                        image: NetworkImage(
                            "https://img.freepik.com/free-vector/geometric-science-education-background-vector-gradient-blue-digital-remix_53876-125993.jpg"),
                        fit: BoxFit.cover,
                        opacity: 0.5)),
                accountName: Text(userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                accountEmail: Text(university),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                ),
              );
            },
          ),

          // 2. OPCIONES DEL SISTEMA
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Configuración'),
            subtitle: const Text('Editar perfil y preferencias'),
            onTap: () {
              Navigator.pop(context); // Cerrar drawer
              // Navegar a la pantalla de configuración
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 10, bottom: 10),
            child: Text("GESTIÓN DE DATOS",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),

          // 3. BACKUP (Exportar)
          ListTile(
            leading: const Icon(Icons.download, color: Colors.blue),
            title: const Text('Exportar Datos'),
            subtitle: const Text('Guardar copia de seguridad'),
            onTap: () {
              Navigator.pop(context);
              BackupService().exportData(context);
            },
          ),

          // 4. RESTORE (Importar)
          ListTile(
            leading: const Icon(Icons.restore_page, color: Colors.orange),
            title: const Text('Restaurar Datos'),
            subtitle: const Text('Importar archivo .json'),
            onTap: () {
              Navigator.pop(context);
              _showRestoreAlert(context);
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreAlert(BuildContext context) {
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
              Navigator.pop(ctx);
              BackupService().restoreData(context);
            },
            child: const Text("SÍ, RESTAURAR",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
