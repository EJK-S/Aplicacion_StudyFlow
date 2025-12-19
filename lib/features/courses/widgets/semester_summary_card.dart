import 'package:flutter/material.dart';
import '../../../data/models/models.dart';

class SemesterSummaryCard extends StatelessWidget {
  final String semestreNombre;
  final List<Course> cursos;

  const SemesterSummaryCard({
    super.key,
    required this.semestreNombre,
    required this.cursos,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 CÁLCULOS MATEMÁTICOS (Basados en la lista interna del curso)
    double sumaPromediosPonderados = 0;
    double totalCreditos = 0;
    int cursosAprobados = 0;

    for (var curso in cursos) {
      // 1. Calculamos el promedio usando la lista INTERNA del curso
      // (Aquí estaba el error antes: buscabas en la caja externa)
      double promedioCurso = _calcularPromedioCurso(curso.evaluations);

      // 2. Sumamos créditos
      // Usamos curso.credits directamente
      double creditos = curso.credits.toDouble();

      // 3. Acumulamos para el promedio global
      sumaPromediosPonderados += (promedioCurso * creditos);
      totalCreditos += creditos;

      // 4. Verificar aprobado
      // Usamos 10.5 como redondeo estándar a favor del alumno
      if (promedioCurso >= 10.5) {
        cursosAprobados++;
      }
    }

    // 5. Promedio Final del Semestre
    double promedioSemestral =
        (totalCreditos > 0) ? sumaPromediosPonderados / totalCreditos : 0.0;

    // --- DISEÑO UI ---
    return Container(
      margin: const EdgeInsets.all(
          16), // Margen externo para que no pegue a los bordes
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.3),
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
              const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
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
                value: "${totalCreditos.toInt()}",
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
  }

  // 👇 Lógica corregida para leer la lista interna
  double _calcularPromedioCurso(List<Evaluation> evaluaciones) {
    if (evaluaciones.isEmpty) return 0.0;

    double sumaNotasPonderadas = 0;
    double sumaPesos = 0;

    for (var eval in evaluaciones) {
      if (eval.scoreObtained != null) {
        // Convertimos peso 30 -> 0.3 si es necesario, o usamos directo si ya es decimal
        double pesoReal = eval.weight;
        // Si el usuario guardó "30" (entero), lo tratamos como 30.
        // La matemática funciona igual: (Nota*30 + Nota*70) / 100 da lo mismo que (Nota*0.3 + Nota*0.7) / 1

        sumaNotasPonderadas += (eval.scoreObtained! * pesoReal);
        sumaPesos += pesoReal;
      }
    }

    if (sumaPesos == 0) return 0.0;
    return sumaNotasPonderadas / sumaPesos;
  }

  Color _getColorPorPromedio(double promedio) {
    if (promedio >= 16) return Colors.greenAccent;
    if (promedio >= 13) return Colors.blueAccent;
    if (promedio >= 10.5) return Colors.orangeAccent;
    return Colors.redAccent;
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
