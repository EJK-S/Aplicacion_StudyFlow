import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';
import '../widgets/semester_summary_card.dart'; // <--- 1. ASEGÚRATE DE IMPORTAR ESTO
import 'course_grades_screen.dart';

class CoursesListScreen extends StatefulWidget {
  final Semester semester;

  const CoursesListScreen({super.key, required this.semester});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  // --- Formulario para agregar curso (Sin cambios) ---
  void _showAddCourseForm(BuildContext context) {
    final nameController = TextEditingController();
    final creditsController = TextEditingController(text: '3');
    final profController = TextEditingController();

    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;
      final service = HiveDataService();
      final newCourse = Course()
        ..name = nameController.text
        ..credits = int.tryParse(creditsController.text) ?? 0
        ..professorName = profController.text
        ..semesterId = widget.semester.key;
      await service.saveCourse(newCourse);
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
              const Text('Nuevo Curso 📚',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nombre (Ej: Cálculo II)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book)),
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: creditsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Créditos',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers)),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: profController,
                      decoration: const InputDecoration(
                          labelText: 'Profesor (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person)),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitForm(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitForm,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('GUARDAR CURSO'),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semester.name),
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<Course>(HiveDataService.boxCourses).listenable(),
        builder: (context, Box<Course> box, _) {
          // Filtramos cursos del semestre actual
          final courses = box.values
              .where((c) => c.semesterId == widget.semester.key)
              .toList();

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("No hay cursos en ${widget.semester.name}",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // --- CAMBIO PRINCIPAL AQUÍ ---
          return Column(
            children: [
              // 1. La Tarjeta de Resumen Arriba
              SemesterSummaryCard(
                semestreNombre: widget.semester.name,
                cursos: courses,
              ),

              // 2. La Lista de Cursos Abajo
              Expanded(
                child: ListView.builder(
                  itemCount: courses.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Text(course.name.isNotEmpty
                                ? course.name[0].toUpperCase()
                                : '?')),
                        title: Text(course.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Prof: ${course.professorName!.isNotEmpty ? course.professorName : 'Sin asignar'} • ${course.credits} créditos"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CourseGradesScreen(course: course),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCourseForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
