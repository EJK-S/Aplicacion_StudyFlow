import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/local/hive_data_service.dart';
import '../../data/models/models.dart';
import '../courses/screens/courses_list_screen.dart';

class SemestersListScreen extends StatefulWidget {
  const SemestersListScreen({super.key});

  @override
  State<SemestersListScreen> createState() => _SemestersListScreenState();
}

class _SemestersListScreenState extends State<SemestersListScreen> {
  // ignore: non_constant_identifier_names
  final DataService = HiveDataService();

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder escucha cambios en la caja de Hive automáticamente
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Semester>(HiveDataService.boxSemesters).listenable(),
      builder: (context, Box<Semester> box, widget) {
        final semesters = box.values.toList();

        if (semesters.isEmpty) {
          return const Center(
            child: Text(
              'No tienes semestres registrados.\n¡Empieza agregando uno!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: semesters.length,
          itemBuilder: (context, index) {
            final semester = semesters[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      semester.isCurrent ? Colors.blueAccent : Colors.grey,
                  child: const Icon(Icons.calendar_today, color: Colors.white),
                ),
                title: Text(
                  semester.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    "Inicio: ${semester.startDate.toString().split(' ')[0]}"),
                trailing: semester.isCurrent
                    ? const Chip(
                        label: Text("Actual",
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.green)
                    : null,
                onTap: () {
                  // Navegación real
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CoursesListScreen(semester: semester),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
