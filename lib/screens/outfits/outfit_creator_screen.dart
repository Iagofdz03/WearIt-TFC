import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';

const Map<String, Offset> _defaultPositions = {
  'camiseta':   Offset(110, 60),
  'top':        Offset(110, 60),
  'jersey':     Offset(110, 60),
  'chaqueta':   Offset(100, 40),
  'vestido':    Offset(100, 60),
  'pantalón':   Offset(110, 180),
  'falda':      Offset(110, 180),
  'zapatos':    Offset(115, 300),
  'collar':     Offset(130, 30),
  'accesorio':  Offset(30, 200),
  'bolso':      Offset(20, 180),
};

const Map<String, double> _defaultSizes = {
  'camiseta': 0.7,
  'top':      0.7,
  'jersey':   0.7,
  'chaqueta': 0.78,
  'vestido':  0.85,
  'pantalón': 0.6,
  'falda':    0.6,
  'zapatos':  0.55,
  'collar':   0.35,
  'accesorio':0.32,
  'bolso':    0.30,
};

class _FilterPreset {
  final String name;
  final double brightness, contrast, saturation;
  const _FilterPreset(this.name, this.brightness, this.contrast, this.saturation);
}

const _presets = [
  _FilterPreset('Normal',  1.0, 1.0, 1.0),
  _FilterPreset('Vintage', 0.9, 1.1, 0.7),
  _FilterPreset('B&N',     1.0, 1.0, 0.0),
  _FilterPreset('Cálido',  1.05,1.0, 1.2),
  _FilterPreset('Vívido',  1.1, 1.2, 1.4),
];

class _PlacedItem {
  final Map<String, dynamic> prenda;
  Offset position;
  double scale;

  _PlacedItem({required this.prenda, required this.position, required this.scale});

  String get tipo => (prenda['tipo'] ?? 'accesorio').toString().toLowerCase();
  String get imageUrl => prenda['fotoUrl'] ?? '';
  String get nombre => prenda['nombre'] ?? '';
}

class OutfitCreatorScreen extends StatefulWidget {
  final int userId;
  const OutfitCreatorScreen({super.key, required this.userId});

  @override
  State<OutfitCreatorScreen> createState() => _OutfitCreatorScreenState();
}

class _OutfitCreatorScreenState extends State<OutfitCreatorScreen> {
  List<dynamic> _armario = [];
  bool _loadingArmario = true;
  String _categoriaSeleccionada = 'Tops';
  final List<_PlacedItem> _placed = [];

  double _brightness = 1.0;
  double _contrast   = 1.0;
  double _saturation = 1.0;
  String _presetName = 'Normal';
  bool _showFilters  = false;

  final _nombreCtrl = TextEditingController();
  String _ocasion = 'casual';
  bool _esPublico = false;
  bool _saving = false;

  final Map<String, List<String>> _categorias = {
    'Tops':       ['camiseta', 'top', 'jersey', 'chaqueta'],
    'Pantalones': ['pantalón', 'falda'],
    'Zapatos':    ['zapatos'],
    'Extras':     ['collar', 'bolso', 'accesorio', 'vestido'],
  };

  @override
  void initState() {
    super.initState();
    _loadArmario();
  }

