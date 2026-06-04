import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/outfit_card.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  List<dynamic> _sugerencias = [];
  bool _loading = false;
  int? _userId;
  String? _ciudad;
  Map<String, dynamic>? _tiempo;
  final _ciudadCtrl = TextEditingController();
  String _ocasionFiltro = '';

  final _ocasiones = ['', 'casual', 'formal', 'deportivo', 'elegante'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await _cargarSugerencias();
  }

  Future<void> _cargarSugerencias() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      List<dynamic> data;
      if (_ciudad != null && _ciudad!.isNotEmpty) {
        data = await ApiService.getSugerenciasTiempo(
            _userId!, _ocasionFiltro.isNotEmpty ? _ocasionFiltro : null,
            _tiempo?['temporadaRecomendada']);
      } else {
        data = await ApiService.getSugerencias(_userId!);
      }
      if (mounted) setState(() => _sugerencias = data);
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

  Future<void> _cargarConTiempo() async {
    if (_ciudadCtrl.text.trim().isEmpty) return;
    setState(() { _ciudad = _ciudadCtrl.text.trim(); _tiempo = null; });
    try {
      final t = await ApiService.getTiempo(_ciudad!);
      if (mounted) setState(() => _tiempo = t);
      await _cargarSugerencias();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ideas de outfit')),
      body: Column(
        children: [
          // Panel de tiempo
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sugerir según el tiempo',
                    style: GoogleFonts.cormorant(fontSize: 18, fontWeight: FontWeight.w500)),
                SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ciudadCtrl,
                      style: GoogleFonts.dmSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ciudad (ej. Madrid)',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 16),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _cargarConTiempo(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _cargarConTiempo,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    child: Icon(Icons.search, size: 18),
                  ),
                ]),
                if (_tiempo != null) ...[
                  SizedBox(height: 12),
                  Row(children: [
                    Image.network(_tiempo!['icono'] ?? '',
                        width: 36, height: 36, errorBuilder: (_, __, ___) => SizedBox()),
                    SizedBox(width: 8),
                    Text(
                      '${_tiempo!['temperatura']?.toStringAsFixed(0)}°C en ${_tiempo!['ciudad']}',
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_tiempo!['temporadaRecomendada'] ?? '',
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          // Filtro ocasión
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ocasiones.length,
              itemBuilder: (ctx, i) {
                final oc = _ocasiones[i];
                final labels = {'': 'Todas', 'casual': 'Casual', 'formal': 'Formal',
                  'deportivo': 'Deporte', 'elegante': 'Elegante'};
                final sel = _ocasionFiltro == oc;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labels[oc]!),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => _ocasionFiltro = oc);
                      _cargarSugerencias();
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.cardBg,
                    labelStyle: GoogleFonts.dmSans(fontSize: 11,
                        color: sel ? AppTheme.background : AppTheme.textPrimary),
                    side: BorderSide(color: sel ? AppTheme.primary : AppTheme.border),
                    checkmarkColor: AppTheme.background,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),

          // Sugerencias
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _sugerencias.isEmpty
                ? _buildEmpty()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sugerencias.length,
              itemBuilder: (ctx, i) => _buildSugerenciaCard(_sugerencias[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaCard(Map<String, dynamic> sug) {
    final prendas = (sug['prendas'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(children: [
              Icon(Icons.auto_awesome, color: AppTheme.accentLight, size: 18),
              SizedBox(width: 8),
              Text(sug['nombre'] ?? '',
                  style: GoogleFonts.cormorant(
                      fontSize: 18, fontWeight: FontWeight.w400, color: AppTheme.background)),
            ]),
          ),
          // Prendas
          if (prendas.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: prendas.length,
                itemBuilder: (ctx, i) {
                  final p = prendas[i];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checkroom_outlined, size: 16, color: AppTheme.textSecondary),
                        SizedBox(height: 2),
                        Text(p['nombre'] ?? '',
                            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(p['color'] ?? '',
                            style: GoogleFonts.dmSans(fontSize: 9, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Explicación
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(sug['explicacion'] ?? '',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 64,
              color: AppTheme.textSecondary.withOpacity(0.3)),
          SizedBox(height: 16),
          Text('Sin sugerencias', style: GoogleFonts.cormorant(
              fontSize: 22, color: AppTheme.textSecondary)),
          SizedBox(height: 8),
          Text('Añade prendas a tu armario para recibir ideas',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}