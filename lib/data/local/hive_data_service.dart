import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveDataService {
  // Nombres de las "Cajas" (Tablas)
  static const boxSemesters = 'semestersBox';
  static const boxCourses = 'coursesBox';
  static const boxEvaluations = 'evaluationsBox';
  static const String boxStudySessions = 'studySessionsBox';

  Future<void> init() async {
    await Hive.initFlutter();

    // Registrar los adaptadores generados
    Hive.registerAdapter(SemesterAdapter());
    Hive.registerAdapter(CourseAdapter());
    Hive.registerAdapter(EvaluationAdapter());
    Hive.registerAdapter(ClassSessionAdapter());
    Hive.registerAdapter(StudySessionAdapter());

    // Abrir las cajas
    await Hive.openBox<Semester>(boxSemesters);
    await Hive.openBox<Course>(boxCourses);
    await Hive.openBox<Evaluation>(boxEvaluations);
    await Hive.openBox('settingsBox');
    await Hive.openBox<StudySession>(boxStudySessions);
  }

  // --- SEMESTRES ---
  Future<void> saveSemester(Semester semester) async {
    final box = Hive.box<Semester>(boxSemesters);
    // .add() autogenera el ID y lo guarda en el objeto
    await box.add(semester);
  }

  List<Semester> getSemesters() {
    return Hive.box<Semester>(boxSemesters).values.toList();
  }

  // --- CURSOS ---
  Future<void> saveCourse(Course course) async {
    final box = Hive.box<Course>(boxCourses);
    await box.add(course);
  }

  // Obtener cursos de un semestre
  List<Course> getCoursesFor(int semesterId) {
    // Aquí usamos el ID (key)
    final box = Hive.box<Course>(boxCourses);
    // Filtramos en memoria (Hive es rapidísimo, no hay problema)
    return box.values.where((c) => c.semesterId == semesterId).toList();
  }

  // --- EVALUACIONES ---
  Future<void> saveEvaluation(Evaluation evaluation) async {
    final box = Hive.box<Evaluation>(boxEvaluations);
    await box.add(evaluation);
  }

  // Obtener evaluaciones de un curso (Opcional, ya que usamos el filtro en la UI)
  List<Evaluation> getEvaluationsFor(int courseId) {
    final box = Hive.box<Evaluation>(boxEvaluations);
    return box.values.where((e) => e.courseId == courseId).toList();
  }

  Future<void> saveStudySession(StudySession session) async {
    final box = Hive.box<StudySession>(boxStudySessions);
    await box.add(session);
    if (kDebugMode) {
      print(
          "✅ Sesión guardada: ${session.durationMinutes} min para curso ${session.courseId}");
    }
  }
}
