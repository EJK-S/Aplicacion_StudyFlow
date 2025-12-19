// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_studyflow/features/courses/screens/courses_list_screen.dart';
import '../../data/local/hive_data_service.dart';
import '../../data/models/models.dart';

class SemestersListScreen extends StatefulWidget {
  const SemestersListScreen({super.key});

  @override
  State<SemestersListScreen> createState() => _SemestersListScreenState();
}

class _SemestersListScreenState extends State<SemestersListScreen> {
  // --- EDICIÓN CON ENTER ---
  void _editSemester(BuildContext context, Semester semester) {
    final nameController = TextEditingController(text: semester.name);

    void save() {
      if (nameController.text.trim().isEmpty) return;
      semester.name = nameController.text.trim();
      semester.save();
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar nombre del ciclo"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Nombre (Ej: 2026-II)"),
          autofocus: true,
          textInputAction: TextInputAction.done, // Teclado muestra "Listo"
          onSubmitted: (_) => save(), // 👈 ¡ENTER PARA GUARDAR!
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: save,
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  // --- BORRADO ---
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
              final navigator = Navigator.of(ctx);
              try {
                if (semester.isInBox) {
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

                  await semester.delete();
                }
              } catch (e) {
                if (kDebugMode) print("Error al borrar: $e");
              } finally {
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
        // Ordenamos: El más reciente arriba para tenerlo a mano
        final semesters = box.values.toList();
        semesters.sort((a, b) => b.startDate.compareTo(a.startDate));

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

        return ListView.builder(
          itemCount: semesters.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, index) {
            final semester = semesters[index];
            final isCurrent = semester.isCurrent;

            return Card(
              key: ValueKey(semester.key),
              // Borde verde neón si es el actual
              shape: isCurrent
                  ? RoundedRectangleBorder(
                      side:
                          const BorderSide(color: Colors.greenAccent, width: 2),
                      borderRadius: BorderRadius.circular(12))
                  : null,
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: isCurrent
                          ? Colors.green.withOpacity(0.2)
                          : Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(
                    isCurrent ? Icons.check_circle : Icons.calendar_month,
                    color: isCurrent ? Colors.greenAccent : Colors.blueAccent,
                  ),
                ),
                title: Text(semester.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCurrent ? Colors.greenAccent : Colors.white)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Inicio: ${semester.startDate.toString().split(' ')[0]}",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    if (isCurrent)
                      const Text("● SEMESTRE ACTUAL",
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold))
                  ],
                ),

                // 👇 MENÚ CON LÓGICA CORREGIDA
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) async {
                    if (value == 'active') {
                      // 1. LÓGICA OPTIMIZADA: "Cirugía Láser"
                      // Buscamos solo al que tiene el check verde actualmente (si existe)
                      // y lo apagamos.
                      try {
                        final previousActive = box.values
                            .cast<Semester?>()
                            .firstWhere(
                                (s) =>
                                    s?.isCurrent == true &&
                                    s?.key != semester.key,
                                orElse: () => null);

                        if (previousActive != null) {
                          previousActive.isCurrent = false;
                          await previousActive.save();
                        }

                        // 2. Encendemos el nuevo
                        semester.isCurrent = true;
                        await semester.save();

                        // Feedback visual rápido
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("✅ Ahora viendo: ${semester.name}"),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ));
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          print("Error cambiando semestre: $e");
                        }
                      }
                    } else if (value == 'edit') {
                      _editSemester(context, semester);
                    } else if (value == 'delete') {
                      _deleteSemester(context, semester);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isCurrent)
                      const PopupMenuItem(
                        value: 'active',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            SizedBox(width: 10),
                            Text("Seleccionar como Actual"),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 20),
                            SizedBox(width: 10),
                            Text("Renombrar"),
                          ],
                        )),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Text("Eliminar",
                                style: TextStyle(color: Colors.red)),
                          ],
                        )),
                  ],
                ),

                onTap: () {
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
