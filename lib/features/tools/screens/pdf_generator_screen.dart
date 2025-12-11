import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfGeneratorScreen extends StatefulWidget {
  const PdfGeneratorScreen({super.key});

  @override
  State<PdfGeneratorScreen> createState() => _PdfGeneratorScreenState();
}

class _PdfGeneratorScreenState extends State<PdfGeneratorScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // --- CONFIGURACIÓN DE UNIVERSIDADES ---
  // Aquí puedes agregar todas las que quieras
  final List<Map<String, String>> universidades = [
    {
      'id': 'unmsm',
      'nombre': 'UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS',
      'subtitulo': '(Universidad del Perú, Decana de América)',
      'logoPath':
          'assets/images/logo_unmsm.png', // Asegúrate de tener esta imagen
    },
    {
      'id': 'uni',
      'nombre': 'UNIVERSIDAD NACIONAL DE INGENIERÍA',
      'subtitulo': 'Lima - Perú',
      'logoPath': 'assets/images/logo_uni.png',
    },
    {
      'id': 'utp',
      'nombre': 'UNIVERSIDAD TECNOLÓGICA DEL PERÚ',
      'subtitulo': '',
      'logoPath': 'assets/images/logo_utp.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generador de Carátulas 📄")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- FORMULARIO ---
            FormBuilder(
              key: _formKey,
              initialValue: const {
                'uni_selector': 'unmsm', // Valor por defecto
                'facultad': 'Facultad de Ingeniería de Sistemas e Informática',
                'anio': '2025',
              },
              child: Column(
                children: [
                  // 1. Selector de Universidad (Esto define el logo)
                  FormBuilderDropdown<String>(
                    name: 'uni_selector',
                    decoration: const InputDecoration(
                        labelText: 'Selecciona tu Universidad'),
                    items: universidades
                        .map((uni) => DropdownMenuItem(
                              value: uni['id'],
                              child: Text(uni['id']!.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      // Opcional: Auto-llenar el nombre de la facultad si tienes esa data
                    },
                  ),
                  const SizedBox(height: 10),

                  FormBuilderTextField(
                    name: 'facultad',
                    decoration:
                        const InputDecoration(labelText: 'Facultad / Escuela'),
                  ),
                  const SizedBox(height: 10),

                  FormBuilderTextField(
                    name: 'curso',
                    decoration:
                        const InputDecoration(labelText: 'Curso / Asignatura'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  FormBuilderTextField(
                    name: 'tema',
                    decoration:
                        const InputDecoration(labelText: 'Título del Trabajo'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  // He notado en tu captura que dice "Uno por línea", así que ajusté la lógica
                  FormBuilderTextField(
                    name: 'integrantes',
                    decoration: const InputDecoration(
                      labelText: 'Integrantes',
                      alignLabelWithHint: true,
                      hintText: 'Ejemplo:\nJuan Pérez\nMaría Gómez',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  FormBuilderTextField(
                    name: 'anio',
                    decoration: const InputDecoration(labelText: 'Año'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- BOTÓN ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("VISUALIZAR Y PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.redAccent, // Color similar a tu captura
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    _generarPdf(_formKey.currentState!.value, context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarPdf(
      Map<String, dynamic> formData, BuildContext context) async {
    final pdf = pw.Document();

    // 1. Recuperar datos de la universidad seleccionada
    final uniId = formData['uni_selector'];
    final uniData = universidades.firstWhere((u) => u['id'] == uniId);

    // 2. Cargar Logo
    pw.MemoryImage? imageProvider;
    try {
      // Intenta cargar la imagen desde assets
      final imgData = await rootBundle.load(uniData['logoPath']!);
      imageProvider = pw.MemoryImage(imgData.buffer.asUint8List());
    } catch (e) {
      // Si falla (ej: no has puesto la imagen aún), no crashea
      // ignore: avoid_print
      print("Error cargando imagen: $e");
    }

    // 3. Procesar Integrantes (Separar por enter '\n')
    final rawIntegrantes = formData['integrantes'] as String;
    final listaIntegrantes = rawIntegrantes
        .split('\n') // Separar por salto de línea
        .map((e) => e
            .trim()
            .replaceAll(RegExp(r'^[\W_]+'), '')) // Limpiar viñetas raras
        .where((e) => e.isNotEmpty)
        .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.center, // ESTO CENTRA VERTICALMENTE
            children: [
              // --- CABECERA ---
              pw.Text(uniData['nombre']!,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16),
                  textAlign: pw.TextAlign.center),
              if (uniData['subtitulo']!.isNotEmpty)
                pw.Text(uniData['subtitulo']!,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center),

              pw.SizedBox(height: 5),

              pw.Text(formData['facultad'],
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 13),
                  textAlign: pw.TextAlign.center),

              pw.SizedBox(height: 30), // Espacio antes del logo

              // --- LOGO CORREGIDO Y CENTRADO ---
              pw.Center(
                // <--- 1. El widget Center es la clave
                child: pw.Container(
                  height:
                      200, // Un tamaño un poco más balanceado (200 a veces es mucho)
                  width: 200,
                  alignment: pw.Alignment.center,
                  child: imageProvider != null
                      ? pw.Image(imageProvider, fit: pw.BoxFit.contain)
                      : pw.Text("LOGO",
                          style: const pw.TextStyle(fontSize: 10)),
                ),
              ),

              pw.SizedBox(height: 30),

              // --- CURSO Y TEMA ---
              pw.Text("ASIGNATURA:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(formData['curso'],
                  style: const pw.TextStyle(fontSize: 12)),

              pw.SizedBox(height: 15),

              pw.Text("TEMA:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(formData['tema'],
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16),
                  textAlign: pw.TextAlign.center),

              pw.SizedBox(height: 40),

              // --- INTEGRANTES (SOLUCIÓN DE CENTRADO) ---
              pw.Text("INTEGRANTES:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),

              // Aquí iteramos para crear un texto centrado por cada nombre
              ...listaIntegrantes.map((nombre) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(nombre,
                      textAlign: pw.TextAlign.center, // CENTRADO DEL TEXTO
                      style: const pw.TextStyle(fontSize: 12)),
                );
              }),

              pw.Spacer(), // Empuja lo siguiente al final de la hoja

              // --- PIE DE PÁGINA ---
              pw.Text("Lima - Perú", style: const pw.TextStyle(fontSize: 11)),
              pw.Text(formData['anio'],
                  style: const pw.TextStyle(fontSize: 11)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
