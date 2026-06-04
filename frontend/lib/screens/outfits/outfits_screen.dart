import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import 'outfit_form_screen.dart';
import 'outfit_creator_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/favorito_button.dart';
import '../../widgets/outfit_canvas_view.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _outfits = [];
  List<dynamic> _favoritos = [];
  List<dynamic> outfitsFav = [];
  bool _loading = true;
  int? _userId;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await Future.wait([_loadOutfits(), _loadFavoritos()]);
  }

  Future<void> _loadOutfits() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getOutfitsUsuario(_userId!);
      if (mounted) setState(() { _outfits = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFavoritos() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getOutfitsFavoritos(_userId!);
      if (mounted) setState(() => _favoritos = data);
    } catch (_) {}
  }

  Future<void> _eliminar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text('Eliminar outfit',
            style: GoogleFonts.cormorant(fontSize: 20)),
        content: Text('¿Eliminar este outfit?',
            style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
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
      await ApiService.eliminarOutfit(id);
      await Future.wait([_loadOutfits(), _loadFavoritos()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => OutfitCreatorScreen(userId: _userId!)));
              await Future.wait([_loadOutfits(), _loadFavoritos()]);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 2,
          tabs: const [Tab(text: 'MIS OUTFITS'), Tab(text: 'FAVORITOS')],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMisOutfits(),
          _buildFavoritos(),
        ],
      ),
    );
  }

  Widget _buildMisOutfits() {
    if (_outfits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 64,
                color: AppTheme.textSecondary.withOpacity(0.3)),
            SizedBox(height: 16),
            Text('Sin outfits todavía',
                style: GoogleFonts.cormorant(
                    fontSize: 22, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => OutfitCreatorScreen(userId: _userId!)));
                await Future.wait([_loadOutfits(), _loadFavoritos()]);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('CREAR OUTFIT'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Future.wait([_loadOutfits(), _loadFavoritos()]),
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outfits.length,
        itemBuilder: (ctx, i) => _buildOutfitTile(_outfits[i]),
      ),
    );
  }

  Widget _buildFavoritos() {
    if (_favoritos.isEmpty) {
      // Extrae los outfits del objeto favorito
      final outfitsFav = _favoritos
          .whereType<Map<String, dynamic>>()
          .toList();

    if (outfitsFav.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64,
                color: AppTheme.textSecondary.withOpacity(0.3)),
            SizedBox(height: 16),
            Text('Sin outfits favoritos',
                style: GoogleFonts.cormorant(
                    fontSize: 22, color: AppTheme.textSecondary)),
            SizedBox(height: 8),
            Text('Marca outfits con ★ para verlos aquí',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }}

    return RefreshIndicator(
      onRefresh: _loadFavoritos,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoritos.length,
        // ✅ pasa directamente sin extraer ['outfit']
        itemBuilder: (ctx, i) => _buildOutfitTile(_favoritos[i], esFavorito: true),
      ),
    );
  }

  Widget _buildOutfitTile(Map<String, dynamic> outfit, {bool esFavorito = false}) {
    final prendas = (outfit['prendas'] as List?) ?? [];

    return GestureDetector(
      onTap: () => _verOutfitCompleto(outfit),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),

          leading: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(6),
            ),
            child: outfit['fotoPortada'] != null && outfit['fotoPortada'].isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                outfit['fotoPortada'],
                fit: BoxFit.cover,
                width: 52, height: 52,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.style_outlined,
                    color: AppTheme.textSecondary, size: 26),
              ),
            )
                : Icon(Icons.style_outlined,
                color: AppTheme.textSecondary, size: 26),
          ),

          title: Text(
            outfit['nombre'] ?? '',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${prendas.length} prendas · ${outfit['ocasion'] ?? ''}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _chip(
                    outfit['esPublico'] == true ? 'Público' : 'Privado',
                    outfit['esPublico'] == true
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  if (_userId != null)
                    FavoritoButton(
                      usuarioId: _userId!,
                      itemId: outfit['id'],
                      esPrenda: false,
                      size: 16,
                    ),
                ],
              ),
            ],
          ),

          trailing: esFavorito
              ? null
              : PopupMenuButton<String>(
            color: AppTheme.background,
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.textSecondary,
              size: 18,
            ),
            onSelected: (action) async {
              if (action == 'editar') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OutfitCreatorScreen(
                      userId: _userId!,
                      outfitId: outfit['id'],
                      outfitExistente: outfit,
                    ),
                  ),
                );
                await Future.wait([_loadOutfits(), _loadFavoritos()]);
              } else if (action == 'eliminar') {
                await _eliminar(outfit['id']);
              } else if (action == 'historial') {
                await ApiService.guardarHistorial(_userId!, outfit['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Añadido al historial'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'editar',
                child: Text(
                  'Editar',
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ),
              PopupMenuItem(
                value: 'historial',
                child: Text(
                  'Marcar como usado',
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ),
              PopupMenuItem(
                value: 'eliminar',
                child: Text(
                  'Eliminar',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verOutfitCompleto(Map<String, dynamic> outfit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scroll) {
          final prendas = (outfit['prendas'] as List?) ?? [];
          return Column(children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(outfit['nombre'] ?? '',
                      style: GoogleFonts.cormorant(
                          fontSize: 26, fontWeight: FontWeight.w400)),
                  SizedBox(height: 4),
                  Text(outfit['ocasion'] ?? '',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  OutfitCanvasView(outfitId: outfit['id'], height: 340),
                  const SizedBox(height: 20),
                  Text('Prendas',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  ...prendas.map((p) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 52, height: 52,
                          child: p['fotoUrl'] != null && p['fotoUrl'].isNotEmpty
                              ? Image.network(p['fotoUrl'],
                              fit: BoxFit.contain, gaplessPlayback: true)
                              : Container(color: AppTheme.border,
                              child: Icon(Icons.checkroom_outlined,
                                  color: AppTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nombre'] ?? '',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${p['tipo'] ?? ''} · ${p['color'] ?? ''}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      )),
                    ]),
                  )),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(text,
        style: GoogleFonts.dmSans(
            fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}