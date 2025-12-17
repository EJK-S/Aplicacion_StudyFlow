import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LacceiToolScreen extends StatefulWidget {
  const LacceiToolScreen({super.key});

  @override
  State<LacceiToolScreen> createState() => _LacceiToolScreenState();
}

class _LacceiToolScreenState extends State<LacceiToolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Link oficial actualizado
  final String _officialDocUrl =
      "https://www.laccei.org/LACCEI_uploads/Template_LACCEI-2026-Antes_revision-SPANISH-Fase01.doc";

  // Estado para la calculadora
  final _wordCountController = TextEditingController();
  String _pageEstimation = "";

  // Estado para el Checklist (Basado en tu documento subido)
  // Las reglas se extrajeron de: [cite: 13, 15, 21, 36]
  final List<Map<String, dynamic>> _rules = [
    {
      "title": "Tamaño Papel",
      "desc": "Carta (Letter) 8.5\" x 11\" (216x279mm)",
      "isChecked": false
    },
    {
      "title": "Márgenes",
      "desc": "Sup: 1.9cm | Inf: 2.54cm | Lados: 1.59cm",
      "isChecked": false
    },
    {
      "title": "Fuente",
      "desc": "Times New Roman para todo el documento",
      "isChecked": false
    },
    {
      "title": "Título",
      "desc": "24 pts, Centrado, NO negrita (Regular)",
      "isChecked": false
    },
    {
      "title": "Autores",
      "desc": "11 pts, Centrado bajo el título",
      "isChecked": false
    },
    {
      "title": "Cuerpo",
      "desc": "10 pts, Justificado, Espacio simple, 2 columnas",
      "isChecked": false
    },
    {
      "title": "Referencias",
      "desc": "Formato IEEE con corchetes [1]",
      "isChecked": false
    },
    {
      "title": "Figuras",
      "desc": "Títulos CENTRADOS en la parte inferior",
      "isChecked": false
    },
    {
      "title": "Tablas",
      "desc": "Títulos CENTRADOS en la parte superior (Núm Romanos)",
      "isChecked": false
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Lógica de cálculo (Aprox 400-500 palabras por página en doble columna IEEE)
  void _calculatePages() {
    if (_wordCountController.text.isEmpty) return;
    final words = int.tryParse(_wordCountController.text);
    if (words == null) return;

    // Estimación conservadora: 450 palabras por página (incluyendo espacio para imágenes)
    final pages = (words / 450).ceil();

    // Reglas de límites
    String status = "";

    if (pages < 2) {
      status = "Muy corto (Mínimo 2 págs para WP)";
    } else if (pages >= 2 && pages <= 5) {
      status = "Rango: Work in Progress (WP)";
    } else if (pages > 5 && pages <= 10) {
      status = "Rango: Full Paper (FP)";
    } else {
      status = "¡Cuidado! Excede el límite de 10 págs";
    }

    setState(() {
      _pageEstimation = "Aprox. $pages páginas\n$status";
    });
    FocusScope.of(context).unfocus(); // Cerrar teclado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kit LACCEI 2026 📄"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Checklist ✅", icon: Icon(Icons.playlist_add_check)),
            Tab(text: "Utilidades 🧮", icon: Icon(Icons.build_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: CHECKLIST INTERACTIVO
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _rules.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, i) {
              final rule = _rules[i];
              return CheckboxListTile(
                activeColor: Colors.blueAccent,
                title: Text(rule['title'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: rule['isChecked']
                            ? TextDecoration.lineThrough
                            : null,
                        color: rule['isChecked'] ? Colors.grey : null)),
                subtitle: Text(rule['desc']),
                value: rule['isChecked'],
                onChanged: (val) {
                  setState(() {
                    rule['isChecked'] = val;
                  });
                },
              );
            },
          ),

          // PESTAÑA 2: UTILIDADES (Descarga + Calculadora)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TARJETA DE DESCARGA
                Card(
                  color: Colors.blueGrey.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_download,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 10),
                        const Text("Plantilla Oficial Word (.doc)",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 5),
                        const Text("LACCEI 2026 - Fase 01",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _officialDocUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Enlace copiado al portapapeles 📋")));
                          },
                          icon: const Icon(Icons.link),
                          label: const Text("COPIAR ENLACE DE DESCARGA"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Text("Estimador de Páginas 📏",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Basado en formato doble columna IEEE",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),

                // 2. CALCULADORA
                TextField(
                  controller: _wordCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Número de palabras (Word Count)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.text_fields),
                      helperText: "Excluye referencias para mayor precisión"),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _calculatePages,
                  child: const Text("CALCULAR EXTENSIÓN"),
                ),
                const SizedBox(height: 20),

                if (_pageEstimation.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent)),
                    child: Text(
                      _pageEstimation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}
