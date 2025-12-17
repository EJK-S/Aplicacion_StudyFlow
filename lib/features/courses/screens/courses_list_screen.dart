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
  // --- FORMULARIO ACTUALIZADO CON HORARIOS ---
  void _showCourseForm(BuildContext context, {Course? courseToEdit}) {
    final isEditing = courseToEdit != null;

    // Controladores de Texto
    final nameController =
        TextEditingController(text: isEditing ? courseToEdit.name : '');
    final creditsController = TextEditingController(
        text: isEditing ? courseToEdit.credits.toString() : '3');
    final profController = TextEditingController(
        text: isEditing ? courseToEdit.professorName : '');
    final sectionController =
        TextEditingController(text: isEditing ? courseToEdit.section : '');

    // Lista temporal para guardar los horarios antes de dar "Guardar"
    // (Si editamos, copiamos la lista existente. Si es nuevo, lista vacía)
    List<ClassSession> tempSessions =
        isEditing ? List.from(courseToEdit.schedules) : [];

    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;

      final service = HiveDataService();

      // Datos comunes
      final name = nameController.text;
      final credits = int.tryParse(creditsController.text) ?? 0;
      final prof = profController.text;
      final section = sectionController.text;

      if (isEditing) {
        // ACTUALIZAR
        courseToEdit.name = name;
        courseToEdit.credits = credits;
        courseToEdit.professorName = prof;
        courseToEdit.section = section;
        courseToEdit.schedules = tempSessions; // Guardamos la lista nueva
        await courseToEdit.save();
      } else {
        // CREAR NUEVO
        final newCourse = Course()
          ..name = name
          ..credits = credits
          ..professorName = prof
          ..semesterId = widget.semester.key
          ..section = section
          ..schedules = tempSessions; // Guardamos la lista

        await service.saveCourse(newCourse);
      }

      if (context.mounted) Navigator.pop(context);
    }

    // Abrimos el BottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Usamos StatefulBuilder para poder actualizar la lista de horarios visualmente
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 16,
                  right: 16,
                  top: 16),
              child: SingleChildScrollView(
                // Para que no tape el teclado
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(isEditing ? 'Editar Curso ✏️' : 'Nuevo Curso 📚',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    // 1. NOMBRE
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre (Ej: Cálculo II)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book)),
                      textInputAction: TextInputAction.next,
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
                                labelText: 'Créditos',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers)),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: sectionController,
                            decoration: const InputDecoration(
                                labelText: 'Sección (Ej: G1)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group)),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 3. PROFESOR
                    TextField(
                      controller: profController,
                      decoration: const InputDecoration(
                          labelText: 'Profesor (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person)),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),

                    // 4. SECCIÓN DE HORARIOS (DINÁMICA)
                    const Text("Horarios ⏰",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),

                    // Lista visual de horarios agregados
                    if (tempSessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text("Sin horarios definidos",
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...tempSessions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final session = entry.value;
                        final dias = [
                          "",
                          "Lun",
                          "Mar",
                          "Mié",
                          "Jue",
                          "Vie",
                          "Sáb",
                          "Dom"
                        ];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 5),
                          color: Colors.blueGrey.shade900,
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.access_time,
                                color: Colors.amber, size: 20),
                            title: Text(
                                "${dias[session.dayIndex]} ${session.startHour}:00 - ${session.startHour + session.durationHours}:00"),
                            subtitle: Text(
                                "${session.type} • Aula: ${session.classroom}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 18),
                              onPressed: () {
                                setModalState(() {
                                  tempSessions.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      }),

                    // Botón para agregar horario
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Abrimos el diálogo para crear una sesión
                        final newSession = await _showAddSessionDialog(context);
                        if (newSession != null) {
                          setModalState(() {
                            tempSessions.add(newSession);
                          });
                        }
                      },
                      icon: const Icon(Icons.add_alarm),
                      label: const Text("Agregar Horario"),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submitForm,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: Text(
                          isEditing ? 'ACTUALIZAR CURSO' : 'GUARDAR CURSO'),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- SUB-DIALOGO PARA AGREGAR UNA SESIÓN (Día, Hora, Aula) ---
  Future<ClassSession?> _showAddSessionDialog(BuildContext context) async {
    // Valores iniciales
    int selectedDay = 1; // Lunes
    int startHour = 8; // 8 AM
    int duration = 2; // 2 horas
    String type = "Teoría";
    final roomController = TextEditingController(text: "S/N");

    final dias = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    final tipos = ["Teoría", "Práctica", "Laboratorio", "Seminario"];

    return showDialog<ClassSession>(
        context: context,
        builder: (ctx) {
          // Usamos StatefulBuilder aquí también para los dropdowns internos
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Agregar Sesión"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. DÍA
                    DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(labelText: "Día"),
                      items: List.generate(
                          7,
                          (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(dias[index]),
                              )),
                      onChanged: (v) => setState(() => selectedDay = v!),
                    ),
                    const SizedBox(height: 10),

                    // 2. HORA Y DURACIÓN
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: startHour,
                            decoration:
                                const InputDecoration(labelText: "Inicio"),
                            items: List.generate(
                                16,
                                (index) => DropdownMenuItem(
                                      // De 7 a 22
                                      value: index + 7,
                                      child: Text("${index + 7}:00"),
                                    )),
                            onChanged: (v) => setState(() => startHour = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: duration,
                            decoration: const InputDecoration(
                                labelText: "Duración (h)"),
                            items: [1, 2, 3, 4, 5]
                                .map((h) => DropdownMenuItem(
                                    value: h, child: Text("$h h")))
                                .toList(),
                            onChanged: (v) => setState(() => duration = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 3. TIPO Y AULA
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration:
                                const InputDecoration(labelText: "Tipo"),
                            items: tipos
                                .map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) => setState(() => type = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: roomController,
                            decoration:
                                const InputDecoration(labelText: "Aula"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar")),
                  ElevatedButton(
                    onPressed: () {
                      // Retornamos el objeto ClassSession nuevo
                      final session = ClassSession(
                        dayIndex: selectedDay,
                        startHour: startHour,
                        durationHours: duration,
                        classroom: roomController.text,
                        type: type,
                      );
                      Navigator.pop(context, session);
                    },
                    child: const Text("Agregar"),
                  )
                ],
              );
            },
          );
        });
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
                if (kDebugMode) {
                  print("Error: $e");
                }
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
