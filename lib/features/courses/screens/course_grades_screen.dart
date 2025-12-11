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
  // Función matemática para calcular el promedio
  double _calculateAverage(List<Evaluation> evaluations) {
    double totalScore = 0;
    double totalWeight = 0;

    for (var eval in evaluations) {
      if (eval.scoreObtained != null) {
        // Multiplicamos nota * peso (Ej: 18 * 0.30)
        totalScore += eval.scoreObtained! *
            (eval.weight / 100); // Asumimos peso en % (30%)
        totalWeight += (eval.weight / 100);
      }
    }

    if (totalWeight == 0) return 0.0;
    return totalScore /
        totalWeight; // Promedio ponderado real (sobre lo avanzado)
  }

  String _getPrediction(List<Evaluation> evaluations) {
    double totalAccumulatedPoints = 0; // Puntos que ya tienes en el bolsillo
    double totalGradedWeight = 0; // Peso que ya se jugó (ej: 60%)

    for (var eval in evaluations) {
      if (eval.scoreObtained != null) {
        totalAccumulatedPoints += eval.scoreObtained! * (eval.weight / 100);
        totalGradedWeight += eval.weight;
      }
    }

    // El peso que falta por evaluarse (El Futuro)
    double remainingWeight = 100 - totalGradedWeight;

    // Si ya se evaluó todo (o casi todo)
    if (remainingWeight <= 0) {
      return totalAccumulatedPoints >= 10.5
          ? "¡Felicidades! Ya aprobaste el curso 🎉"
          : "Lo siento, ya no hay puntos suficientes 💀";
    }

    // Cálculo inverso: (Meta - LoQueTengo) / (PesoRestante%)
    double pointsNeeded = 10.5 - totalAccumulatedPoints;

    if (pointsNeeded <= 0) {
      return "¡Ya aprobaste! Solo mantén el ritmo 😎";
    }

    double gradeNeeded = pointsNeeded / (remainingWeight / 100);

    if (gradeNeeded > 20) {
      return "Necesitas $gradeNeeded... Matemáticamente imposible ⚰️";
    }

    return "Necesitas promedio de ${gradeNeeded.toStringAsFixed(2)} en el ${remainingWeight.toInt()}% restante";
  }

  // Formulario para agregar nota
  void _showAddEvaluationForm(BuildContext context) {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    final weightController = TextEditingController();

    // Lógica encapsulada
    Future<void> submitForm() async {
      if (nameController.text.isEmpty || weightController.text.isEmpty) return;

      final service = HiveDataService();
      final newEval = Evaluation()
        ..name = nameController.text
        ..scoreObtained = double.tryParse(scoreController.text)
        // Incluimos el parche del % aquí también por seguridad
        ..weight =
            double.tryParse(weightController.text.replaceAll('%', '').trim()) ??
                0.0
        ..courseId = widget.course.key;

      await service.saveEvaluation(newEval);
      if (context.mounted) Navigator.pop(context);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nueva Evaluación 📝',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nombre (Ej: Examen Parcial)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment)),
                autofocus: true,
                textInputAction: TextInputAction.next, // Siguiente
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Nota (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade)),
                      textInputAction: TextInputAction.next, // Siguiente
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Peso % (Ej: 30)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pie_chart)),
                      // 👇 MAGIA: Enter = Guardar
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitForm(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitForm,
                child: const Text('GUARDAR NOTA'),
              )
            ],
          ),
        );
      },
    );
  }

  // 👇 PEGA ESTE BLOQUE AQUÍ (Entre _showAddEvaluationForm y build)

  void _showEditEvaluationForm(BuildContext context, Evaluation eval) {
    final nameController = TextEditingController(text: eval.name);
    final scoreController =
        TextEditingController(text: eval.scoreObtained?.toString() ?? '');
    final weightController =
        TextEditingController(text: eval.weight.toString());

    // 1. CREAMOS LA FUNCIÓN DE GUARDAR AQUÍ ADENTRO PARA REUTILIZARLA
    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;

      eval.name = nameController.text;
      eval.scoreObtained = double.tryParse(scoreController.text);
      eval.weight =
          double.tryParse(weightController.text.replaceAll('%', '').trim()) ??
              0.0;

      await eval.save();
      if (context.mounted) Navigator.pop(context);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar Evaluación ✏️',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // CAMPO 1: NOMBRE
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment)),
                // 👇 MAGIA 1: Al dar Enter, pasa al siguiente campo
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    // CAMPO 2: NOTA
                    child: TextField(
                      controller: scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Nota',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade)),
                      autofocus: true,
                      // 👇 MAGIA 2: Al dar Enter, pasa al Peso
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    // CAMPO 3: PESO (EL ÚLTIMO)
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Peso %',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pie_chart)),
                      // 👇 MAGIA 3: Al dar Enter aquí, ¡GUARDA COMPLETO!
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitForm(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await eval.delete();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      // Usamos la misma función que el teclado
                      onPressed: submitForm,
                      child: const Text('ACTUALIZAR'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
  // 👆 FIN DEL BLOQUE NUEVO

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.name)),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<Evaluation>(HiveDataService.boxEvaluations).listenable(),
        builder: (context, Box<Evaluation> box, _) {
          // Filtramos las notas de ESTE curso
          final evaluations =
              box.values.where((e) => e.courseId == widget.course.key).toList();
          final average = _calculateAverage(evaluations);

          return Column(
            children: [
              // TARJETA DE RESUMEN (PROMEDIO)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: average >= 10.5
                      ? Colors.green.shade100
                      : Colors.red.shade100, // Color dinámico (Aprobado/Jalado)
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
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
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      average.toStringAsFixed(2), // Muestra solo 2 decimales
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

              // --- INICIO DEL ORÁCULO ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900, // Fondo oscuro estilo hacker
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
                        _getPrediction(
                            evaluations), // Llamamos a la función mágica
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              // --- FIN DEL ORÁCULO ---

              const SizedBox(height: 10), // Un separador pequeño

              // LISTA DE NOTAS
              Expanded(
                child: evaluations.isEmpty
                    ? const Center(
                        child: Text("Sin evaluaciones aún. ¡Agrega una!"))
                    : ListView.builder(
                        itemCount: evaluations.length,
                        itemBuilder: (context, index) {
                          final eval = evaluations[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.shade100,
                              child: Text("${eval.weight.toInt()}%",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black)),
                            ),
                            title: Text(eval.name),
                            subtitle: Text(eval.scoreObtained != null
                                ? "Nota: ${eval.scoreObtained}"
                                : "Pendiente"),
                            trailing: eval.scoreObtained != null
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : const Icon(Icons.circle_outlined,
                                    color: Colors.grey),
                            onTap: () => _showEditEvaluationForm(context, eval),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEvaluationForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
