import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<StudySession>(HiveDataService.boxStudySessions).listenable(),
      builder: (context, Box<StudySession> box, _) {
        if (box.isEmpty) {
          return const SizedBox.shrink(); // No mostrar si no hay datos
        }

        // 1. ANÁLISIS DE DATOS (El "Motor")
        final sessions = box.values.toList();
        final now = DateTime.now();

        // Filtrar sesiones de ESTA semana
        final thisWeekSessions = sessions.where((s) {
          final difference = now.difference(s.date).inDays;
          return difference < 7;
        }).toList();

        if (thisWeekSessions.isEmpty) {
          return _buildCard("😴", "Esta semana está tranquila",
              "Aún no has registrado actividad reciente.");
        }

        // Calcular totales
        int totalMinutes = 0;
        final Map<int, int> courseMinutes = {};

        for (var s in thisWeekSessions) {
          totalMinutes += s.durationMinutes;
          courseMinutes.update(s.courseId, (val) => val + s.durationMinutes,
              ifAbsent: () => s.durationMinutes);
        }

        // Encontrar el curso favorito (Top Focus)
        int topCourseId = -1;
        int maxMin = -1;
        courseMinutes.forEach((id, min) {
          if (min > maxMin) {
            maxMin = min;
            topCourseId = id;
          }
        });

        // Obtener nombre del curso
        String courseName = "Varios";
        if (topCourseId != -1) {
          final course =
              Hive.box<Course>(HiveDataService.boxCourses).get(topCourseId);
          courseName = course?.name ?? "Desconocido";
        }

        // 2. GENERAR INSIGHT (La "IA" lógica)
        String icon = "💡";
        String title = "Resumen Semanal";
        String message = "";

        if (totalMinutes < 60) {
          icon = "🐢";
          title = "Arranque lento";
          message =
              "Solo llevas $totalMinutes min esta semana. ¡Vamos por una hora!";
        } else if (courseMinutes.length == 1) {
          icon = "🎯";
          title = "Monotema";
          message =
              "Estás 100% enfocado en $courseName. ¿No olvidas otras materias?";
        } else {
          icon = "🔥";
          title = "A buen ritmo";
          message =
              "Tu prioridad es $courseName (${(maxMin / totalMinutes * 100).toStringAsFixed(0)}% del tiempo).";
        }

        return _buildCard(icon, title, message);
      },
    );
  }

  Widget _buildCard(String icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.blueGrey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
          border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(body,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
