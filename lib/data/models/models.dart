import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class Semester extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late DateTime startDate;

  @HiveField(2)
  bool isCurrent = false;

  // 👇 AGREGAR ESTO: Convierte el objeto a Mapa
  Map<String, dynamic> toJson() {
    return {
      'id': key, // Guardamos la Key original para mantener las relaciones
      'name': name,
      'startDate':
          startDate.toIso8601String(), // Las fechas se guardan como texto ISO
      'isCurrent': isCurrent,
    };
  }
}

@HiveType(typeId: 1)
class Course extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late int credits;

  @HiveField(2)
  late int semesterId; // Esta es la conexión con el Semestre

  @HiveField(3)
  String? professorName;

  // 👇 AGREGAR ESTO
  Map<String, dynamic> toJson() {
    return {
      'id': key,
      'name': name,
      'credits': credits,
      'semesterId': semesterId,
      'professorName': professorName,
    };
  }
}

@HiveType(typeId: 2)
class Evaluation extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  double? score; // Nota

  @HiveField(2)
  late double weight; // Peso %

  @HiveField(3)
  late int courseId; // Conexión con el Curso

  double? get scoreObtained => score;

  // 👇 AGREGAR ESTO
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'weight': weight,
      'courseId': courseId,
    };
  }
}
