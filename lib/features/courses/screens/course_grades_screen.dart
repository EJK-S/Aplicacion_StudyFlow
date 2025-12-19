import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/hive_data_service.dart';
import '../../../data/models/models.dart';

class CourseGradesScreen extends StatefulWidget {
  final Course course;

  const CourseGradesScreen({super.key, required this.course});

  @override
  State<CourseGradesScreen> createState() => _CourseGradesScreenState();
}

class _CourseGradesScreenState extends State<CourseGradesScreen> {
  // --- 1. LÓGICA DE CÁLCULO ---
  double _calculateAverage(List<Evaluation> evaluations) {
    double totalScore = 0;
    double totalWeight = 0;

    for (var eval in evaluations) {
      if (eval.scoreObtained != null) {
        // Soporte para pesos enteros (30) o decimales (0.3)
        double peso = eval.weight > 1 ? eval.weight / 100 : eval.weight;
        totalScore += eval.scoreObtained! * peso;
        totalWeight += peso;
      }
    }

    if (totalWeight == 0) return 0.0;
    return totalScore / totalWeight;
  }

  String _getPrediction(List<Evaluation> evaluations) {
    double totalAccumulatedPoints = 0;
    double totalGradedWeight = 0;

    for (var eval in evaluations) {
      if (eval.scoreObtained != null) {
        double peso = eval.weight > 1 ? eval.weight / 100 : eval.weight;
        totalAccumulatedPoints += eval.scoreObtained! * peso;
        totalGradedWeight += eval.weight > 1 ? eval.weight : eval.weight * 100;
      }
    }

    double remainingWeight = 100 - totalGradedWeight;

    if (remainingWeight <= 0.1) {
      // Margen de error pequeño
      return totalAccumulatedPoints >= 10.5
          ? "¡Felicidades! Ya aprobaste el curso 🎉"
          : "Lo siento, ya no hay puntos suficientes 💀";
    }

    double pointsNeeded = 10.5 - totalAccumulatedPoints;
    if (pointsNeeded <= 0) return "¡Ya aprobaste! Solo mantén el ritmo 😎";

    double gradeNeeded = pointsNeeded / (remainingWeight / 100);
    if (gradeNeeded > 20) {
      return "Necesitas $gradeNeeded... Matemáticamente imposible ⚰️";
    }

    return "Necesitas promedio de ${gradeNeeded.toStringAsFixed(2)} en el ${remainingWeight.toInt()}% restante";
  }

