import 'dart:convert';
// import 'dart:io'; // ❌ BORRAMOS ESTO (Causa error en Web)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart'; // ❌ BORRAMOS ESTO
import 'package:share_plus/share_plus.dart';
import 'hive_data_service.dart';
import '../models/models.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  Future<void> exportData(BuildContext context) async {
    try {
      // 1. RECOLECTAR DATOS (Igual que antes)
      final boxSemesters = Hive.box<Semester>(HiveDataService.boxSemesters);
      final boxCourses = Hive.box<Course>(HiveDataService.boxCourses);
      final boxEvaluations =
          Hive.box<Evaluation>(HiveDataService.boxEvaluations);

      final Map<String, dynamic> bigDataMap = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'semesters': boxSemesters.values.map((s) => s.toJson()).toList(),
        'courses': boxCourses.values.map((c) => c.toJson()).toList(),
        'evaluations': boxEvaluations.values.map((e) => e.toJson()).toList(),
      };

      // 2. CONVERTIR A BYTES (EN MEMORIA)
      // En lugar de guardar en disco, lo convertimos a "bytes" directamente en la RAM
      final String jsonString = jsonEncode(bigDataMap);
      final List<int> bytes =
          utf8.encode(jsonString); // Convertimos texto a datos binarios

      // 3. PREPARAR EL ARCHIVO VIRTUAL
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'studyflow_backup_$dateStr.json';

      // Usamos XFile.fromData (Funciona en Web y Celular)
      final xFile = XFile.fromData(
        (bytes as dynamic), // Truco para compatibilidad de tipos
        mimeType: 'application/json',
        name: fileName,
      );

      // 4. COMPARTIR / DESCARGAR
      if (context.mounted) {
        // En Celular: Abre el menú de compartir (WhatsApp, Drive).
        // En Chrome: Descarga el archivo automáticamente a tu carpeta "Descargas".
        await Share.shareXFiles(
          [xFile],
          subject: 'Copia de Seguridad StudyFlow',
          text: 'Aquí tienes tu respaldo de notas 🚀',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al exportar: $e");
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> restoreData(BuildContext context) async {
    try {
      // 1. ELEGIR ARCHIVO
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Importante para Web (carga los bytes en memoria)
      );

      if (result == null) return; // Usuario canceló

      // 2. LEER CONTENIDO
      // En Web y Móvil, result.files.first.bytes tiene el contenido
      final bytes = result.files.first.bytes;
      if (bytes == null) throw "No se pudo leer el archivo";

      final String jsonString = utf8.decode(bytes);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // 3. LIMPIEZA TOTAL (Borramos la base de datos actual)
      final boxSemesters = Hive.box<Semester>(HiveDataService.boxSemesters);
      final boxCourses = Hive.box<Course>(HiveDataService.boxCourses);
      final boxEvaluations =
          Hive.box<Evaluation>(HiveDataService.boxEvaluations);

      await boxSemesters.clear();
      await boxCourses.clear();
      await boxEvaluations.clear();

      // --- MAPAS DE TRADUCCIÓN DE IDs (La "Libreta") ---
      // Map<ID_Viejo, ID_Nuevo>
      final Map<int, int> semesterMap = {};
      final Map<int, int> courseMap = {};

      // 4. RESTAURAR SEMESTRES (Fase 1)
      final semestersList = data['semesters'] as List;
      for (var sJson in semestersList) {
        final oldId = sJson['id']; // El ID que tenía antes

        final newSemester = Semester()
          ..name = sJson['name']
          ..startDate = DateTime.parse(sJson['startDate'])
          ..isCurrent = sJson['isCurrent'];

        // Al agregar, Hive nos devuelve el NUEVO ID
        final newId = await boxSemesters.add(newSemester);

        // Anotamos la traducción
        if (oldId != null) semesterMap[oldId] = newId;
      }

      // 5. RESTAURAR CURSOS (Fase 2)
      final coursesList = data['courses'] as List;
      for (var cJson in coursesList) {
        final oldId = cJson['id'];
        final oldSemId = cJson['semesterId'];

        // Buscamos el ID nuevo del semestre padre
        final newSemId = semesterMap[oldSemId];

        if (newSemId != null) {
          final newCourse = Course()
            ..name = cJson['name']
            ..credits = cJson['credits']
            ..professorName = cJson['professorName']
            ..semesterId = newSemId; // 👈 Conectamos con el nuevo ID

          final newId = await boxCourses.add(newCourse);
          if (oldId != null) courseMap[oldId] = newId;
        }
      }

      // 6. RESTAURAR EVALUACIONES (Fase 3)
      final evalsList = data['evaluations'] as List;
      for (var eJson in evalsList) {
        final oldCourseId = eJson['courseId'];
        final newCourseId = courseMap[oldCourseId];

        if (newCourseId != null) {
          final newEval = Evaluation()
            ..name = eJson['name']
            ..score = eJson['score'] // (Ya acepta nulos gracias a tu arreglo)
            ..weight = eJson['weight']
            ..courseId = newCourseId; // 👈 Conectamos con el nuevo ID

          await boxEvaluations.add(newEval);
        }
      }

      // 7. ÉXITO
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('¡Datos restaurados con éxito! 🔄'),
              backgroundColor: Colors.green),
        );
        // Forzamos un reinicio visual simple cerrando el drawer o yendo a inicio
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al restaurar: $e");
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
