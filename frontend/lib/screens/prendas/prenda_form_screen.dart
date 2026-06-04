import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import 'dart:convert';

class PrendaFormScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? prenda;

  const PrendaFormScreen({super.key, required this.userId, this.prenda});

  @override
  State<PrendaFormScreen> createState() => _PrendaFormScreenState();
}

class _PrendaFormScreenState extends State<PrendaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  String _tipo = 'camiseta';
  String _color = 'negro';
  String _estilo = 'casual';
  String _temporada = 'todo año';
  String? _fotoUrl;
  bool _loading = false;
  bool _uploadingImg = false;
  bool _removingBg = false; // estado quitar fondo

  final _tipos = ['camiseta', 'pantalón', 'vestido', 'chaqueta', 'zapatos',
    'accesorio', 'falda', 'jersey', 'top', 'bolso', 'collar'];
  final _colores = ['negro', 'blanco', 'rojo', 'azul', 'verde', 'amarillo',
    'rosa', 'gris', 'beige', 'naranja', 'morado', 'marrón', 'turquesa'];
  final _estilos = ['casual', 'formal', 'deportivo', 'elegante', 'bohemio',
    'urbano', 'vintage', 'minimalista'];
  final _temporadas = ['verano', 'primavera', 'otoño', 'invierno', 'todo año'];

  bool get _editMode => widget.prenda != null;

  @override
  void initState() {
    super.initState();
    if (_editMode) {
      _nombreCtrl.text = widget.prenda!['nombre'] ?? '';
      _tipo = widget.prenda!['tipo'] ?? 'camiseta';
      _color = widget.prenda!['color'] ?? 'negro';
      _estilo = widget.prenda!['estilo'] ?? 'casual';
      _temporada = widget.prenda!['temporada'] ?? 'todo año';
      _fotoUrl = widget.prenda!['fotoUrl'];
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploadingImg = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ApiService.subirImagen(bytes, file.name);
      if (mounted) setState(() => _fotoUrl = url);

      // Quitar fondo automáticamente al subir
      await _quitarFondo(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir imagen: $e'),
                backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _uploadingImg = false);
    }
  }

  // Quita el fondo y actualiza _fotoUrl con la imagen procesada
  Future<void> _quitarFondo(String url) async {
    setState(() => _removingBg = true);
    try {
      // Sube imagen sin fondo como nueva imagen al servidor
      final base64Result = await ApiService.removeBg(url);
      // Convierte base64 a bytes y sube al servidor para tener URL persistente
      final bytes = base64Decode(base64Result);
      final newUrl = await ApiService.subirImagen(
          bytes, 'nobg_${DateTime.now().millisecondsSinceEpoch}.png');
      if (mounted) setState(() => _fotoUrl = newUrl);
    } catch (_) {
      // Si falla quitar fondo, mantenemos la imagen original — no bloqueamos
    } finally {
      if (mounted) setState(() => _removingBg = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'tipo': _tipo,
      'color': _color,
      'estilo': _estilo,
      'temporada': _temporada,
      'fotoUrl': _fotoUrl,
      'usuario': {'id': widget.userId},
    };

    try {
      if (_editMode) {
        await ApiService.actualizarPrenda(widget.prenda!['id'], data);
      } else {
        await ApiService.crearPrenda(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Editar prenda' : 'Nueva prenda'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              GestureDetector(
                onTap: _uploadingImg || _removingBg ? null : _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _uploadingImg
                      ? _loadingState('Subiendo imagen...')
                      : _removingBg
                      ? _loadingState('Quitando fondo...')
                      : _fotoUrl != null && _fotoUrl!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _fotoUrl!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => _imgHint(),
                    ),
                  )
                      : _imgHint(),
                ),
              ),
              const SizedBox(height: 24),

              _label('NOMBRE'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreCtrl,
                style: GoogleFonts.dmSans(fontSize: 14),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                decoration:
                const InputDecoration(hintText: 'ej. Camiseta azul marinera'),
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('TIPO'),
                      const SizedBox(height: 6),
                      _buildDropdown(_tipos, _tipo,
                              (v) => setState(() => _tipo = v!)),
                    ])),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('COLOR'),
                      const SizedBox(height: 6),
                      _buildDropdown(_colores, _color,
                              (v) => setState(() => _color = v!)),
                    ])),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('ESTILO'),
                      const SizedBox(height: 6),
                      _buildDropdown(_estilos, _estilo,
                              (v) => setState(() => _estilo = v!)),
                    ])),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('TEMPORADA'),
                      const SizedBox(height: 6),
                      _buildDropdown(_temporadas, _temporada,
                              (v) => setState(() => _temporada = v!)),
                    ])),
              ]),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading || _uploadingImg || _removingBg
                      ? null
                      : _submit,
                  child: _loading
                      ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(_editMode ? 'GUARDAR CAMBIOS' : 'AÑADIR PRENDA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingState(String msg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppTheme.accent),
        SizedBox(height: 12),
        Text(msg, style: GoogleFonts.dmSans(
            fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary, letterSpacing: 1));

  Widget _buildDropdown(List<String> items, String value,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary),
          dropdownColor: AppTheme.background,
          items: items.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t, style: GoogleFonts.dmSans(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _imgHint() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_photo_alternate_outlined,
          size: 40, color: AppTheme.textSecondary),
      SizedBox(height: 8),
      Text('Añadir foto (fondo se quitará automáticamente)',
          style: GoogleFonts.dmSans(
              fontSize: 12, color: AppTheme.textSecondary),
          textAlign: TextAlign.center),
    ],
  );
}