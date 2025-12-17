import 'package:hive/hive.dart';

part 'models.g.dart';

// --- TUS MODELOS EXISTENTES (Semester) ---
@HiveType(typeId: 0)
class Semester extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late DateTime startDate;

  @HiveField(2)
  bool isCurrent = false;

  Map<String, dynamic> toJson() {
    return {
      'id': key,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}

// --- ACTUALIZACIÓN EN CURSO ---
@HiveType(typeId: 1)
class Course extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late int credits;

  @HiveField(2)
  late int semesterId;

  @HiveField(3)
  String? professorName;

  // 👇 NUEVO CAMPO: SECCIÓN (Ej: "Grupo 1", "Sección B")
  @HiveField(4)
  String? section;

  // 👇 NUEVO CAMPO: LISTA DE HORARIOS (Ej: Lunes 8-10, Jueves 14-16)
  @HiveField(5)
  List<ClassSession> schedules = [];

  Map<String, dynamic> toJson() {
    return {
      'id': key,
      'name': name,
      'credits': credits,
      'semesterId': semesterId,
      'professorName': professorName,
      'section': section, // Agregar al backup
      'schedules':
          schedules.map((s) => s.toJson()).toList(), // Agregar al backup
    };
  }
}

// --- EVALUATION (Sin cambios, solo verifica que esté ok) ---
@HiveType(typeId: 2)
class Evaluation extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  double? score;
  @HiveField(2)
  late double weight;
  @HiveField(3)
  late int courseId;

  double? get scoreObtained => score;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'weight': weight,
      'courseId': courseId,
    };
  }
}

// --- 👇 NUEVA CLASE PARA EL HORARIO 👇 ---
// No necesita extender HiveObject porque vivirá DENTRO de Course
@HiveType(typeId: 3)
class ClassSession {
  @HiveField(0)
  late int dayIndex; // 1=Lunes, 2=Martes, ..., 6=Sábado, 7=Domingo

  @HiveField(1)
  late int startHour; // Ej: 8 (para las 8:00 AM)

  @HiveField(2)
  late int durationHours; // Ej: 2 (dura 2 horas)

  @HiveField(3)
  late String classroom; // Ej: "SJL-201"

  @HiveField(4)
  late String type; // "Teoría", "Práctica", "Laboratorio"

  ClassSession({
    required this.dayIndex,
    required this.startHour,
    required this.durationHours,
    required this.classroom,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayIndex': dayIndex,
      'startHour': startHour,
      'durationHours': durationHours,
      'classroom': classroom,
      'type': type,
    };
  }
}
