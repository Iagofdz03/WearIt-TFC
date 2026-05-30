import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import 'dart:convert';

// ─── Posiciones por defecto ───────────────────────────────────────────────────
const Map<String, Offset> _defaultPositions = {
  'camiseta':  Offset(110, 60),
  'top':       Offset(110, 60),
  'jersey':    Offset(110, 60),
  'chaqueta':  Offset(100, 40),
  'vestido':   Offset(100, 60),
  'pantalón':  Offset(110, 180),
  'falda':     Offset(110, 180),
  'zapatos':   Offset(115, 300),
  'collar':    Offset(130, 30),
  'accesorio': Offset(30, 200),
  'bolso':     Offset(20, 180),
};

const Map<String, double> _defaultSizes = {
  'camiseta':  0.7,
  'top':       0.7,
  'jersey':    0.7,
  'chaqueta':  0.78,
  'vestido':   0.85,
  'pantalón':  0.6,
  'falda':     0.6,
  'zapatos':   0.55,
  'collar':    0.35,
  'accesorio': 0.32,
  'bolso':     0.30,
};

// ─── Presets de filtro ────────────────────────────────────────────────────────
class _FilterPreset {
  final String name;
  final double brightness, contrast, saturation;
  const _FilterPreset(this.name, this.brightness, this.contrast, this.saturation);
}

const _presets = [
  _FilterPreset('Normal',  1.0, 1.0, 1.0),
  _FilterPreset('Vintage', 0.9, 1.1, 0.7),
  _FilterPreset('B&N',     1.0, 1.0, 0.0),
  _FilterPreset('Sepia',   0.95,1.05,0.5),
  _FilterPreset('Cálido',  1.05,1.0, 1.2),
  _FilterPreset('Vívido',  1.1, 1.2, 1.4),
];

// ─── Modelo de prenda colocada ────────────────────────────────────────────────
class _PlacedItem {
  final Map<String, dynamic> prenda;
  Offset position;
  // ValueNotifier para posición — evita setState en cada frame de arrastre
  late ValueNotifier<Offset> positionNotifier;
  double scale;
  double brightness;
  double contrast;
  double saturation;
  bool removeBgApplied;
  String? processedUrl;
  bool removingBg;

  _PlacedItem({
    required this.prenda,
    required this.position,
    required this.scale,
    this.brightness = 1.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.removeBgApplied = false,
    this.processedUrl,
    this.removingBg = false,
  }) {
    positionNotifier = ValueNotifier<Offset>(position);
  }

  void dispose() {
    positionNotifier.dispose();
  }

  String get tipo => (prenda['tipo'] ?? 'accesorio').toString().toLowerCase();
  String get imageUrl => processedUrl ?? prenda['fotoUrl'] ?? '';
  String get nombre => prenda['nombre'] ?? '';

  ColorFilter buildColorFilter() {
    final b = brightness;
    final c = contrast;
    final s = saturation;
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
}

// ─── Screen ───────────────────────────────────────────────────────────────────
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

  final _nombreCtrl = TextEditingController();
  String _ocasion = 'casual';
  bool _esPublico = false;
  bool _saving = false;

  final Map<String, List<String>> _categorias = {
    'Tops': ['camiseta', 'top', 'jersey', 'chaqueta'],
    'Pantalones': ['pantalón', 'falda', 'vestido'],
    'Zapatos': ['zapatos'],
    'Extras': ['collar', 'bolso', 'accesorio'],
  };

  @override
  void initState() {
    super.initState();
    _loadArmario();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    // Libera todos los ValueNotifier de las prendas colocadas
    for (final item in _placed) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadArmario() async {
    try {
      final data = await ApiService.getPrendas(widget.userId);
      if (mounted) setState(() {
        _armario = data;
        _loadingArmario = false;
      });
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
        // Reemplaza prendas del mismo grupo (no accesorios)
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

  // ─── Remove BG ─────────────────────────────────────────────────────────────
  Future<void> _removeBg(_PlacedItem item) async {
    if (item.imageUrl.isEmpty) return;
    setState(() => item.removingBg = true);
    try {
      final result = await ApiService.removeBg(item.imageUrl);
      setState(() {
        item.processedUrl = result;
        item.removeBgApplied = true;
        item.removingBg = false;
      });
    } catch (e) {
      setState(() => item.removingBg = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al quitar fondo: $e'),
                backgroundColor: AppTheme.error));
      }
    }
  }

  // ─── Guardar ───────────────────────────────────────────────────────────────
  Future<void> _guardarOutfit() async {
    if (_placed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añade al menos una prenda'),
              backgroundColor: AppTheme.error));
      return;
    }
    if (_nombreCtrl.text
        .trim()
        .isEmpty) {
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
    bool dialogPublico = _esPublico;
    String dialogOcasion = _ocasion;
    showDialog(
      context: context,
      builder: (ctx) =>
          StatefulBuilder(
            builder: (ctx, setDialogState) =>
                AlertDialog(
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
                        decoration: const InputDecoration(
                            hintText: 'ej. Look del lunes'),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Text('Ocasión:',
                            style: GoogleFonts.dmSans(fontSize: 13)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: dialogOcasion,
                          dropdownColor: AppTheme.background,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppTheme.textPrimary),
                          items: [
                            'casual',
                            'trabajo',
                            'fiesta',
                            'deporte',
                            'formal'
                          ]
                              .map((o) =>
                              DropdownMenuItem(value: o, child: Text(o)))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => dialogOcasion = v!),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Público',
                              style: GoogleFonts.dmSans(fontSize: 13)),
                          Switch(
                            value: dialogPublico,
                            onChanged: (v) =>
                                setDialogState(() => dialogPublico = v),
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
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textSecondary))),
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

