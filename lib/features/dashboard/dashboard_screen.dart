import 'package:flutter/material.dart';
import 'package:flutter_studyflow/features/courses/widgets/semester_summary_card.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <--- Importante para escuchar cambios
import '../../data/local/hive_data_service.dart';
import '../../data/models/models.dart';
import 'semesters_list.dart';
import 'main_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // --- (Tu función _showAddSemesterForm se queda IGUAL, no la toques) ---
  void _showAddSemesterForm(BuildContext context) {
    final nameController = TextEditingController();
    bool isCurrent = true;

    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;
      final service = HiveDataService();

      // Pequeño truco: Si este es el nuevo "Actual", desmarcamos los anteriores
      if (isCurrent) {
        final box = Hive.box<Semester>(HiveDataService.boxSemesters);
        for (var s in box.values) {
          if (s.isCurrent) {
            s.isCurrent = false;
            s.save();
          }
        }
      }

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
                    labelText: 'Nombre del Ciclo (Ej: 2026-I)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school)),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submitForm(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitForm,
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
        title: const Text(
            'StudyFlow 🚀'), // Cambio de nombre para que se vea más Pro
        centerTitle: true,
      ),
      // AQUÍ OCURRE LA MAGIA DEL DASHBOARD
      body: Column(
        children: [
          // 1. EL DASHBOARD GLOBAL (Resumen del ciclo actual)
          ValueListenableBuilder(
            valueListenable:
                Hive.box<Semester>(HiveDataService.boxSemesters).listenable(),
            builder: (context, Box<Semester> boxSemesters, _) {
              // Buscamos si hay algún semestre marcado como "Actual"
              Semester? currentSemester;
              try {
                currentSemester =
                    boxSemesters.values.firstWhere((s) => s.isCurrent);
              } catch (e) {
                currentSemester = null;
              }

              // Si no hay ciclo actual, no mostramos el resumen
              if (currentSemester == null) return const SizedBox.shrink();

              // Si HAY ciclo actual, necesitamos sus cursos para llenar la tarjeta
              return ValueListenableBuilder(
                valueListenable:
                    Hive.box<Course>(HiveDataService.boxCourses).listenable(),
                builder: (context, Box<Course> boxCourses, _) {
                  final courses = boxCourses.values
                      .where((c) => c.semesterId == currentSemester!.key)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 10),
                        child: Text("Tu Resumen Actual",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ),
                      // Aquí reutilizamos tu componente estrella
                      SemesterSummaryCard(
                          semestreNombre: currentSemester!.name,
                          cursos: courses),
                    ],
                  );
                },
              );
            },
          ),

          // 2. LA LISTA DE SEMESTRES (Historial)
          const Expanded(
            child: SemestersListScreen(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSemesterForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
