import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';

class CycleComparisonScreen extends StatefulWidget {
  const CycleComparisonScreen({super.key});

  @override
  State<CycleComparisonScreen> createState() => _CycleComparisonScreenState();
}

class _CycleComparisonScreenState extends State<CycleComparisonScreen> {
  int? semesterId1;
  int? semesterId2;

  // --- 🧠 EL CEREBRO MATEMÁTICO ---
  Map<String, double> _calculateMetrics(int semesterId) {
    // 1. Obtener Cursos del Semestre
    final allCourses = Hive.box<Course>(HiveDataService.boxCourses).values;
    final semesterCourses =
        allCourses.where((c) => c.semesterId == semesterId).toList();

    if (semesterCourses.isEmpty) {
      return {'average': 0.0, 'credits': 0.0, 'studyHours': 0.0};
    }

    // 2. Calcular Promedio y Créditos
    double totalScore = 0;
    double totalWeight = 0;
    double totalCredits = 0;

    for (var course in semesterCourses) {
      // Sumamos créditos
      totalCredits += course.credits;

      // Calculamos promedio del curso
      double courseScore = 0;
      double courseWeight = 0;
      for (var eval in course.evaluations) {
        if (eval.scoreObtained != null) {
          courseScore += eval.scoreObtained! * (eval.weight / 100);
          courseWeight += (eval.weight / 100);
        }
      }
      double finalCourseGrade =
          (courseWeight == 0) ? 0 : (courseScore / courseWeight);

      // Ponderado Global: NotaCurso * CreditosCurso
      totalScore += finalCourseGrade * course.credits;
      totalWeight += course.credits;
    }

    double globalAverage = (totalWeight == 0) ? 0 : (totalScore / totalWeight);

    // 3. Calcular Horas de Estudio (Cruzando con Pomodoro)
    // Buscamos sesiones donde el courseId coincida con alguno de este semestre
    final allSessions =
        Hive.box<StudySession>(HiveDataService.boxStudySessions).values;
    final courseIds = semesterCourses.map((c) => c.key).toSet();

    int totalMinutes = 0;
    for (var session in allSessions) {
      if (courseIds.contains(session.courseId)) {
        totalMinutes += session.durationMinutes;
      }
    }

    return {
      'average': globalAverage,
      'credits': totalCredits,
      'studyHours': totalMinutes / 60, // Convertimos a horas
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comparador de Ciclos ⚖️")),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<Semester>(HiveDataService.boxSemesters).listenable(),
        builder: (context, Box<Semester> box, _) {
          final semesters = box.values.toList();

          if (semesters.length < 2) {
            return const Center(
                child: Text("Necesitas al menos 2 ciclos para comparar."));
          }

          // Métricas
          final metrics1 =
              semesterId1 != null ? _calculateMetrics(semesterId1!) : null;
          final metrics2 =
              semesterId2 != null ? _calculateMetrics(semesterId2!) : null;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. SELECTORES
                Row(
                  children: [
                    Expanded(
                        child: _buildDropdown(semesters, semesterId1,
                            (v) => setState(() => semesterId1 = v))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("VS",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.amber)),
                    ),
                    Expanded(
                        child: _buildDropdown(semesters, semesterId2,
                            (v) => setState(() => semesterId2 = v))),
                  ],
                ),

                const SizedBox(height: 30),

                // 2. TARJETAS DE COMPARACIÓN
                if (metrics1 != null && metrics2 != null) ...[
                  _buildStatRow("Promedio Ponderado 🎓", metrics1['average']!,
                      metrics2['average']!,
                      isHigherBetter: true),
                  const SizedBox(height: 15),
                  _buildStatRow("Horas de Estudio ⏳", metrics1['studyHours']!,
                      metrics2['studyHours']!,
                      isHigherBetter: true),
                  const SizedBox(height: 15),
                  _buildStatRow("Créditos Totales 📚", metrics1['credits']!,
                      metrics2['credits']!,
                      isHigherBetter: true),

                  const Spacer(),
                  // 3. VEREDICTO
                  _buildVerdict(metrics1, metrics2),
                ] else
                  const Expanded(
                      child: Center(
                          child: Text(
                              "Selecciona dos ciclos para comenzar el análisis.",
                              style: TextStyle(color: Colors.grey)))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(
      List<Semester> semesters, int? selectedId, Function(int?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.blueGrey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          hint: const Text("Seleccionar"),
          isExpanded: true,
          items: semesters
              .map((s) => DropdownMenuItem(
                    value: s.key as int,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, double val1, double val2,
      {required bool isHigherBetter}) {
    // Calculamos diferencia
    double diff = val2 - val1;
    bool isBetter = isHigherBetter ? diff >= 0 : diff <= 0;
    Color color = isBetter ? Colors.green : Colors.red;
    String icon = isBetter ? "📈" : "📉";

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val1.toStringAsFixed(2),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                // ignore: deprecated_member_use
                decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Text(
                        diff > 0
                            ? "+${diff.toStringAsFixed(2)}"
                            : diff.toStringAsFixed(2),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    Text(icon, style: const TextStyle(fontSize: 12))
                  ],
                ),
              ),
              Text(val2.toStringAsFixed(2),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVerdict(Map<String, double> m1, Map<String, double> m2) {
    // Lógica simple de veredicto
    bool improved = m2['average']! > m1['average']!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: improved
                  ? [Colors.green.shade900, Colors.black]
                  : [Colors.red.shade900, Colors.black]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: improved ? Colors.green : Colors.red)),
      child: Row(
        children: [
          Text(improved ? "🏆" : "💪", style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(improved ? "¡MEJORA DETECTADA!" : "MANTÉN EL ESFUERZO",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                Text(
                    improved
                        ? "Has superado tu promedio anterior. ¡Sigue así!"
                        : "El rendimiento ha bajado un poco. Revisa tus horas de estudio.",
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
