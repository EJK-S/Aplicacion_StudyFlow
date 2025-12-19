import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';
import 'course_grades_screen.dart';

class CoursesListScreen extends StatefulWidget {
  final Semester semester;

  const CoursesListScreen({super.key, required this.semester});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  // --- DIÁLOGO PARA CREAR/EDITAR CURSO ---
  void _showCourseDialog(BuildContext context, [Course? courseToEdit]) {
    final nameController = TextEditingController(text: courseToEdit?.name);
    final creditsController =
        TextEditingController(text: courseToEdit?.credits.toString());
    final sectionController =
        TextEditingController(text: courseToEdit?.section);
    final professorController =
        TextEditingController(text: courseToEdit?.professorName);

    // Gestión de Horarios (Lista temporal)
    List<ClassSession> tempSchedules = courseToEdit?.schedules.toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // --- LÓGICA DE GUARDADO (Centralizada) ---
            Future<void> submitForm() async {
              if (nameController.text.isEmpty ||
                  creditsController.text.isEmpty) {
                // Validación visual rápida (puedes agregar un SnackBar si quieres)
                return;
              }

              // Cerrar teclado para evitar bugs
              FocusScope.of(context).unfocus();

              final name = nameController.text;
              final credits = int.tryParse(creditsController.text) ?? 0;
              final section = sectionController.text;
              final professor = professorController.text;

              if (courseToEdit == null) {
                // CREAR NUEVO
                final newCourse = Course()
                  ..name = name
                  ..credits = credits
                  ..semesterId = widget.semester.key as int
                  ..section = section
                  ..professorName = professor
                  ..schedules = tempSchedules; // Guardamos horarios

                final box = Hive.box<Course>(HiveDataService.boxCourses);
                await box.add(newCourse);
              } else {
                // EDITAR EXISTENTE
                courseToEdit.name = name;
                courseToEdit.credits = credits;
                courseToEdit.section = section;
                courseToEdit.professorName = professor;
                courseToEdit.schedules = tempSchedules; // Actualizamos horarios
                await courseToEdit.save();
              }

              if (context.mounted) Navigator.pop(context);
            }

            // --- DIÁLOGO PARA AGREGAR HORARIO ---
            void showAddScheduleDialog() {
              int selectedDay = 1; // Lunes
              int startHour = 8;
              int duration = 2;
              String type = "Teoría";
              String classroom = "";

              showDialog(
                context: context,
                builder: (ctx) =>
                    StatefulBuilder(builder: (ctx, setScheduleState) {
                  return AlertDialog(
                    title: const Text("Agregar Horario ⏰"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<int>(
                            value: selectedDay,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 1, child: Text("Lunes")),
                              DropdownMenuItem(value: 2, child: Text("Martes")),
                              DropdownMenuItem(
                                  value: 3, child: Text("Miércoles")),
                              DropdownMenuItem(value: 4, child: Text("Jueves")),
                              DropdownMenuItem(
                                  value: 5, child: Text("Viernes")),
                              DropdownMenuItem(value: 6, child: Text("Sábado")),
                              DropdownMenuItem(
                                  value: 7, child: Text("Domingo")),
                            ],
                            onChanged: (v) =>
                                setScheduleState(() => selectedDay = v!),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Hora Inicio (0-23)"),
                                  onChanged: (v) =>
                                      startHour = int.tryParse(v) ?? 8,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: "Duración (hrs)"),
                                  onChanged: (v) =>
                                      duration = int.tryParse(v) ?? 2,
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            decoration: const InputDecoration(
                                labelText: "Aula (Ej: 201)"),
                            onChanged: (v) => classroom = v,
                          ),
                          DropdownButton<String>(
                            value: type,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: "Teoría", child: Text("Teoría")),
                              DropdownMenuItem(
                                  value: "Práctica", child: Text("Práctica")),
                              DropdownMenuItem(
                                  value: "Laboratorio",
                                  child: Text("Laboratorio")),
                              DropdownMenuItem(
                                  value: "Seminario", child: Text("Seminario")),
                              DropdownMenuItem(
                                  value: "Recuperación",
                                  child: Text("Recuperación")),
                            ],
                            onChanged: (v) => setScheduleState(() => type = v!),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancelar")),
                      ElevatedButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempSchedules.add(ClassSession(
                                dayIndex: selectedDay,
                                startHour: startHour,
                                durationHours: duration,
                                classroom: classroom,
                                type: type));
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text("Agregar"),
                      )
                    ],
                  );
                }),
              );
            }

            return AlertDialog(
              title: Text(
                  courseToEdit == null ? "Nuevo Curso 📚" : "Editar Curso ✏️"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. NOMBRE
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: "Nombre (Ej: Cálculo II)",
                            prefixIcon: Icon(Icons.book),
                            border: OutlineInputBorder()),
                        textInputAction:
                            TextInputAction.next, // Enter -> Siguiente
                      ),
                      const SizedBox(height: 10),

                      // 2. CRÉDITOS Y SECCIÓN
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: "Créditos",
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder()),
                              textInputAction:
                                  TextInputAction.next, // Enter -> Siguiente
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: sectionController,
                              decoration: const InputDecoration(
                                  labelText: "Sección (Ej: G1)",
                                  prefixIcon: Icon(Icons.people),
                                  border: OutlineInputBorder()),
                              textInputAction:
                                  TextInputAction.next, // Enter -> Siguiente
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 3. PROFESOR (El último campo de texto)
                      TextField(
                        controller: professorController,
                        decoration: const InputDecoration(
                            labelText: "Profesor (Opcional)",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder()),
                        // 👇 AQUÍ ESTÁ LA MAGIA: ENTER = GUARDAR
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submitForm(),
                      ),

                      const SizedBox(height: 20),

                      // 4. LISTA DE HORARIOS (Visual)
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Horarios ⏰",
                              style: Theme.of(context).textTheme.titleSmall)),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10)),
                        child: Column(
                          children: [
                            if (tempSchedules.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Text("Sin horarios definidos",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ),
                            ...tempSchedules.map((s) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.access_time,
                                      color: Colors.orangeAccent, size: 20),
                                  title: Text(_getDayName(s.dayIndex)),
                                  subtitle: Text(
                                      "${s.startHour}:00 - ${s.startHour + s.durationHours}:00 • ${s.type}"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red, size: 18),
                                    onPressed: () {
                                      setStateDialog(() {
                                        tempSchedules.remove(s);
                                      });
                                    },
                                  ),
                                )),
                            const Divider(),
                            TextButton.icon(
                                onPressed: showAddScheduleDialog,
                                icon: const Icon(Icons.add_alarm),
                                label: const Text("Agregar Horario"))
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                if (courseToEdit != null)
                  TextButton(
                    onPressed: () async {
                      // Confirmar borrado
                      final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                title: const Text("¿Borrar curso?"),
                                content: const Text(
                                    "Se borrarán también todas las notas asociadas."),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text("Cancelar")),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Borrar",
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ));

                      if (confirm == true) {
                        // Borrar notas asociadas primero
                        final boxEvals = Hive.box<Evaluation>(
                            HiveDataService.boxEvaluations);
                        final evalsToDelete = boxEvals.values
                            .where((e) => e.courseId == courseToEdit.key)
                            .map((e) => e.key)
                            .toList();
                        await boxEvals.deleteAll(evalsToDelete);

                        // Borrar curso
                        await courseToEdit.delete();
                        if (context.mounted) {
                          Navigator.pop(context); // Cerrar diálogo
                        }
                      }
                    },
                    child: const Text("Eliminar",
                        style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: submitForm, // Usa la misma función que el ENTER
                  child: Text(courseToEdit == null
                      ? "GUARDAR CURSO"
                      : "ACTUALIZAR CURSO"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper para nombres de días
  String _getDayName(int index) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    if (index >= 1 && index <= 7) return days[index - 1];
    return "Día $index";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.semester.name)),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<Course>(HiveDataService.boxCourses).listenable(),
        builder: (context, Box<Course> box, _) {
          // Filtrar cursos de este semestre
          final courses = box.values
              .where((c) => c.semesterId == widget.semester.key)
              .toList();

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("No hay cursos en ${widget.semester.name}",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      onPressed: () => _showCourseDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Crear Primer Curso"))
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                color: const Color(0xFF252525),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigoAccent,
                    child: Text(
                        course.name.isNotEmpty
                            ? course.name[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(course.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                      "Prof: ${course.professorName ?? 'No sé'} • ${course.credits} créditos"),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showCourseDialog(context, course),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                CourseGradesScreen(course: course)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
