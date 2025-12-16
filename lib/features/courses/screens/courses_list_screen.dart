import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';
import '../widgets/semester_summary_card.dart';
import 'course_grades_screen.dart';

class CoursesListScreen extends StatefulWidget {
  final Semester semester;

  const CoursesListScreen({super.key, required this.semester});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  // --- FORMULARIO HÍBRIDO (CREAR / EDITAR) ---
  // Ahora recibe un parámetro opcional 'courseToEdit'
  void _showCourseForm(BuildContext context, {Course? courseToEdit}) {
    final isEditing = courseToEdit != null;

    // Si estamos editando, rellenamos los campos. Si no, van vacíos.
    final nameController =
        TextEditingController(text: isEditing ? courseToEdit.name : '');
    final creditsController = TextEditingController(
        text: isEditing ? courseToEdit.credits.toString() : '3');
    final profController = TextEditingController(
        text: isEditing ? courseToEdit.professorName : '');

    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;

      if (isEditing) {
        // --- LÓGICA DE EDICIÓN ---
        // Actualizamos las propiedades del objeto existente
        courseToEdit.name = nameController.text;
        courseToEdit.credits = int.tryParse(creditsController.text) ?? 0;
        courseToEdit.professorName = profController.text;

        // ¡MAGIA DE HIVE! .save() actualiza el registro en la base de datos
        await courseToEdit.save();
      } else {
        // --- LÓGICA DE CREACIÓN ---
        final service = HiveDataService();
        final newCourse = Course()
          ..name = nameController.text
          ..credits = int.tryParse(creditsController.text) ?? 0
          ..professorName = profController.text
          ..semesterId =
              widget.semester.key; // Usamos la key del semestre padre
        await service.saveCourse(newCourse);
      }

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
              Text(isEditing ? 'Editar Curso ✏️' : 'Nuevo Curso 📚',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
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
                child: Text(isEditing ? 'ACTUALIZAR DATOS' : 'GUARDAR CURSO'),
              )
            ],
          ),
        );
      },
    );
  }

  // --- FUNCIÓN DE BORRADO BLINDADA ---
  void _deleteCourse(BuildContext context, Course course) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar tocando afuera mientras borra
      builder: (ctx) => AlertDialog(
        title: const Text("¿Borrar curso?"),
        content: Text("Se eliminará '${course.name}' y todas sus notas."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              // 1. GUARDAR REFERENCIA
              final navigator = Navigator.of(ctx);

              try {
                if (course.isInBox) {
                  // ... Lógica de borrado de notas ...
                  final boxEvaluations =
                      Hive.box<Evaluation>(HiveDataService.boxEvaluations);
                  final evaluacionesBorrar = boxEvaluations.values
                      .where((ev) => ev.courseId == course.key)
                      .map((ev) => ev.key)
                      .toList();

                  if (evaluacionesBorrar.isNotEmpty) {
                    await boxEvaluations.deleteAll(evaluacionesBorrar);
                  }

                  await course.delete();
                }
              } catch (e) {
                print("Error: $e");
              } finally {
                // 2. CERRAR USANDO LA REFERENCIA
                navigator.pop();
              }
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

          return Column(
            children: [
              SemesterSummaryCard(
                semestreNombre: widget.semester.name,
                cursos: courses,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: courses.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Card(
                      key: ValueKey(course.key),
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

                        // --- AQUÍ ESTÁ EL MENÚ NUEVO (EDITAR / BORRAR) ---
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showCourseForm(context, courseToEdit: course);
                            } else if (value == 'delete') {
                              _deleteCourse(context, course);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 10),
                                  Text('Editar')
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 10),
                                  Text('Borrar',
                                      style: TextStyle(color: Colors.red))
                                ],
                              ),
                            ),
                          ],
                        ),
                        // -------------------------------------------------

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
        onPressed: () =>
            _showCourseForm(context), // Modo crear (sin argumentos)
        child: const Icon(Icons.add),
      ),
    );
  }
}
