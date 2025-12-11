import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';

class SemesterSummaryCard extends StatelessWidget {
  final String semestreNombre;
  final List<Course> cursos; // Cambiado a List<Course> para ser más estricto

  const SemesterSummaryCard({
    super.key,
    required this.semestreNombre,
    required this.cursos,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Necesitamos acceso a la caja de evaluaciones para calcular las notas
    // Usamos ValueListenableBuilder para que si agregas una nota, el promedio se actualice solo.
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Evaluation>(HiveDataService.boxEvaluations).listenable(),
      builder: (context, Box<Evaluation> boxEvaluations, _) {
        // --- ZONA DE CÁLCULOS MATEMÁTICOS ---
        double sumaPromediosPonderados = 0;
        int totalCreditos = 0;
        int cursosAprobados = 0;

        for (var curso in cursos) {
          // A. Buscamos las evaluaciones de ESTE curso específico
          final evaluacionesDelCurso = boxEvaluations.values
              .where((ev) =>
                  ev.courseId ==
                  curso.key) // curso.key es el ID automático de Hive
              .toList();

          // B. Calculamos el promedio de ESTE curso
          double promedioCurso = _calcularPromedioCurso(evaluacionesDelCurso);

          // C. Sumamos para el promedio global del semestre
          int creditos = curso.credits > 0 ? curso.credits : 1; // Evitar ceros
          sumaPromediosPonderados += (promedioCurso * creditos);
          totalCreditos += creditos;

          if (promedioCurso >= 10.5) {
            cursosAprobados++;
          }
        }

        // D. Promedio Final del Semestre
        double promedioSemestral =
            totalCreditos > 0 ? sumaPromediosPonderados / totalCreditos : 0.0;

        // --- ZONA DE DISEÑO (UI) ---
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF141E30),
                Color(0xFF243B55)
              ], // Un gradiente azul oscuro elegante
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Resumen $semestreNombre",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Icon(Icons.analytics_outlined,
                      color: Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    promedioSemestral.toStringAsFixed(2),
                    style: TextStyle(
                      color: _getColorPorPromedio(promedioSemestral),
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Promedio Ponderado",
                      style: TextStyle(
                          color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    label: "Créditos",
                    value: "$totalCreditos",
                    icon: Icons.class_outlined,
                  ),
                  _InfoChip(
                    label: "Cursos",
                    value: "${cursos.length}",
                    icon: Icons.book_outlined,
                  ),
                  _InfoChip(
                    label: "Aprobados",
                    value: "$cursosAprobados",
                    icon: Icons.check_circle_outline,
                    color: Colors.greenAccent,
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // Función auxiliar para calcular promedio individual (Lógica pura)
  double _calcularPromedioCurso(List<Evaluation> evaluaciones) {
    if (evaluaciones.isEmpty) return 0.0;

    double sumaNotasPonderadas = 0;
    double sumaPesos = 0;

    for (var eval in evaluaciones) {
      // scoreObtained puede ser null si no ha dado el examen, asumimos 0 por seguridad
      double nota = eval.scoreObtained ?? 0.0;
      double peso =
          eval.weight; // El peso ya viene como double (ej: 0.30) o entero (30)

      // Pequeña corrección si guardaste pesos como 30 en vez de 0.3
      // Si la suma de pesos da > 1.0, asumimos que usaste escala de 100

      sumaNotasPonderadas += (nota * peso);
      sumaPesos += peso;
    }

    if (sumaPesos == 0) return 0.0;

    // Si tus pesos son (30, 30, 40) -> sumaPesos = 100. División OK.
    // Si tus pesos son (0.3, 0.3, 0.4) -> sumaPesos = 1. División OK.
    return sumaNotasPonderadas / sumaPesos;
  }

  Color _getColorPorPromedio(double promedio) {
    if (promedio >= 16) return Colors.greenAccent; // Excelente
    if (promedio >= 13) return Colors.blueAccent; // Bien
    if (promedio >= 10.5) return Colors.orangeAccent; // Raspando
    return Colors.redAccent; // Jalado
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }
}
