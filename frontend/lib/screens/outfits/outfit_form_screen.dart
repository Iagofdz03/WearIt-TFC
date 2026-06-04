import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';

class OutfitFormScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? outfit;

  const OutfitFormScreen({super.key, required this.userId, this.outfit});

  @override
  State<OutfitFormScreen> createState() => _OutfitFormScreenState();
}

class _OutfitFormScreenState extends State<OutfitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  String _ocasion = 'casual';
  bool _esPublico = false;
  List<dynamic> _prendas = [];
  List<int> _prendasSeleccionadas = [];
  bool _loading = false;
  bool _loadingPrendas = true;

  final _ocasiones = ['casual', 'trabajo', 'fiesta', 'deporte', 'formal'];
  bool get _editMode => widget.outfit != null;

  @override
  void initState() {
    super.initState();
    if (_editMode) {
      _nombreCtrl.text = widget.outfit!['nombre'] ?? '';
      _ocasion = widget.outfit!['ocasion'] ?? 'casual';
      _esPublico = widget.outfit!['esPublico'] ?? false;
      _prendasSeleccionadas = ((widget.outfit!['prendas'] as List?) ?? [])
          .map<int>((p) => p['id'] as int)
          .toList();
    }
    _loadPrendas();
  }

  Future<void> _loadPrendas() async {
    try {
      final data = await ApiService.getPrendas(widget.userId);
      if (mounted) setState(() { _prendas = data; _loadingPrendas = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPrendas = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_prendasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecciona al menos una prenda'),
              backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _loading = true);

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'ocasion': _ocasion,
      'esPublico': _esPublico,
      'usuario': {'id': widget.userId},
      'prendas': _prendasSeleccionadas.map((id) => {'id': id}).toList(),
    };

    try {
      if (_editMode) {
        await ApiService.actualizarOutfit(widget.outfit!['id'], data);
      } else {
        await ApiService.crearOutfit(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')),
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
        title: Text(_editMode ? 'Editar outfit' : 'Nuevo outfit'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('NOMBRE DEL OUTFIT'),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: _nombreCtrl,
                      style: GoogleFonts.dmSans(fontSize: 14),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                      decoration: const InputDecoration(hintText: 'ej. Look oficina lunes'),
                    ),
                    SizedBox(height: 16),

                    _label('OCASIÓN'),
                    SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _ocasion,
                          isExpanded: true,
                          style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary),
                          dropdownColor: AppTheme.background,
                          items: _ocasiones.map((o) => DropdownMenuItem(
                            value: o,
                            child: Text(o, style: GoogleFonts.dmSans(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => setState(() => _ocasion = v!),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hacer público',
                            style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary)),
                        Switch(
                          value: _esPublico,
                          onChanged: (v) => setState(() => _esPublico = v),
                          activeColor: AppTheme.accent,
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    _label('PRENDAS (${_prendasSeleccionadas.length} seleccionadas)'),
                    SizedBox(height: 12),

                    _loadingPrendas
                        ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
                        : _prendas.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'No tienes prendas. Añade primero prendas a tu armario.',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _prendas.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final prenda = _prendas[i];
                        final selected = _prendasSeleccionadas
                            .contains(prenda['id'] as int);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _prendasSeleccionadas.add(prenda['id']);
                              } else {
                                _prendasSeleccionadas.remove(prenda['id']);
                              }
                            });
                          },
                          title: Text(prenda['nombre'] ?? '',
                              style: GoogleFonts.dmSans(fontSize: 13)),
                          subtitle: Text(
                              '${prenda['tipo'] ?? ''} · ${prenda['color'] ?? ''} · ${prenda['temporada'] ?? ''}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                          activeColor: AppTheme.accent,
                          checkColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Botón fijo abajo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
                color: AppTheme.background,
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_editMode ? 'GUARDAR CAMBIOS' : 'CREAR OUTFIT'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary, letterSpacing: 1));
}