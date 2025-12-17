import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../data/local/hive_data_service.dart';
import '../../../../data/models/models.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // CONFIGURACIÓN (En segundos)
  // static const int focusTime = 5; // ⚡ MODO PRUEBA RÁPIDA (Descomentar para probar)
  static const int focusTime = 25 * 60;
  static const int breakTime = 5 * 60;

  int timeLeft = focusTime;
  bool isRunning = false;
  bool isFocusMode = true;
  Timer? _timer;

  // 👇 NUEVO: SELECCIÓN DE CURSO
  int? selectedCourseId; // Null = General / Sin Asignar

  Color get currentColor => isFocusMode ? Colors.redAccent : Colors.green;
  String get currentModeText =>
      isFocusMode ? "MODO ENFOQUE 🧠" : "MODO DESCANSO ☕";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _finishSession();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      timeLeft = isFocusMode ? focusTime : breakTime;
    });
  }

  // 👇 LÓGICA DE GUARDADO MEJORADA
  Future<void> _finishSession() async {
    _stopTimer();
    HapticFeedback.heavyImpact();

    // SI TERMINAMOS UN POMODORO DE ESTUDIO, GUARDAMOS LOS DATOS
    if (isFocusMode) {
      final session = StudySession()
        ..courseId = selectedCourseId ?? -1 // -1 significa "General"
        ..date = DateTime.now()
        ..durationMinutes =
            (focusTime / 60).round(); // Guardamos 25 min (o lo que configures)

      await HiveDataService().saveStudySession(session);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
            isFocusMode ? "¡Sesión Completada! 🎉" : "¡Descanso Terminado! 🚀"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isFocusMode
                ? "Has sumado 25 minutos a tu historial."
                : "Es hora de volver a concentrarse."),
            if (isFocusMode && selectedCourseId != null)
              const Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text("Datos guardados correctamente ✅",
                    style: TextStyle(fontSize: 12, color: Colors.green)),
              )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _switchMode();
            },
            child: const Text("CONTINUAR"),
          )
        ],
      ),
    );
  }

  void _switchMode() {
    setState(() {
      isFocusMode = !isFocusMode;
      timeLeft = isFocusMode ? focusTime : breakTime;
    });
  }

  String _formatTime() {
    final minutes = (timeLeft / 60).floor().toString().padLeft(2, '0');
    final seconds = (timeLeft % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final totalTime = isFocusMode ? focusTime : breakTime;
    final progress = timeLeft / totalTime;

    return Scaffold(
      appBar: AppBar(title: const Text("Pomodoro Inteligente")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 👇 WIDGET SELECTOR DE CURSO
            // Solo se muestra si estamos en modo ENFOQUE y el reloj está PAUSADO (para no cambiar a mitad)
            if (isFocusMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ValueListenableBuilder(
                  valueListenable:
                      Hive.box<Course>(HiveDataService.boxCourses).listenable(),
                  builder: (context, Box<Course> box, _) {
                    // 👇 LÓGICA CORREGIDA 👇
                    // 1. Buscamos el ID del semestre activo de forma segura
                    int activeSemesterId = -1;
                    try {
                      final semesterBox =
                          Hive.box<Semester>(HiveDataService.boxSemesters);
                      final activeSemester =
                          semesterBox.values.firstWhere((s) => s.isCurrent);
                      activeSemesterId = activeSemester.key as int;
                    } catch (_) {
                      // Si no hay semestre activo o falla, el ID se queda en -1
                    }

                    // 2. Filtramos usando ese ID
                    final courses = box.values
                        .where((c) => c.semesterId == activeSemesterId)
                        .toList();
                    // 👆 FIN DE LA CORRECCIÓN 👆

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.blueGrey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blueGrey)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedCourseId,
                          hint: const Text("¿Qué vas a estudiar? 📚"),
                          isExpanded: true,
                          dropdownColor:
                              Colors.grey.shade900, // Color oscuro para el menú
                          items: [
                            const DropdownMenuItem(
                                value: null,
                                child: Text("Estudio General / Tareas Varios")),
                            ...courses.map((c) => DropdownMenuItem(
                                  value: c.key as int,
                                  child: Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ))
                          ],
                          onChanged: isRunning
                              ? null
                              : (v) => setState(() => selectedCourseId = v),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            // ETIQUETA DEL MODO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: currentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: currentColor)),
              child: Text(currentModeText,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: currentColor)),
            ),

            const SizedBox(height: 40),

            // RELOJ
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                      value: 1.0, strokeWidth: 15, color: Colors.grey.shade800),
                ),
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 15,
                      color: currentColor,
                      strokeCap: StrokeCap.round),
                ),
                Text(_formatTime(),
                    style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),

            const SizedBox(height: 50),

            // CONTROLES
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "reset",
                  onPressed: _resetTimer,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                    heroTag: "play",
                    onPressed: _toggleTimer,
                    backgroundColor: currentColor,
                    child: Icon(isRunning ? Icons.pause : Icons.play_arrow,
                        size: 40, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