  Future<void> _loadArmario() async {
    try {
      final data = await ApiService.getPrendas(widget.userId);
      if (mounted) setState(() { _armario = data; _loadingArmario = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingArmario = false);
    }
  }

  List<dynamic> get _prendasCategoria {
    final tipos = _categorias[_categoriaSeleccionada] ?? [];
    return _armario.where((p) =>
        tipos.contains((p['tipo'] ?? '').toString().toLowerCase())).toList();
  }

  bool _estaSeleccionada(Map<String, dynamic> prenda) =>
      _placed.any((p) => p.prenda['id'] == prenda['id']);

  void _togglePrenda(Map<String, dynamic> prenda) {
    setState(() {
      if (_estaSeleccionada(prenda)) {
        _placed.removeWhere((p) => p.prenda['id'] == prenda['id']);
      } else {
        final tipo = (prenda['tipo'] ?? 'accesorio').toString().toLowerCase();
        if (!['collar', 'bolso', 'accesorio'].contains(tipo)) {
          final baseTypes = _categorias.entries
              .firstWhere((e) => e.value.contains(tipo),
              orElse: () => const MapEntry('', []))
              .value;
          _placed.removeWhere((p) => baseTypes.contains(p.tipo));
        }
        _placed.add(_PlacedItem(
          prenda: prenda,
          position: _defaultPositions[tipo] ?? const Offset(100, 150),
          scale: _defaultSizes[tipo] ?? 0.5,
        ));
      }
    });
  }

  void _applyPreset(_FilterPreset p) {
    setState(() {
      _presetName  = p.name;
      _brightness  = p.brightness;
      _contrast    = p.contrast;
      _saturation  = p.saturation;
    });
  }

  ColorFilter _buildColorFilter() {
    final b = _brightness;
    final c = _contrast;
    final s = _saturation;
    final sr = (1 - s) * 0.2126;
    final sg = (1 - s) * 0.7152;
    final sb = (1 - s) * 0.0722;
    final t = (1 - c) / 2;
    return ColorFilter.matrix([
      c*(sr+s)*b, c*sg*b,     c*sb*b,     0, t*255,
      c*sr*b,     c*(sg+s)*b, c*sb*b,     0, t*255,
      c*sr*b,     c*sg*b,     c*(sb+s)*b, 0, t*255,
      0,          0,          0,          1, 0,
    ]);
  }

  Future<void> _guardarOutfit() async {
    if (_placed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añade al menos una prenda'),
              backgroundColor: AppTheme.error));
      return;
    }
    if (_nombreCtrl.text.trim().isEmpty) {
      _showNombreDialog();
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.crearOutfit({
        'nombre': _nombreCtrl.text.trim(),
        'ocasion': _ocasion,
        'esPublico': _esPublico,
        'usuario': {'id': widget.userId},
        'prendas': _placed.map((p) => {'id': p.prenda['id']}).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Outfit guardado!'),
                backgroundColor: AppTheme.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showNombreDialog() {
    // Reset estado del switch al abrir el diálogo
    bool dialogPublico = _esPublico;
    String dialogOcasion = _ocasion;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('Guardar outfit',
              style: GoogleFonts.cormorant(fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                autofocus: true,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: const InputDecoration(hintText: 'ej. Look del lunes'),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('Ocasión:', style: GoogleFonts.dmSans(fontSize: 13)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: dialogOcasion,
                  dropdownColor: AppTheme.background,
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary),
                  items: ['casual', 'trabajo', 'fiesta', 'deporte', 'formal']
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => dialogOcasion = v!),
                ),
              ]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Público', style: GoogleFonts.dmSans(fontSize: 13)),
                  Switch(
                    value: dialogPublico,
                    onChanged: (v) => setDialogState(() => dialogPublico = v),
                    activeColor: AppTheme.accent,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar',
                    style: GoogleFonts.dmSans(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _esPublico = dialogPublico;
                  _ocasion = dialogOcasion;
                });
                Navigator.pop(ctx);
                _guardarOutfit();
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Crear Outfit'),
        actions: [
          if (_placed.isNotEmpty)
            TextButton(
              onPressed: _saving ? null : _showNombreDialog,
              child: _saving
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                  : Text('GUARDAR',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.accent, letterSpacing: 1)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Canvas arriba ────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: _buildCanvas(),
          ),

          // ─── Filtros ──────────────────────────────────────────────────────
          _buildFilterBar(),

          const Divider(height: 1),

          // ─── Selector prendas abajo ───────────────────────────────────────
          Expanded(
            flex: 4,
            child: _buildPrendaSelector(),
          ),
        ],
      ),
    );
  }

