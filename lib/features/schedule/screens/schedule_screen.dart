import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../data/local/hive_data_service.dart';
import '../../../../data/models/models.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Configuración de la cuadrícula
  final int startHour = 7; // 7:00 AM
  final int endHour = 22; // 10:00 PM
  final double hourHeight = 60.0; // Altura de cada celda de hora
  final double timeColumnWidth = 60.0; // Ancho de la columna de horas

  // Colores para los cursos (para que se vea bonito)
  final List<Color> courseColors = [
    Colors.blueAccent.shade100,
    Colors.redAccent.shade100,
    Colors.greenAccent.shade100,
    Colors.orangeAccent.shade100,
    Colors.purpleAccent.shade100,
    Colors.tealAccent.shade100,
  ];

  @override
  Widget build(BuildContext context) {
    // Usamos ValueListenableBuilder para que se actualice si cambias de semestre actual
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Semester>(HiveDataService.boxSemesters).listenable(),
      builder: (context, Box<Semester> boxSemesters, _) {
        // 1. Buscar el Semestre Actual
        final currentSemester = boxSemesters.values.firstWhere(
          (s) => s.isCurrent,
          orElse: () => Semester()..name = "Sin Semestre Activo",
        );

        if (currentSemester.key == null) {
          return const Center(child: Text("Activa un semestre primero"));
        }

        // 2. Buscar los Cursos de este semestre
        final boxCourses = Hive.box<Course>(HiveDataService.boxCourses);
        final myCourses = boxCourses.values
            .where((c) => c.semesterId == currentSemester.key)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('Horario ${currentSemester.name} 🗓️'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // --- CABECERA (DÍAS) ---
              _buildDaysHeader(),

              // --- CUERPO (GRILLA DE HORAS + BLOQUES) ---
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna lateral de Horas (7:00, 8:00...)
                      _buildTimeColumn(),

                      // El área principal donde van los bloques
                      Expanded(
                        child: Stack(
                          children: [
                            // Capa 1: Las líneas horizontales de fondo
                            _buildGridLines(),
                            // Capa 2: Los bloques de colores de las clases
                            ..._buildCourseBlocks(myCourses),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // WIDGET: Cabecera con Lunes, Martes, etc.
  Widget _buildDaysHeader() {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return Container(
      height: 50,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: [
            // ignore: deprecated_member_use
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
          ]),
      child: Row(
        children: [
          SizedBox(width: timeColumnWidth), // Espacio para la columna de horas
          // Generamos los 7 días
          ...List.generate(
              7,
              (index) => Expanded(
                    child: Center(
                        child: Text(days[index],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                  )),
        ],
      ),
    );
  }

  // WIDGET: Columna lateral con las horas
  Widget _buildTimeColumn() {
    return Column(
      children: List.generate(endHour - startHour + 1, (index) {
        final hour = startHour + index;
        return Container(
          height: hourHeight,
          width: timeColumnWidth,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 5),
          child: Text("$hour:00",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        );
      }),
    );
  }

  // WIDGET: Líneas de fondo de la grilla
  Widget _buildGridLines() {
    return Column(
      children: List.generate(endHour - startHour, (index) {
        return Container(
          height: hourHeight,
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                right: BorderSide(color: Colors.grey.shade300, width: 1)),
          ),
        );
      }),
    );
  }

  // LÓGICA: Generar los bloques de colores
  List<Widget> _buildCourseBlocks(List<Course> courses) {
    List<Widget> blocks = [];
    int colorIndex = 0;

    for (var course in courses) {
      final color = courseColors[
          colorIndex % courseColors.length]; // Asignar color cíclico

      for (var session in course.schedules) {
        // MATH TIME: Calcular posición y tamaño
        // dayIndex es 1-based (Lunes=1), lo pasamos a 0-based para el cálculo
        final dayColumnIndex = session.dayIndex - 1;

        // La posición superior (top) depende de a qué hora empieza
        final topOffset = (session.startHour - startHour) * hourHeight;

        // La altura depende de la duración
        final blockHeight = session.durationHours * hourHeight;

        // Usamos Positioned para ubicarlo en el Stack
        blocks.add(Positioned(
          top: topOffset,
          left: dayColumnIndex *
              (MediaQuery.of(context).size.width - timeColumnWidth) /
              7,
          width: (MediaQuery.of(context).size.width - timeColumnWidth) / 7,
          height: blockHeight,
          child: Container(
            margin: const EdgeInsets.all(
                2), // Un pequeño margen para que se vean separados
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: color.darken(0.2)) // Borde un poco más oscuro
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${session.type} • Aula ${session.classroom}",
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                ),
                if (course.section != null)
                  Text(
                    "Sec: ${course.section}",
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ));
      }
      colorIndex++;
    }
    return blocks;
  }
}

// Pequeña extensión para oscurecer el color del borde
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
