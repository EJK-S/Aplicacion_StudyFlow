import 'package:flutter/material.dart';
import '../../data/local/hive_data_service.dart';
import '../../data/models/models.dart';
import 'semesters_list.dart';
import 'main_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

// Función para mostrar el formulario deslizable
  void _showAddSemesterForm(BuildContext context) {
    final nameController = TextEditingController();
    bool isCurrent = true;

    // Lógica encapsulada
    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;
      final service = HiveDataService();
      final nuevo = Semester()
        ..name = nameController.text
        ..startDate = DateTime.now()
        ..isCurrent = isCurrent;
      await service.saveSemester(nuevo);
      if (context.mounted) Navigator.pop(context);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nuevo Semestre 📅',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nombre del Ciclo (Ej: 2025-1)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school)),
                autofocus: true,
                // 👇 MAGIA: Enter = Guardar
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submitForm(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitForm, // Usamos la misma función
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white),
                child: const Text('GUARDAR CICLO'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Mis Ciclos 🎓'),
        centerTitle: true,
      ),
      body: const SemestersListScreen(), // <--- Aquí llamamos a la lista
      floatingActionButton: FloatingActionButton(
        // En lugar de crear datos falsos, llamamos a la función visual:
        onPressed: () => _showAddSemesterForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
