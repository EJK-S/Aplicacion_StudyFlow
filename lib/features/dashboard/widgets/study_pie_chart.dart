import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';

class StudyPieChart extends StatefulWidget {
  const StudyPieChart({super.key});

  @override
  State<StudyPieChart> createState() => _StudyPieChartState();
}

class _StudyPieChartState extends State<StudyPieChart> {
  int touchedIndex = -1; // Para la animación al tocar

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<StudySession>(HiveDataService.boxStudySessions).listenable(),
      builder: (context, Box<StudySession> boxSessions, _) {
        // 1. OBTENER DATOS Y FILTRAR POR SEMESTRE ACTUAL
        // (Para simplificar, por ahora tomamos todo el historial, luego podemos filtrar por fechas)
        final sessions = boxSessions.values.toList();

        if (sessions.isEmpty) {
          return _buildEmptyState();
        }

        // 2. AGRUPAR MINUTOS POR CURSO
        // Map<CourseId, Minutos>
        final Map<int, int> timePerCourse = {};
        int totalMinutes = 0;

        for (var session in sessions) {
          timePerCourse.update(
              session.courseId, (value) => value + session.durationMinutes,
              ifAbsent: () => session.durationMinutes);
          totalMinutes += session.durationMinutes;
        }

        // 3. PREPARAR DATOS PARA EL GRÁFICO
        final boxCourses = Hive.box<Course>(HiveDataService.boxCourses);
        final List<PieChartSectionData> sections = [];

        int index = 0;
        timePerCourse.forEach((courseId, minutes) {
          final isTouched = index == touchedIndex;
          final double fontSize = isTouched ? 20.0 : 14.0;
          final double radius = isTouched ? 60.0 : 50.0;

          String courseName = "General";
          Color color = Colors.grey;

          if (courseId != -1) {
            final course = boxCourses.get(courseId);
            if (course != null) {
              courseName = course.name;
              // Generamos un color consistente basado en el ID del curso
              color = Colors.primaries[courseId % Colors.primaries.length];
            }
          } else {
            color = Colors.blueGrey;
          }

          final percent = (minutes / totalMinutes) * 100;

          sections.add(PieChartSectionData(
            color: color,
            value: minutes.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            badgeWidget: isTouched ? _buildBadge(courseName, minutes) : null,
            badgePositionPercentageOffset: .98,
          ));
          index++;
        });

        return Column(
          children: [
            const Text("Distribución de Estudio ⏳",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
                totalMinutes < 60
                    ? "Total acumulado: $totalMinutes min"
                    : "Total acumulado: ${(totalMinutes / 60).toStringAsFixed(1)} horas",
                style: const TextStyle(color: Colors.grey))
          ],
        );
      },
    );
  }

  Widget _buildBadge(String text, int minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white24)),
      child: Text(
        "$text\n$minutes min",
        style: const TextStyle(color: Colors.white, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15)),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text("Sin datos de estudio aún",
              style: TextStyle(color: Colors.grey)),
          Text("Usa el Pomodoro para generar estadísticas",
              style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
