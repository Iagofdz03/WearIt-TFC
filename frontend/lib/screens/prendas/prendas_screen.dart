import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import 'prenda_form_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/favorito_button.dart';

class PrendasScreen extends StatefulWidget {
  const PrendasScreen({super.key});

  @override
  State<PrendasScreen> createState() => _PrendasScreenState();
}

class _PrendasScreenState extends State<PrendasScreen> {
  List<dynamic> _prendas = [];
  bool _loading = true;
  int? _userId;
  final _busquedaCtrl = TextEditingController();
  bool _soloFavoritos = false;

  final Set<String> _filtrosTipo = {};
  final Set<String> _filtrosColor = {};
  final Set<String> _filtrosEstilo = {};
  final Set<String> _filtrosTemporada = {};
  bool _mostrarFiltros = false;

  final _tipos = ['camiseta', 'pantalón', 'vestido', 'chaqueta', 'zapatos',
    'accesorio', 'falda', 'jersey', 'top', 'bolso', 'collar'];
  final _colores = ['negro', 'blanco', 'rojo', 'azul', 'verde', 'amarillo',
    'rosa', 'gris', 'beige', 'naranja', 'morado', 'marrón', 'turquesa'];
  final _estilos = ['casual', 'formal', 'deportivo', 'elegante', 'bohemio',
    'urbano', 'vintage', 'minimalista'];
  final _temporadas = ['verano', 'primavera', 'otoño', 'invierno', 'todo año'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await _loadPrendas();
  }

  Future<void> _loadPrendas() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      List<dynamic> data;

      if (_soloFavoritos) {
        final favs = await ApiService.getPrendasFavoritas(_userId!);
        data = favs
            .map((f) => f['prenda'])
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        data = await ApiService.getPrendas(_userId!,
            nombre: _busquedaCtrl.text.isEmpty ? null : _busquedaCtrl.text);
      }

      List<dynamic> filtradas = data;
      if (_filtrosTipo.isNotEmpty) {
        filtradas = filtradas.where((p) =>
            _filtrosTipo.contains((p['tipo'] ?? '').toLowerCase())).toList();
      }
      if (_filtrosColor.isNotEmpty) {
        filtradas = filtradas.where((p) =>
            _filtrosColor.contains((p['color'] ?? '').toLowerCase())).toList();
      }
      if (_filtrosEstilo.isNotEmpty) {
        filtradas = filtradas.where((p) =>
            _filtrosEstilo.contains(
                (p['estilo'] ?? '').toLowerCase())).toList();
      }
      if (_filtrosTemporada.isNotEmpty) {
        filtradas = filtradas.where((p) =>
            _filtrosTemporada.contains(
                (p['temporada'] ?? '').toLowerCase())).toList();
      }