  // ─── BUILD ─────────────────────────────────────────────────────────────────
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent))
                  : Text('GUARDAR',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.accent, letterSpacing: 1)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 5, child: _buildCanvas()),
          const Divider(height: 1),
          Expanded(flex: 4, child: _buildPrendaSelector()),
        ],
      ),
    );
  }

  // ─── Canvas ────────────────────────────────────────────────────────────────
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
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Icon(Icons.accessibility_new,
                  size: 220, color: AppTheme.textPrimary),
            ),
          ),
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
          ..._placed.map((item) =>
              _DraggablePrenda(
                key: ValueKey(item.prenda['id']),
                item: item,
                onLongPress: () => _showItemOptions(item),
              )),
          if (_placed.isNotEmpty)
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _placed.clear()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.refresh,
                        size: 13, color: AppTheme.textSecondary),
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
    return ValueListenableBuilder<Offset>(
      valueListenable: item.positionNotifier,
      builder: (_, pos, __) =>
          Positioned(
            left: pos.dx,
            top: pos.dy,
            child: GestureDetector(
              onPanUpdate: (d) {
                // Solo actualiza el notifier — no llama a setState
                item.positionNotifier.value = Offset(
                  item.positionNotifier.value.dx + d.delta.dx,
                  item.positionNotifier.value.dy + d.delta.dy,
                );
              },
              onPanEnd: (_) {
                // Sincroniza position al soltar para que el modelo quede actualizado
                setState(() => item.position = item.positionNotifier.value);
              },
              onLongPress: () => _showItemOptions(item),
              child: item.removingBg
                  ? SizedBox(
                  width: 130 * item.scale,
                  height: 130 * item.scale,
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2)))
                  : ColorFiltered(
                colorFilter: item.buildColorFilter(),
                child: SizedBox(
                  width: 130 * item.scale,
                  height: 130 * item.scale,
                  child: item.removeBgApplied && item.processedUrl != null
                      ? Image.memory(
                    base64Decode(item.processedUrl!),
                    fit: BoxFit.contain,
                  )
                      : item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        _prendaPlaceholder(item.tipo),
                  )
                      : _prendaPlaceholder(item.tipo),
                ),
              ),
            ),
          ),
    );
  }

  // ─── Bottom sheet opciones prenda ──────────────────────────────────────────
  void _showItemOptions(_PlacedItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) =>
          StatefulBuilder(
            builder: (ctx, setSheet) =>
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nombre,
                          style: GoogleFonts.cormorant(
                              fontSize: 20, fontWeight: FontWeight.w500)),
                      Text('Mantén pulsado para abrir opciones',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppTheme.textSecondary)),
                      const Divider(height: 24),

                      // Tamaño
                      Text('Tamaño: ${(item.scale * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Slider(
                        value: item.scale,
                        min: 0.2,
                        max: 1.4,
                        activeColor: AppTheme.accent,
                        onChanged: (v) =>
                            setSheet(() {
                              item.scale = v;
                              setState(() {});
                            }),
                      ),

                      const Divider(height: 16),

                      // Filtros — presets rápidos
                      Text('Filtros',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _presets.map((p) =>
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () =>
                                      setSheet(() {
                                        item.brightness = p.brightness;
                                        item.contrast = p.contrast;
                                        item.saturation = p.saturation;
                                        setState(() {});
                                      }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppTheme.border),
                                    ),
                                    child: Text(p.name,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 11)),
                                  ),
                                ),
                              )).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Sliders individuales
                      _sheetSlider('Brillo', item.brightness, 0.5, 1.5, (v) {
                        setSheet(() {
                          item.brightness = v;
                          setState(() {});
                        });
                      }),
                      _sheetSlider('Contraste', item.contrast, 0.5, 1.5, (v) {
                        setSheet(() {
                          item.contrast = v;
                          setState(() {});
                        });
                      }),
                      _sheetSlider(
                          'Saturación', item.saturation, 0.0, 2.0, (v) {
                        setSheet(() {
                          item.saturation = v;
                          setState(() {});
                        });
                      }),

                      const Divider(height: 20),

                      // Acciones
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: item.removeBgApplied ? null : () {
                              Navigator.pop(ctx);
                              _removeBg(item);
                            },
                            icon: const Icon(Icons.auto_fix_high, size: 15),
                            label: Text(
                                item.removeBgApplied
                                    ? 'Fondo quitado'
                                    : 'Quitar fondo',
                                style: GoogleFonts.dmSans(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.border)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() =>
                                  _placed.removeWhere(
                                          (p) =>
                                      p.prenda['id'] == item.prenda['id']));
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.delete_outline, size: 15),
                            label: Text('Quitar',
                                style: GoogleFonts.dmSans(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _sheetSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(children: [
      SizedBox(
        width: 82,
        child: Text('$label\n${(value * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.dmSans(
                fontSize: 10, color: AppTheme.textSecondary)),
      ),
      Expanded(
        child: Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppTheme.accent,
          inactiveColor: AppTheme.border,
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  // ─── Selector prendas ──────────────────────────────────────────────────────
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
                  onTap: () =>
                      setState(() => _categoriaSeleccionada = cat),
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
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: sel
                                ? AppTheme.primary
                                : AppTheme.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Lista horizontal de prendas — FIX: altura suficiente para no cortar
        Expanded(
          child: _loadingArmario
              ? const Center(child: CircularProgressIndicator(
              color: AppTheme.accent))
              : _prendasCategoria.isEmpty
              ? Center(
              child: Text('Sin prendas en esta categoría',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary)))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            itemCount: _prendasCategoria.length,
            itemBuilder: (ctx, i) =>
                _buildPrendaCard(_prendasCategoria[i]),
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
        // FIX: más ancho y proporción correcta para no cortar la foto
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.05)
              : AppTheme.cardBg,
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
                // FIX: imagen ocupa el 80% de la altura disponible sin recortar
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(9)),
                    child: prenda['fotoUrl'] != null &&
                        prenda['fotoUrl'].isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: prenda['fotoUrl'],
                      // BoxFit.contain en vez de cover — no recorta
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorWidget: (_, __, ___) =>
                          _prendaPlaceholder(prenda['tipo'] ?? ''),
                    )
                        : _prendaPlaceholder(prenda['tipo'] ?? ''),
                  ),
                ),
                // Nombre abajo
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    child: Text(
                      prenda['nombre'] ?? '',
                      style: GoogleFonts.dmSans(
                          fontSize: 10, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 12),
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
      case 'zapatos':
        return Icons.directions_walk;
      case 'collar':
      case 'accesorio':
        return Icons.diamond_outlined;
      case 'bolso':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.checkroom_outlined;
    }
  }
}

