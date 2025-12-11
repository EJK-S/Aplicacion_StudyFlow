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
}

@HiveType(typeId: 1)
class Course extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  String? professorName;

  @HiveField(2)
  int credits = 0;

  @HiveField(3)
  String color = '#FF5733';

  @HiveField(4)
  int semesterId = 0; // Relación manual por ID
}

@HiveType(typeId: 2)
class Evaluation extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  double? scoreObtained;

  @HiveField(2)
  double weight = 0.0;

  @HiveField(3)
  int courseId = 0; // Relación manual por ID
}