  // --- 2. PLANTILLA SAN MARCOS (PARCIAL, FINAL, CONTINUO) ---
  void _applySanMarcosTemplate() async {
    // Verificar si ya tiene notas para no duplicar
    if (widget.course.evaluations.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "El curso ya tiene evaluaciones. Limpia la lista primero.")));
      return;
    }

    // Estructura Clásica
    final parcial = Evaluation()
      ..name = "Examen Parcial"
      ..weight = 30
      ..courseId = widget.course.key as int;
    final finalExam = Evaluation()
      ..name = "Examen Final"
      ..weight = 30
      ..courseId = widget.course.key as int;
    final continuo = Evaluation()
      ..name = "Examen Continuo"
      ..weight = 40
      ..courseId = widget.course.key as int;

    widget.course.evaluations.addAll([parcial, continuo, finalExam]);
    await widget.course.save();

    setState(() {}); // Refrescar pantalla
  }

  // --- 3. CALCULADORA DE SUB-NOTAS (Para el Examen Continuo) ---
  Future<double?> _showSubGradeCalculator(BuildContext context) async {
    // Lista temporal de notas (Ej: Prácticas, Labs)
    List<double> subGrades = [];
    final subGradeController = TextEditingController();

    return showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateCalc) {
            // Función interna para agregar a la lista
            void addSubGrade() {
              if (subGradeController.text.isNotEmpty) {
                final val = double.tryParse(subGradeController.text);
                if (val != null && val >= 0 && val <= 20) {
                  setStateCalc(() {
                    subGrades.add(val);
                    subGradeController.clear();
                  });
                }
              }
              // Mantener foco para seguir escribiendo rápido
            }

            double promedio = subGrades.isEmpty
                ? 0
                : subGrades.reduce((a, b) => a + b) / subGrades.length;

            return AlertDialog(
              title: const Text("🧮 Calculadora de Continuo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Agrega tus prácticas, laboratorios, etc. aquí. El sistema calculará el promedio simple.",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subGradeController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: const InputDecoration(
                              labelText: "Nota (Ej: 14)",
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10)),
                          onSubmitted: (_) =>
                              addSubGrade(), // ENTER para agregar
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.blueAccent, size: 30),
                        onPressed: addSubGrade,
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Lista de notas agregadas
                  if (subGrades.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      children: subGrades
                          .map((g) => Chip(
                                label: Text(g.toStringAsFixed(0)),
                                onDeleted: () =>
                                    setStateCalc(() => subGrades.remove(g)),
                              ))
                          .toList(),
                    ),
                  const Divider(),
                  Text("Promedio: ${promedio.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.greenAccent)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(
                        context, double.parse(promedio.toStringAsFixed(2))),
                    child: const Text("USAR ESTE PROMEDIO")),
              ],
            );
          },
        );
      },
    );
  }

  // --- 4. DIÁLOGO PRINCIPAL (Con Enter y Calculadora) ---
  void _showEvaluationDialog(BuildContext context,
      [Evaluation? evaluationToEdit]) {
    final nameController = TextEditingController(text: evaluationToEdit?.name);
    final scoreController =
        TextEditingController(text: evaluationToEdit?.score?.toString());
    final weightController =
        TextEditingController(text: evaluationToEdit?.weight.toString());
    DateTime? selectedDate = evaluationToEdit?.date;

    // Función de guardado extraída para usarla en botones y ENTER
    Future<void> submit() async {
      if (nameController.text.isEmpty || weightController.text.isEmpty) return;

      FocusScope.of(context).unfocus(); // Cerrar teclado

      final name = nameController.text;
      final weight =
          double.tryParse(weightController.text.replaceAll('%', '').trim()) ??
              0.0;
      final score = scoreController.text.isEmpty
          ? null
          : double.tryParse(scoreController.text);

      if (evaluationToEdit == null) {
        // CREAR
        final newEval = Evaluation()
          ..name = name
          ..weight = weight
          ..score = score
          ..courseId = widget.course.key as int
          ..date = selectedDate;
        widget.course.evaluations.add(newEval);
      } else {
        // EDITAR
        evaluationToEdit.name = name;
        evaluationToEdit.weight = weight;
        evaluationToEdit.score = score;
        evaluationToEdit.date = selectedDate;
      }

      await widget.course.save();
      if (context.mounted) Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(evaluationToEdit == null
                  ? 'Nueva Evaluación'
                  : 'Editar Evaluación'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // NOMBRE
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment)),
                      textInputAction:
                          TextInputAction.next, // ENTER pasa al siguiente
                    ),
                    const SizedBox(height: 10),

                    // NOTA + CALCULADORA
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: scoreController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Nota',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.grade)),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        // BOTÓN DE CALCULADORA PARA CONTINUO
                        IconButton(
                          icon: const Icon(Icons.calculate,
                              color: Colors.orangeAccent),
                          tooltip: "Calcular promedio de prácticas/labs",
                          onPressed: () async {
                            final promedioCalculado =
                                await _showSubGradeCalculator(context);
                            if (promedioCalculado != null) {
                              scoreController.text =
                                  promedioCalculado.toString();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // PESO
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Peso %',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pie_chart)),
                      textInputAction: TextInputAction
                          .done, // ENTER aquí envía el formulario
                      onSubmitted: (_) =>
                          submit(), // 👈 MAGIA: Enter guarda todo
                    ),
                    const SizedBox(height: 20),

                    // CALENDARIO
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today,
                          color: Colors.blueAccent),
                      title: Text(
                          selectedDate == null
                              ? "Programar fecha (Opcional)"
                              : "Fecha: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          style: TextStyle(
                              color: selectedDate == null ? Colors.grey : null,
                              fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (evaluationToEdit != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Borrar manualmente de la lista del curso
                      widget.course.evaluations.remove(evaluationToEdit);
                      await widget.course.save(); // Guardar el padre
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  onPressed: submit,
                  child: const Text('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        actions: [
          // BOTÓN MÁGICO: Plantilla San Marcos
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: "Cargar Estructura San Marcos",
            onPressed: _applySanMarcosTemplate,
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<Course>(HiveDataService.boxCourses).listenable(),
        builder: (context, Box<Course> box, _) {
          final freshCourse = box.get(widget.course.key);
          final evaluations = freshCourse?.evaluations ?? [];
          final average = _calculateAverage(evaluations);

          return Column(
            children: [
              // 1. TARJETA RESUMEN
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: average >= 10.5
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    // ignore: deprecated_member_use
                    BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Promedio Actual:",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    Text(
                      average.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: average >= 10.5
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ORÁCULO
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900,
                  borderRadius: BorderRadius.circular(10),
                  // ignore: deprecated_member_use
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getPrediction(evaluations),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. LISTA
              Expanded(
                child: evaluations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("¡Curso vacío!",
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text("Usar Estructura San Marcos"),
                              onPressed: _applySanMarcosTemplate,
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: evaluations.length,
                        itemBuilder: (context, index) {
                          final eval = evaluations[index];
                          String dateText = eval.date != null
                              ? " • ${eval.date!.day}/${eval.date!.month}"
                              : "";

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.shade100,
                              child: Text("${eval.weight.toInt()}%",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black)),
                            ),
                            title: Text(eval.name),
                            subtitle: Text((eval.scoreObtained != null
                                ? "Nota: ${eval.scoreObtained}$dateText"
                                : "Pendiente$dateText")),
                            trailing: eval.scoreObtained != null
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.circle_outlined,
                                    color: Colors.grey),
                            onTap: () => _showEvaluationDialog(context, eval),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEvaluationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