class _DraggablePrenda extends StatefulWidget {
  final _PlacedItem item;
  final VoidCallback onLongPress;

  const _DraggablePrenda({
    super.key,
    required this.item,
    required this.onLongPress,
  });

  @override
  State<_DraggablePrenda> createState() => _DraggablePrendaState();
}

class _DraggablePrendaState extends State<_DraggablePrenda> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.item.position;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final size = 130 * item.scale;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      // RepaintBoundary aisla este widget del repaint del padre
      child: RepaintBoundary(
        child: GestureDetector(
          onPanUpdate: (d) {
            setState(() {
              _position = Offset(
                _position.dx + d.delta.dx,
                _position.dy + d.delta.dy,
              );
              item.position = _position;
            });
          },
          onLongPress: widget.onLongPress,
          child: item.removingBg
              ? SizedBox(
              width: size, height: size,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2)))
              : ColorFiltered(
            colorFilter: item.buildColorFilter(),
            child: SizedBox(
              width: size,
              height: size,
              child: item.removeBgApplied && item.processedUrl != null
                  ? Image.memory(
                base64Decode(item.processedUrl!),
                fit: BoxFit.contain,
                gaplessPlayback: true, // evita parpadeo al rebuild
              )
                  : item.imageUrl.isNotEmpty
                  ? Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
                gaplessPlayback: true, // clave anti-parpadeo
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.border,
                  child: const Icon(Icons.checkroom_outlined,
                      size: 28,
                      color: AppTheme.textSecondary),
                ),
              )
                  : Container(
                color: AppTheme.border,
                child: const Icon(Icons.checkroom_outlined,
                    size: 28,
                    color: AppTheme.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}