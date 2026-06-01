import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';

class FeedSocialScreen extends StatefulWidget {
  const FeedSocialScreen({super.key});

  @override
  State<FeedSocialScreen> createState() => _FeedSocialScreenState();
}

class _FeedSocialScreenState extends State<FeedSocialScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _outfits = [];
  bool _loading = true;
  int? _userId;
  String _filtroOcasion = '';
  String _busqueda = '';
  final _busquedaCtrl = TextEditingController();
  late TabController _tabCtrl;

  final _ocasiones = ['', 'casual', 'trabajo', 'fiesta', 'deporte', 'formal'];
  final _labels = {
    '': 'Todos', 'casual': 'Casual', 'trabajo': 'Trabajo',
    'fiesta': 'Fiesta', 'deporte': 'Deporte', 'formal': 'Formal',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getOutfitsPublicos();
      if (mounted) setState(() {
        _outfits = data['content'] ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _outfitsFiltrados {
    var lista = _outfits;
    if (_filtroOcasion.isNotEmpty) {
      lista = lista.where((o) => o['ocasion'] == _filtroOcasion).toList();
    }
    if (_busqueda.isNotEmpty) {
      lista = lista.where((o) =>
          (o['nombre'] ?? '').toLowerCase().contains(
              _busqueda.toLowerCase())).toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comunidad',
            style: GoogleFonts.cormorant(
                fontSize: 22, fontWeight: FontWeight.w500)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'EXPLORAR'),
            Tab(text: 'TENDENCIAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildExplorar(),
          _buildTendencias(),
        ],
      ),
    );
  }

  Widget _buildExplorar() {
    return Column(
      children: [
        // Búsqueda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _busquedaCtrl,
            style: GoogleFonts.dmSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar outfits...',
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: AppTheme.textSecondary),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    setState(() => _busqueda = '');
                  })
                  : null,
            ),
            onChanged: (v) => setState(() => _busqueda = v),
          ),
        ),
        // Filtros ocasión
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ocasiones.length,
            itemBuilder: (ctx, i) {
              final oc = _ocasiones[i];
              final sel = _filtroOcasion == oc;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filtroOcasion = oc),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppTheme.primary : AppTheme.border),
                    ),
                    child: Text(_labels[oc]!,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: sel
                                ? AppTheme.background
                                : AppTheme.textPrimary,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Grid outfits
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
              color: AppTheme.accent))
              : RefreshIndicator(
            onRefresh: _loadFeed,
            color: AppTheme.accent,
            child: _outfitsFiltrados.isEmpty
                ? Center(child: Text('Sin outfits públicos',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textSecondary)))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _outfitsFiltrados.length,
              itemBuilder: (ctx, i) =>
                  _buildOutfitCard(_outfitsFiltrados[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTendencias() {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getRanking(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              color: AppTheme.accent));
        }
        final ranking = snap.data ?? [];
        if (ranking.isEmpty) {
          return Center(child: Text('Sin datos de tendencias',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ranking.length,
          itemBuilder: (ctx, i) => _buildRankingTile(ranking[i], i),
        );
      },
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    final prendas = (outfit['prendas'] as List?) ?? [];
    return GestureDetector(
      onTap: () => _verOutfitCompleto(outfit),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview fotos prendas
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9)),
                child: _buildOutfitPreview(prendas),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(outfit['nombre'] ?? '',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(outfit['ocasion'] ?? '',
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: AppTheme.textSecondary)),
                    ),
                    const Spacer(),
                    _LikeButton(
                        outfitId: outfit['id'], userId: _userId),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Preview del outfit mostrando las primeras 4 prendas en grid 2x2
  Widget _buildOutfitPreview(List prendas) {
    if (prendas.isEmpty) {
      return Container(
        color: AppTheme.border,
        child: const Center(child: Icon(Icons.style_outlined,
            size: 40, color: AppTheme.textSecondary)),
      );
    }

    final fotos = prendas
        .where((p) => p['fotoUrl'] != null && p['fotoUrl'].isNotEmpty)
        .take(4)
        .toList();

    if (fotos.length == 1) {
      return Image.network(fotos[0]['fotoUrl'],
          fit: BoxFit.contain, gaplessPlayback: true,
          width: double.infinity);
    }

    // Grid 2x2 con las primeras prendas
    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: fotos.map((p) => Image.network(
        p['fotoUrl'],
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.border,
          child: const Icon(Icons.checkroom_outlined,
              size: 20, color: AppTheme.textSecondary),
        ),
      )).toList(),
    );
  }

  Widget _buildRankingTile(Map<String, dynamic> outfit, int index) {
    final likes = outfit['likes'] ?? 0;
    return GestureDetector(
      onTap: () => _verOutfitCompleto(outfit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: index == 0 ? AppTheme.accent : AppTheme.border),
        ),
        child: Row(children: [
          // Posición
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: index == 0 ? AppTheme.accent : AppTheme.border,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${index + 1}',
                style: GoogleFonts.cormorant(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: index == 0
                        ? Colors.white
                        : AppTheme.textPrimary))),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outfit['nombre'] ?? '',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(outfit['ocasion'] ?? '',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          )),
          // Likes
          Row(children: [
            const Icon(Icons.favorite, size: 14, color: AppTheme.accent),
            const SizedBox(width: 4),
            Text('$likes', style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ]),
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
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) {
          final prendas = (outfit['prendas'] as List?) ?? [];
          return Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
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
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(outfit['ocasion'] ?? '',
                          style: GoogleFonts.dmSans(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    _LikeButton(
                        outfitId: outfit['id'], userId: _userId),
                  ]),
                  const SizedBox(height: 20),
                  Text('Prendas del outfit',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  // Grid prendas completo
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: prendas.length,
                    itemBuilder: (ctx, i) {
                      final p = prendas[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7)),
                              child: p['fotoUrl'] != null &&
                                  p['fotoUrl'].isNotEmpty
                                  ? Image.network(p['fotoUrl'],
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  gaplessPlayback: true)
                                  : Container(color: AppTheme.border,
                                  child: const Icon(
                                      Icons.checkroom_outlined,
                                      color: AppTheme.textSecondary)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(children: [
                              Text(p['nombre'] ?? '',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '${p['tipo'] ?? ''} · ${p['color'] ?? ''}',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary)),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// Widget de like independiente para evitar rebuilds del padre
class _LikeButton extends StatefulWidget {
  final int outfitId;
  final int? userId;

  const _LikeButton({required this.outfitId, this.userId});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool _liked = false;
  int _count = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEstado();
  }

  Future<void> _loadEstado() async {
    if (widget.userId == null) return;
    try {
      final data = await ApiService.estadoLike(
          widget.outfitId, widget.userId!);
      if (mounted) setState(() {
        _liked = data['yaDiLike'] ?? false;
        _count = data['count'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (widget.userId == null || _loading) return;
    setState(() => _loading = true);
    try {
      if (_liked) {
        await ApiService.quitarLike(widget.userId!, widget.outfitId);
        setState(() { _liked = false; _count = (_count - 1).clamp(0, 9999); });
      } else {
        await ApiService.darLike(widget.userId!, widget.outfitId);
        setState(() { _liked = true; _count++; });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Row(children: [
        Icon(
          _liked ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: _liked ? AppTheme.accent : AppTheme.textSecondary,
        ),
        const SizedBox(width: 3),
        Text('$_count',
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }
}