      if (mounted) setState(() { _prendas = filtradas; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleFiltro(Set<String> set, String valor) {
    setState(() {
      if (set.contains(valor)) {
        set.remove(valor);
      } else {
        set.add(valor);
      }
    });
    _loadPrendas();
  }

  void _limpiarFiltros() {
    setState(() {
      _filtrosTipo.clear();
      _filtrosColor.clear();
      _filtrosEstilo.clear();
      _filtrosTemporada.clear();
    });
    _loadPrendas();
  }

  int get _totalFiltrosActivos =>
      _filtrosTipo.length + _filtrosColor.length +
          _filtrosEstilo.length + _filtrosTemporada.length;

  Future<void> _eliminarPrenda(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text('Eliminar prenda',
            style: GoogleFonts.cormorant(
                fontSize: 20, color: AppTheme.textPrimary)),
        content: Text('¿Seguro que quieres eliminar esta prenda?',
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: GoogleFonts.dmSans(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.eliminarPrenda(id);
        await _loadPrendas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Armario'),
        actions: [
          // Botón favoritos
          IconButton(
            icon: Icon(
              _soloFavoritos ? Icons.star : Icons.star_border,
              color: _soloFavoritos ? Colors.amber : AppTheme.textPrimary,
            ),
            onPressed: () {
              setState(() => _soloFavoritos = !_soloFavoritos);
              _loadPrendas();
            },
          ),
          // Botón filtros con badge
          Stack(
            children: [
              IconButton(
                icon: Icon(_mostrarFiltros
                    ? Icons.filter_list_off
                    : Icons.filter_list),
                onPressed: () =>
                    setState(() => _mostrarFiltros = !_mostrarFiltros),
              ),
              if (_totalFiltrosActivos > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                        color: AppTheme.accent, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_totalFiltrosActivos',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
          // Botón añadir
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => PrendaFormScreen(userId: _userId!)));
              await _loadPrendas();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _busquedaCtrl,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar prenda...',
                prefixIcon: Icon(Icons.search,
                    size: 18, color: AppTheme.textSecondary),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _busquedaCtrl.clear();
                      _loadPrendas();
                    })
                    : null,
              ),
              onSubmitted: (_) => _loadPrendas(),
            ),
          ),

          // Panel filtros múltiples
          if (_mostrarFiltros)
            Container(
              margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filtros',
                          style: GoogleFonts.cormorant(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      if (_totalFiltrosActivos > 0)
                        TextButton(
                          onPressed: _limpiarFiltros,
                          child: Text('Limpiar todo',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppTheme.accent)),
                        ),
                    ],
                  ),
                  _buildFiltroSeccion('Tipo', _tipos, _filtrosTipo),
                  _buildFiltroSeccion('Color', _colores, _filtrosColor),
                  _buildFiltroSeccion('Estilo', _estilos, _filtrosEstilo),
                  _buildFiltroSeccion(
                      'Temporada', _temporadas, _filtrosTemporada),
                ],
              ),
            ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Text(
                  _soloFavoritos
                      ? '${_prendas.length} favoritas'
                      : '${_prendas.length} prendas',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ),

          // Grid prendas
          Expanded(
            child: _loading
                ? Center(
                child: CircularProgressIndicator(color: AppTheme.accent))
                : _prendas.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _loadPrendas,
              color: AppTheme.accent,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: _prendas.length,
                itemBuilder: (ctx, i) => _buildPrendaCard(_prendas[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroSeccion(
      String titulo, List<String> opciones, Set<String> seleccionados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(titulo,
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary, letterSpacing: 0.8)),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: opciones.map((op) {
            final sel = seleccionados.contains(op);
            return GestureDetector(
              onTap: () => _toggleFiltro(seleccionados, op),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppTheme.primary : AppTheme.border),
                ),
                child: Text(op,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: sel
                            ? AppTheme.background
                            : AppTheme.textPrimary,
                        fontWeight: sel
                            ? FontWeight.w600
                            : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrendaCard(Map<String, dynamic> prenda) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) =>
                PrendaFormScreen(userId: _userId!, prenda: prenda)));
        await _loadPrendas();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(8)),
                child: prenda['fotoUrl'] != null &&
                    prenda['fotoUrl'].isNotEmpty
                    ? Image.network(
                  prenda['fotoUrl'],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      _imgPlaceholder(prenda),
                )
                    : _imgPlaceholder(prenda),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prenda['nombre'] ?? '',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      '${prenda['tipo'] ?? ''} · ${prenda['color'] ?? ''}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1),
                  const SizedBox(height: 6),
                  Row(children: [
                    _chip(prenda['temporada'] ?? ''),
                    const Spacer(),
                    if (_userId != null)
                      FavoritoButton(
                        usuarioId: _userId!,
                        itemId: prenda['id'],
                        esPrenda: true,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _eliminarPrenda(prenda['id']),
                      child: Icon(Icons.delete_outline,
                          size: 16, color: AppTheme.textSecondary),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(Map<String, dynamic> prenda) {
    return Container(
      color: AppTheme.border,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom_outlined,
                size: 36, color: AppTheme.textSecondary),
            if (prenda['color'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _colorFromName(prenda['color']),
                  border: Border.all(
                      color: AppTheme.textSecondary, width: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    const map = {
      'negro': Color(0xFF1A1A1A), 'blanco': Color(0xFFF5F5F5),
      'rojo': Color(0xFFD32F2F), 'azul': Color(0xFF1565C0),
      'verde': Color(0xFF2E7D32), 'amarillo': Color(0xFFF9A825),
      'rosa': Color(0xFFE91E8C), 'gris': Color(0xFF757575),
      'beige': Color(0xFFD7CCC8), 'naranja': Color(0xFFE65100),
      'morado': Color(0xFF6A1B9A), 'marrón': Color(0xFF5D4037),
      'turquesa': Color(0xFF00796B),
    };
    return map[name.toLowerCase()] ?? AppTheme.textSecondary;
  }

  Widget _chip(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text,
          style: GoogleFonts.dmSans(
              fontSize: 10, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              _soloFavoritos
                  ? Icons.star_border
                  : Icons.checkroom_outlined,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
              _soloFavoritos
                  ? 'No tienes prendas favoritas'
                  : 'Tu armario está vacío',
              style: GoogleFonts.cormorant(
                  fontSize: 22, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(
              _soloFavoritos
                  ? 'Marca prendas con ★ para verlas aquí'
                  : 'Añade tu primera prenda',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textSecondary)),
          if (!_soloFavoritos) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PrendaFormScreen(userId: _userId!)));
                await _loadPrendas();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('AÑADIR PRENDA'),
            ),
          ],
        ],
      ),
    );
  }
}