  // ─── Canvas ──────────────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Stack(
        children: [
          // Silueta fondo
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Icon(Icons.accessibility_new,
                  size: 220, color: AppTheme.textPrimary),
            ),
          ),
          // Texto vacío
          if (_placed.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.style_outlined, size: 40,
                      color: AppTheme.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Selecciona prendas abajo',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          // Prendas arrastrables — SIN etiquetas
          ..._placed.map((item) => _buildDraggableItem(item)),
          // Botón reset
          if (_placed.isNotEmpty)
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _placed.clear()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.refresh, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('Reset', style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppTheme.textSecondary)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(_PlacedItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            item.position = Offset(
              item.position.dx + d.delta.dx,
              item.position.dy + d.delta.dy,
            );
          });
        },
        onLongPress: () => _showItemOptions(item),
        child: ColorFiltered(
          colorFilter: _buildColorFilter(),
          child: SizedBox(
            width: 130 * item.scale,
            height: 130 * item.scale,
            child: item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => _prendaPlaceholder(item.tipo),
            )
                : _prendaPlaceholder(item.tipo),
          ),
        ),
      ),
    );
  }

  void _showItemOptions(_PlacedItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.nombre,
                  style: GoogleFonts.cormorant(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Arrastra para mover · Mantén para opciones',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textSecondary)),
              const Divider(height: 24),
              Text('Tamaño: ${(item.scale * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
              Slider(
                value: item.scale,
                min: 0.2, max: 1.4,
                activeColor: AppTheme.accent,
                onChanged: (v) => setSheet(() => item.scale = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _placed.removeWhere(
                            (p) => p.prenda['id'] == item.prenda['id']));
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text('Quitar prenda',
                      style: GoogleFonts.dmSans(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Barra de filtros ────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.palette_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('Filtros', style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
                const Spacer(),
                Icon(_showFilters ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: AppTheme.textSecondary),
              ]),
            ),
          ),
          if (_showFilters) ...[
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _presets.length,
                itemBuilder: (_, i) {
                  final p = _presets[i];
                  final sel = _presetName == p.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _applyPreset(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: sel ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Text(p.name,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: sel ? AppTheme.background : AppTheme.textPrimary,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ─── Selector prendas ────────────────────────────────────────────────────
  Widget _buildPrendaSelector() {
    return Column(
      children: [
        // Tabs categorías
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border))),
          child: Row(
            children: _categorias.keys.map((cat) {
              final sel = _categoriaSeleccionada == cat;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _categoriaSeleccionada = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: sel ? AppTheme.primary : Colors.transparent,
                        width: 2,
                      )),
                    ),
                    child: Text(cat,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? AppTheme.primary : AppTheme.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Lista horizontal de prendas
        Expanded(
          child: _loadingArmario
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : _prendasCategoria.isEmpty
              ? Center(
              child: Text('Sin prendas en esta categoría',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textSecondary)))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            itemCount: _prendasCategoria.length,
            itemBuilder: (ctx, i) => _buildPrendaCard(_prendasCategoria[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildPrendaCard(Map<String, dynamic> prenda) {
    final selected = _estaSeleccionada(prenda);
    return GestureDetector(
      onTap: () => _togglePrenda(prenda),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.05) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                    child: prenda['fotoUrl'] != null && prenda['fotoUrl'].isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: prenda['fotoUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (_, __, ___) =>
                          _prendaPlaceholder(prenda['tipo'] ?? ''),
                    )
                        : _prendaPlaceholder(prenda['tipo'] ?? ''),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Text(
                    prenda['nombre'] ?? '',
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _prendaPlaceholder(String tipo) {
    return Container(
      color: AppTheme.border,
      child: Center(child: Icon(_tipoIcon(tipo),
          size: 28, color: AppTheme.textSecondary)),
    );
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'zapatos': return Icons.directions_walk;
      case 'collar':
      case 'accesorio': return Icons.diamond_outlined;
      case 'bolso': return Icons.shopping_bag_outlined;
      default: return Icons.checkroom_outlined;
    }
  }
}