import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/local/hive_data_service.dart';
import '../../data/models/models.dart';
import '../courses/widgets/semester_summary_card.dart';
import 'semesters_list.dart';
import 'main_drawer.dart';

// 👇 IMPORTS DE LAS PESTAÑAS
import '../schedule/screens/schedule_screen.dart'; // 1. Tu Horario Nuevo
import '../courses/screens/courses_list_screen.dart'; // 2. Lista de Cursos
import '../courses/screens/tools_screen.dart'; // 3. Herramientas
import 'widgets/study_pie_chart.dart';
import 'widgets/insights_card.dart';
import 'widgets/upcoming_exams_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Controla qué pestaña estamos viendo (0: Inicio)

  // --- LISTA DE PÁGINAS ---
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeTab(), // Index 0: Lo que tenías antes (Resumen + Lista)
      const CurrentSemesterCoursesTab(), // Index 1: Cursos del ciclo actual
      const ScheduleScreen(), // Index 2: EL HORARIO 🗓️
      const ToolsScreen(), // Index 3: Herramientas
    ];
  }

  // --- FUNCIÓN PARA AGREGAR SEMESTRE (Solo se usa en la pestaña 0) ---
  void _showAddSemesterForm(BuildContext context) {
    final nameController = TextEditingController();
    bool isCurrent = true;

    Future<void> submitForm() async {
      if (nameController.text.isEmpty) return;
      final service = HiveDataService();

      if (isCurrent) {
        final box = Hive.box<Semester>(HiveDataService.boxSemesters);
        for (var s in box.values) {
          if (s.isCurrent) {
            s.isCurrent = false;
            s.save();
          }
        }
      }

      final nuevo = Semester()
        ..name = nameController.text
        ..startDate = DateTime.now()
        ..isCurrent = isCurrent;
      await service.saveSemester(nuevo);
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
              const Text('Nuevo Semestre 📅',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Nombre (Ej: 2026-I)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school)),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submitForm(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitForm,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white),
                child: const Text('GUARDAR CICLO'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('StudyFlow 🚀'),
        centerTitle: true,
      ),
      // Muestra la página según el índice seleccionado
      body: _pages[_selectedIndex],

      // 👇 BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Cursos'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month),
              label: 'Horario'), // <--- AQUÍ ESTÁ
          NavigationDestination(icon: Icon(Icons.build), label: 'Herramientas'),
        ],
      ),

      // El botón flotante solo aparece en la pestaña de Inicio (0)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddSemesterForm(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET 1: PESTAÑA DE INICIO (HOME TAB)
// ---------------------------------------------------------------------------
// Este es el código que tenías antes en el body, ahora empaquetado.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        // 1. Preparamos el widget del Resumen para no repetir código
        //    (Este es el bloque que daba error, ahora corregido)
        Widget buildSummaryCard() {
          return ValueListenableBuilder(
            valueListenable:
                Hive.box<Course>(HiveDataService.boxCourses).listenable(),
            builder: (context, Box<Course> coursesBox, _) {
              return ValueListenableBuilder(
                valueListenable:
                    Hive.box<Semester>(HiveDataService.boxSemesters)
                        .listenable(),
                builder: (context, Box<Semester> semesterBox, _) {
                  // 👇 LÓGICA SEGURA: Usamos try-catch en lugar de crear objetos falsos
                  Semester? activeSemester;
                  try {
                    activeSemester =
                        semesterBox.values.firstWhere((s) => s.isCurrent);
                  } catch (_) {
                    // Si no hay semestre activo, se queda en null
                    activeSemester = null;
                  }

                  // Si no hay semestre, no mostramos nada
                  if (activeSemester == null) return const SizedBox();

                  // Filtramos los cursos usando la key real del semestre encontrado
                  final courses = coursesBox.values
                      .where((c) => c.semesterId == activeSemester!.key)
                      .toList();

                  return SemesterSummaryCard(
                      semestreNombre: activeSemester.name, cursos: courses);
                },
              );
            },
          );
        }

        if (isDesktop) {
          // --- DISEÑO DE ESCRITORIO ---
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildSummaryCard(), // <--- Usamos la función corregida
                      const SizedBox(height: 16),
                      const Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: StudyPieChart(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const InsightsCard(),
                    ],
                  ),
                ),
              ),
              const Expanded(
                flex: 6,
                child: Column(
                  children: [
                    UpcomingExamsCard(),
                    Expanded(
                      child: SemestersListScreen(),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // --- DISEÑO MÓVIL ---
          return Column(
            children: [
              buildSummaryCard(), // <--- Usamos la función corregida
              const UpcomingExamsCard(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: StudyPieChart(),
                  ),
                ),
              ),
              const InsightsCard(),
              const Expanded(
                child: SemestersListScreen(),
              ),
            ],
          );
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET 2: PESTAÑA DE CURSOS ACTUALES (WRAPPER INTELIGENTE)
// ---------------------------------------------------------------------------
// Busca automáticamente el semestre activo para mostrar sus cursos
class CurrentSemesterCoursesTab extends StatelessWidget {
  const CurrentSemesterCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<Semester>(HiveDataService.boxSemesters).listenable(),
      builder: (context, Box<Semester> box, _) {
        try {
          final currentSemester = box.values.firstWhere((s) => s.isCurrent);
          // Si hay semestre actual, mostramos su lista de cursos
          return CoursesListScreen(semester: currentSemester);
        } catch (e) {
          // Si no hay semestre activo, mostramos un aviso
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("No tienes un ciclo activo",
                    style: TextStyle(fontSize: 18)),
                SizedBox(height: 5),
                Text("Ve a Inicio y crea o activa uno.",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
      },
    );
  }
}
