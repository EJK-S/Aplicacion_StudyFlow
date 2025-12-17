import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_studyflow/features/courses/screens/courses_list_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/local/hive_data_service.dart';
import '../../data/models/models.dart';

class SemestersListScreen extends StatefulWidget {
  const SemestersListScreen({super.key});

  @override
  State<SemestersListScreen> createState() => _SemestersListScreenState();
}

class _SemestersListScreenState extends State<SemestersListScreen> {
  // Función para editar (similar a la de cursos, pero más simple)
  void _editSemester(BuildContext context, Semester semester) {
    final nameController = TextEditingController(text: semester.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar nombre del ciclo"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nombre (Ej: 2026-II)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              semester.name = nameController.text;
              semester.save(); // Guardar cambios
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  // --- FUNCIÓN DE BORRADO EN CASCADA (SEMESTRE -> CURSOS -> NOTAS) ---
  void _deleteSemester(BuildContext context, Semester semester) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Borrar ciclo completo?"),
        content: Text(
            "Se eliminará '${semester.name}' y TODOS los cursos y notas que contiene.\n\nEsta acción es irreversible."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              // 1. CAPTURAMOS EL NAVIGATOR ANTES DE HACER NADA
              final navigator = Navigator.of(ctx);

              try {
                if (semester.isInBox) {
                  // --- LÓGICA DE BORRADO (Cursos y Notas) ---
                  final boxCourses =
                      Hive.box<Course>(HiveDataService.boxCourses);
                  final boxEvaluations =
                      Hive.box<Evaluation>(HiveDataService.boxEvaluations);

                  final cursosDelSemestre = boxCourses.values
                      .where((c) => c.semesterId == semester.key)
                      .toList();

                  for (var curso in cursosDelSemestre) {
                    final notasDelCurso = boxEvaluations.values
                        .where((ev) => ev.courseId == curso.key)
                        .map((ev) => ev.key)
                        .toList();
                    if (notasDelCurso.isNotEmpty) {
                      await boxEvaluations.deleteAll(notasDelCurso);
                    }
                  }

                  final keysCursos =
                      cursosDelSemestre.map((c) => c.key).toList();
                  if (keysCursos.isNotEmpty) {
                    await boxCourses.deleteAll(keysCursos);
                  }

                  // Borrar el semestre
                  await semester.delete();
                }
              } catch (e) {
                if (kDebugMode) {
                  print("Error al borrar: $e");
                }
              } finally {
                // 2. USAMOS LA REFERENCIA GUARDADA PARA CERRAR EL DIÁLOGO SIEMPRE
                navigator.pop();
              }
            },
            child:
                const Text("Borrar Todo", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Semester>(HiveDataService.boxSemesters).listenable(),
      builder: (context, Box<Semester> box, _) {
        final semesters = box.values.toList();

        if (semesters.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                    "No tienes semestres registrados.\n¡Empieza agregando uno!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Ordenamos: El más nuevo arriba (opcional)
        // semesters.sort((a, b) => b.startDate.compareTo(a.startDate));

        return ListView.builder(
          itemCount: semesters.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            final semester = semesters[index];
            return Card(
              key: ValueKey(semester.key),
              color: const Color(0xFF1E1E1E), // Color oscuro tarjeta
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.calendar_month,
                      color: Colors.blueAccent),
                ),
                title: Text(semester.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                    "Inicio: ${semester.startDate.toString().split(' ')[0]}",
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),

                // --- BOTÓN DE ACCIÓN ACTUAL (Ir al Dashboard) ---
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón "Hacer Actual" (opcional si quieres cambiar manualmente)
                    if (!semester.isCurrent)
                      IconButton(
                        icon: const Text("Actual",
                            style:
                                TextStyle(fontSize: 10, color: Colors.green)),
                        onPressed: () {
                          // Desmarcar otros y marcar este
                          for (var s in box.values) {
                            s.isCurrent = false;
                            s.save();
                          }
                          semester.isCurrent = true;
                          semester.save();
                        },
                      ),

                    // MENÚ DE EDICIÓN
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') _editSemester(context, semester);
                        if (value == 'delete') {
                          _deleteSemester(context, semester);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text("Renombrar")),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text("Eliminar",
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),

                onTap: () {
                  // Navegar a los cursos de ese semestre
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CoursesListScreen(semester: semester),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
