import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import 'outfit_form_screen.dart';
import 'outfit_form_screen.dart';
import '../../theme/app_theme.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _outfits = [];
  List<dynamic> _ranking = [];
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
    await Future.wait([_loadOutfits(), _loadRanking()]);
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

  Future<void> _loadRanking() async {
    try {
      final data = await ApiService.getRanking();
      if (mounted) setState(() => _ranking = data);
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
      await ApiService.eliminarOutfit(id);
      await _loadOutfits();
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
                  MaterialPageRoute(builder: (_) => OutfitFormScreen(userId: _userId!)));
              await _loadOutfits();
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
          tabs: const [Tab(text: 'MIS OUTFITS'), Tab(text: 'RANKING')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMisOutfits(),
          _buildRanking(),
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
            const SizedBox(height: 16),
            Text('Sin outfits todavía',
                style: GoogleFonts.cormorant(fontSize: 22, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => OutfitFormScreen(userId: _userId!)));
                await _loadOutfits();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('CREAR OUTFIT'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOutfits,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _outfits.length,
        itemBuilder: (ctx, i) => _buildOutfitTile(_outfits[i]),
      ),
    );
  }

  Widget _buildOutfitTile(Map<String, dynamic> outfit) {
    final prendas = (outfit['prendas'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.style_outlined,
              color: AppTheme.textSecondary, size: 26),
        ),
        title: Text(outfit['nombre'] ?? '',
            style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${prendas.length} prendas · ${outfit['ocasion'] ?? ''}',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              _chip(outfit['esPublico'] == true ? 'Público' : 'Privado',
                  outfit['esPublico'] == true ? AppTheme.success : AppTheme.textSecondary),
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppTheme.background,
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 18),
          onSelected: (action) async {
            if (action == 'editar') {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      OutfitFormScreen(userId: _userId!, outfit: outfit)));
              await _loadOutfits();
            } else if (action == 'eliminar') {
              await _eliminar(outfit['id']);
            } else if (action == 'historial') {
              await ApiService.guardarHistorial(_userId!, outfit['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Añadido al historial'),
                        backgroundColor: AppTheme.success));
              }
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(value: 'editar',
                child: Text('Editar', style: GoogleFonts.dmSans(fontSize: 13))),
            PopupMenuItem(value: 'historial',
                child: Text('Marcar como usado', style: GoogleFonts.dmSans(fontSize: 13))),
            PopupMenuItem(value: 'eliminar',
                child: Text('Eliminar',
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.error))),
          ],
        ),
      ),
    );
  }

  Widget _buildRanking() {
    if (_ranking.isEmpty) {
      return Center(child: Text('Sin datos',
          style: GoogleFonts.dmSans(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ranking.length,
      itemBuilder: (ctx, i) {
        final outfit = _ranking[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: i == 0 ? AppTheme.accent : AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: i == 0 ? AppTheme.accent : AppTheme.border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: GoogleFonts.cormorant(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: i == 0 ? Colors.white : AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(outfit['nombre'] ?? '',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(outfit['ocasion'] ?? '',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Row(children: [
                const Icon(Icons.favorite, size: 14, color: AppTheme.accent),
                const SizedBox(width: 4),
                Text('${(outfit['prendas'] as List?)?.length ?? 0}',
                    style: GoogleFonts.dmSans(fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(text,
        style: GoogleFonts.dmSans(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}