import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:metadata_fetch/metadata_fetch.dart'; // <--- IMPORTANTE

class ApaGeneratorScreen extends StatefulWidget {
  const ApaGeneratorScreen({super.key});

  @override
  State<ApaGeneratorScreen> createState() => _ApaGeneratorScreenState();
}

class _ApaGeneratorScreenState extends State<ApaGeneratorScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String _resultadoApa = "";
  bool _isLoading = false; // Para mostrar un spinner mientras carga

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generador APA 7 Pro 🤖"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. BARRA DE AUTO-COMPLETADO ---
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  const Icon(Icons.link, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Pega el link aquí para auto-rellenar...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _extraerDatosDesdeUrl(value),
                    ),
                  ),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search,
                              color: Colors.blueAccent),
                          onPressed: () {
                            // Aquí capturamos lo que haya en el campo si queremos botón manual
                            // Por simplicidad, sugiero usar el onSubmitted o conectar un controller
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              " *La extracción depende de los metadatos de la página.",
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // --- 2. FORMULARIO ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                        'autor', 'Autor', 'Apellido, N. (Opcional)'),
                    const SizedBox(height: 10),
                    _buildTextField('anio', 'Año', 'Ej: 2024'),
                    const SizedBox(height: 10),
                    _buildTextField(
                        'titulo', 'Título del artículo', 'Se llenará solo...'),
                    const SizedBox(height: 10),
                    _buildTextField('fuente', 'Fuente / Sitio Web',
                        'Ej: Wikipedia, BBC...'),
                    const SizedBox(height: 10),
                    _buildTextField('url', 'URL Final', 'https://...'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- BOTÓN GENERAR ---
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: const Text("GENERAR CITA"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _generarCita,
            ),

            // --- RESULTADO (Igual que antes) ---
            if (_resultadoApa.isNotEmpty) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: SelectableText(_resultadoApa,
                    style: const TextStyle(fontSize: 16)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text("Copiar"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _resultadoApa));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Copiado")));
                },
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE EXTRACCIÓN REAL ---
  Future<void> _extraerDatosDesdeUrl(String url) async {
    if (url.isEmpty) return;
    if (!url.startsWith("http")) url = "https://$url";

    setState(() => _isLoading = true);

    try {
      var data = await MetadataFetch.extract(url);

      // --- TRUCOS NUEVOS ---

      // 1. Intentar sacar el AÑO de la URL (Busca 4 números seguidos, ej: /2025/)
      String foundYear = '';
      final yearRegex = RegExp(r'/(\d{4})/');
      final match = yearRegex.firstMatch(url);
      if (match != null) {
        foundYear = match.group(1) ?? '';
      }

      // 2. Intentar adivinar la FUENTE desde el dominio (ej: cnn.com -> CNN)
      String foundSource = '';
      try {
        final uri = Uri.parse(url);
        // Toma la parte principal del dominio (ej: 'cnnespanol' o 'wikipedia')
        String host = uri.host.replaceFirst('www.', '');
        foundSource = host.split('.').first.toUpperCase();
        // ignore: empty_catches
      } catch (e) {}

      // ---------------------

      if (data != null) {
        _formKey.currentState?.patchValue({
          'titulo': data.title ?? '',
          'anio': foundYear, // <--- ¡Aquí inyectamos el año encontrado!
          'fuente': foundSource, // <--- ¡Y aquí la fuente adivinada!
          'url': url,
          'image': data.image,
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Título encontrado: ${data.title}")),
        );
      } else {
        // ... (resto igual)
      }
    } catch (e) {
      // ... (resto igual)
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String name, String label, String hint) {
    return FormBuilderTextField(
      name: name,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        labelStyle: const TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _generarCita() {
    _formKey.currentState?.save();
    final val = _formKey.currentState?.value;
    if (val == null) return;

    // Lógica APA simple
    String autor =
        val['autor']?.toString().isNotEmpty == true ? "${val['autor']} " : "";
    String fecha = val['anio']?.toString().isNotEmpty == true
        ? "(${val['anio']}). "
        : "(s.f.). ";
    String titulo = val['titulo']?.toString().isNotEmpty == true
        ? "${val['titulo']}. "
        : "";
    String fuente = val['fuente']?.toString().isNotEmpty == true
        ? "${val['fuente']}. "
        : "";
    String url = val['url'] ?? "";

    setState(() {
      _resultadoApa = "$autor$fecha$titulo$fuente$url";
    });
  }
}
