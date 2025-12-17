// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SemesterAdapter extends TypeAdapter<Semester> {
  @override
  final int typeId = 0;

  @override
  Semester read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Semester()
      ..name = fields[0] as String
      ..startDate = fields[1] as DateTime
      ..isCurrent = fields[2] as bool;
  }

  @override
  void write(BinaryWriter writer, Semester obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.isCurrent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 1;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course()
      ..name = fields[0] as String
      ..credits = fields[1] as int
      ..semesterId = fields[2] as int
      ..professorName = fields[3] as String?
      ..section = fields[4] as String?
      ..schedules = (fields[5] as List).cast<ClassSession>();
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.credits)
      ..writeByte(2)
      ..write(obj.semesterId)
      ..writeByte(3)
      ..write(obj.professorName)
      ..writeByte(4)
      ..write(obj.section)
      ..writeByte(5)
      ..write(obj.schedules);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EvaluationAdapter extends TypeAdapter<Evaluation> {
  @override
  final int typeId = 2;

  @override
  Evaluation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Evaluation()
      ..name = fields[0] as String
      ..score = fields[1] as double?
      ..weight = fields[2] as double
      ..courseId = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, Evaluation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.courseId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClassSessionAdapter extends TypeAdapter<ClassSession> {
  @override
  final int typeId = 3;

  @override
  ClassSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassSession(
      dayIndex: fields[0] as int,
      startHour: fields[1] as int,
      durationHours: fields[2] as int,
      classroom: fields[3] as String,
      type: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClassSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dayIndex)
      ..writeByte(1)
      ..write(obj.startHour)
      ..writeByte(2)
      ..write(obj.durationHours)
      ..writeByte(3)
      ..write(obj.classroom)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
