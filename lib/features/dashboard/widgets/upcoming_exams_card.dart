import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml, si no, usa una función simple
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';

class UpcomingExamsCard extends StatelessWidget {
  const UpcomingExamsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Course>(HiveDataService.boxCourses).listenable(),
      builder: (context, Box<Course> box, _) {
        // 1. OBTENER SEMESTRE ACTUAL
        final semesterBox = Hive.box<Semester>(HiveDataService.boxSemesters);
        Semester? activeSemester;
        try {
          activeSemester = semesterBox.values.firstWhere((s) => s.isCurrent);
        } catch (_) {
          return const SizedBox.shrink();
        }

        // 2. RECOLECTAR TODAS LAS EVALUACIONES PENDIENTES
        final courses = box.values
            .where((c) => c.semesterId == activeSemester!.key)
            .toList();
        final List<Map<String, dynamic>> upcomingEvaluations = [];
        final now = DateTime.now();
        // Normalizamos "hoy" para comparar solo fechas sin horas
        final today = DateTime(now.year, now.month, now.day);

        for (var course in courses) {
          for (var eval in course.evaluations) {
            // Si tiene fecha y es hoy o futuro
            if (eval.date != null) {
              final evalDate =
                  DateTime(eval.date!.year, eval.date!.month, eval.date!.day);
              if (evalDate.isAtSameMomentAs(today) || evalDate.isAfter(today)) {
                upcomingEvaluations.add({
                  'course': course.name,
                  'evalName': eval.name,
                  'date': eval.date,
                  'daysLeft': evalDate.difference(today).inDays,
                });
              }
            }
          }
        }

        // 3. ORDENAR POR FECHA (Lo más cercano primero)
        upcomingEvaluations.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        // Tomamos solo las próximas 3 para no saturar
        final nextExams = upcomingEvaluations.take(3).toList();

        if (nextExams.isEmpty) {
          return _buildEmptyState();
        }

        // 4. DETECTAR "MODO SEMANA CRÍTICA" 🚨
        // Si el examen más cercano es en menos de 7 días
        bool isCriticalWeek = (nextExams.first['daysLeft'] as int) <= 7;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // Si es crítico, fondo rojo oscuro, si no, azul oscuro
            // ignore: deprecated_member_use
            color: isCriticalWeek
                // ignore: deprecated_member_use
                ? Colors.red.shade900.withOpacity(0.2)
                // ignore: deprecated_member_use
                : Colors.blueGrey.shade900.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isCriticalWeek
                    ? Colors.redAccent
                    : Colors.blueGrey.shade700,
                width: isCriticalWeek ? 2 : 1),
          ),
          child: Column(
            children: [
              // Encabezado
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                        isCriticalWeek
                            ? Icons.warning_amber_rounded
                            : Icons.calendar_today,
                        color: isCriticalWeek
                            ? Colors.redAccent
                            : Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      isCriticalWeek
                          ? "SEMANA CRÍTICA 🔥"
                          : "Próximas Evaluaciones",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isCriticalWeek ? Colors.redAccent : Colors.white),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Lista de Exámenes
              ...nextExams.map((exam) {
                final days = exam['daysLeft'] as int;
                String timeText = days == 0
                    ? "¡HOY!"
                    : (days == 1 ? "Mañana" : "En $days días");

                return ListTile(
                  dense: true,
                  title: Text(exam['course'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${DateFormat('dd/MM').format(exam['date'])} • ${exam['evalName']}"),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: days <= 3 ? Colors.redAccent : Colors.green,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(timeText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                );
              }),
              if (upcomingEvaluations.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("+${upcomingEvaluations.length - 3} más...",
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          // ignore: deprecated_member_use
          border: Border.all(color: Colors.green.withOpacity(0.3))),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.beach_access, color: Colors.green),
          SizedBox(width: 10),
          Text("¡Todo despejado! No hay exámenes próximos.",
              style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}
