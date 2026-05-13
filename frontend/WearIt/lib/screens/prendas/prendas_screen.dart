import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import 'prenda_form_screen.dart';
import 'prenda_form_screen.dart';
import '../../theme/app_theme.dart';

class PrendasScreen extends StatefulWidget {
  const PrendasScreen({super.key});

  @override
  State<PrendasScreen> createState() => _PrendasScreenState();
}

class _PrendasScreenState extends State<PrendasScreen> {
  List<dynamic> _prendas = [];
  bool _loading = true;
  int? _userId;
  String? _filtroTipo;
  String? _filtroTemporada;
  final _busquedaCtrl = TextEditingController();

  final _tipos = ['', 'camiseta', 'pantalón', 'vestido', 'chaqueta', 'zapatos', 'accesorio'];
  final _temporadas = ['', 'verano', 'primavera', 'otoño', 'invierno', 'todo año'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await _loadPrendas();
  }

  Future<void> _loadPrendas() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getPrendas(
        _userId!,
        tipo: _filtroTipo?.isEmpty == true ? null : _filtroTipo,
        temporada: _filtroTemporada?.isEmpty == true ? null : _filtroTemporada,
        nombre: _busquedaCtrl.text.isEmpty ? null : _busquedaCtrl.text,
      );
      if (mounted) setState(() { _prendas = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminarPrenda(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text('Eliminar prenda',
            style: GoogleFonts.cormorant(fontSize: 20, color: AppTheme.textPrimary)),
        content: Text('¿Seguro que quieres eliminar esta prenda?',
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.dmSans(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.eliminarPrenda(id);
      await _loadPrendas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Armario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PrendaFormScreen(userId: _userId!)));
              await _loadPrendas();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda y filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _busquedaCtrl,
                  style: GoogleFonts.dmSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar prenda...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Tipo', _tipos, _filtroTipo, (v) {
                      setState(() => _filtroTipo = v);
                      _loadPrendas();
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDropdown('Temporada', _temporadas, _filtroTemporada, (v) {
                      setState(() => _filtroTemporada = v);
                      _loadPrendas();
                    })),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_prendas.length} prendas',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _prendas.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _loadPrendas,
              color: AppTheme.accent,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _buildDropdown(String hint, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? '',
          hint: Text(hint, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSecondary)),
          isExpanded: true,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary),
          dropdownColor: AppTheme.background,
          items: items.map((t) => DropdownMenuItem(
            value: t,
            child: Text(t.isEmpty ? 'Todos' : t,
                style: GoogleFonts.dmSans(fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPrendaCard(Map<String, dynamic> prenda) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PrendaFormScreen(userId: _userId!, prenda: prenda)));
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: prenda['fotoUrl'] != null && prenda['fotoUrl'].isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: prenda['fotoUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: (_, __, ___) => _imgPlaceholder(prenda),
                )
                    : _imgPlaceholder(prenda),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prenda['nombre'] ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prenda['tipo'] ?? ''} · ${prenda['color'] ?? ''}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(prenda['temporada'] ?? ''),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _eliminarPrenda(prenda['id']),
                        child: const Icon(Icons.delete_outline,
                            size: 16, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
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
            const Icon(Icons.checkroom_outlined,
                size: 36, color: AppTheme.textSecondary),
            if (prenda['color'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _colorFromName(prenda['color']),
                  border: Border.all(color: AppTheme.textSecondary, width: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    const map = {
      'negro': Color(0xFF1A1A1A),
      'blanco': Color(0xFFF5F5F5),
      'rojo': Color(0xFFD32F2F),
      'azul': Color(0xFF1565C0),
      'verde': Color(0xFF2E7D32),
      'amarillo': Color(0xFFF9A825),
      'rosa': Color(0xFFE91E8C),
      'gris': Color(0xFF757575),
      'beige': Color(0xFFD7CCC8),
      'naranja': Color(0xFFE65100),
    };
    return map[name.toLowerCase()] ?? AppTheme.textSecondary;
  }

  Widget _chip(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text,
          style: GoogleFonts.dmSans(fontSize: 10, color: AppTheme.textSecondary)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Tu armario está vacío',
              style: GoogleFonts.cormorant(
                  fontSize: 22, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Añade tu primera prenda',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PrendaFormScreen(userId: _userId!)));
              await _loadPrendas();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('AÑADIR PRENDA'),
          ),
        ],
      ),
    );
  }
}