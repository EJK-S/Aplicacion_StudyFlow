import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _uniController = TextEditingController();
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    _nameController.text =
        settingsBox.get('userName', defaultValue: 'Jean Carlo');
    _uniController.text = settingsBox.get('university', defaultValue: 'UNMSM');
  }

  void _saveSettings() {
    settingsBox.put('userName', _nameController.text);
    settingsBox.put('university', _uniController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('¡Perfil actualizado! ✅'),
          backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Perfil del Estudiante",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),

          // CAMPO NOMBRE
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
                labelText: "Tu Nombre",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),

          // CAMPO UNIVERSIDAD
          TextField(
            controller: _uniController,
            decoration: const InputDecoration(
                labelText: "Universidad / Institución",
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder()),
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white),
            child: const Text("GUARDAR CAMBIOS"),
          ),

          const SizedBox(height: 40),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Acerca de StudyFlow"),
            subtitle: Text("Versión 1.0.0 Beta"),
          )
        ],
      ),
    );
  }
}
