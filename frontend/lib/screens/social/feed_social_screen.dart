import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/outfit_canvas_view.dart';

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
      final data = await ApiService.getOutfitsPublicos(size: 50);
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
      backgroundColor: AppTheme.background,
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

  // ── Tab Explorar ────────────────────────────────────────────────────────────
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
                            color: sel ? AppTheme.background : AppTheme.textPrimary,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Feed estilo Pinterest — 3 columnas
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
                : _buildPinterestGrid(_outfitsFiltrados),
          ),
        ),
      ],
    );
  }

  // ── Grid estilo Pinterest 3 columnas ────────────────────────────────────────
  Widget _buildPinterestGrid(List<dynamic> outfits) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.52, // ratio alto — muestra prendas apiladas
            ),
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _OutfitCard(
                key: ValueKey(outfits[i]['id']),
                outfit: outfits[i],
                userId: _userId,
                onTap: () => _verOutfitCompleto(outfits[i]),
              ),
              childCount: outfits.length,
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab Tendencias ──────────────────────────────────────────────────────────
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

  Widget _buildRankingTile(Map<String, dynamic> outfit, int index) {
    final likes = outfit['likes'] ?? 0;
    final prendas = (outfit['prendas'] as List?) ?? [];
    final fotoUrl = prendas.isNotEmpty ? prendas[0]['fotoUrl'] : null;

    return GestureDetector(
      onTap: () => _verOutfitCompleto(outfit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: index == 0 ? AppTheme.accent : AppTheme.border),
        ),
        child: Row(children: [
          // Posición
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: index == 0 ? AppTheme.accent : AppTheme.border,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${index + 1}',
                style: GoogleFonts.cormorant(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: index == 0 ? Colors.white : AppTheme.textPrimary))),
          ),
          const SizedBox(width: 12),
          // Foto prenda principal
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48, height: 48,
              child: fotoUrl != null && fotoUrl.isNotEmpty
                  ? Image.network(fotoUrl, fit: BoxFit.contain,
                  gaplessPlayback: true)
                  : Container(color: AppTheme.border,
                  child: const Icon(Icons.style_outlined,
                      size: 20, color: AppTheme.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outfit['nombre'] ?? '',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('@${outfit['creadorNombre'] ?? ''}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppTheme.textSecondary)),
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

  // ── Ver outfit completo ─────────────────────────────────────────────────────
  // Sustituye el método _verOutfitCompleto() en feed_social_screen.dart
// y añade el import al principio:
// import '../../widgets/outfit_canvas_view.dart';

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
                  // Creador
                  Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: outfit['creadorFoto'] != null &&
                          outfit['creadorFoto'].isNotEmpty
                          ? NetworkImage(outfit['creadorFoto'])
                          : null,
                      child: outfit['creadorFoto'] == null ||
                          outfit['creadorFoto'].isEmpty
                          ? Text(
                          (outfit['creadorNombre'] ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: GoogleFonts.cormorant(
                              fontSize: 16, color: AppTheme.background))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(outfit['creadorNombre'] ?? '',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(outfit['ocasion'] ?? '',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    _LikeButton(outfitId: outfit['id'], userId: _userId),
                  ]),
                  const SizedBox(height: 12),
                  Text(outfit['nombre'] ?? '',
                      style: GoogleFonts.cormorant(
                          fontSize: 26, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 16),

                  // ── Canvas del outfit ──────────────────────────────────────
                  // Muestra el outfit exactamente como fue creado
                  OutfitCanvasView(
                    outfitId: outfit['id'],
                    height: 340,
                  ),

                  const SizedBox(height: 20),

                  // Prendas listadas debajo del canvas
                  Text('Prendas',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  ...prendas.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
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
                          child: p['fotoUrl'] != null &&
                              p['fotoUrl'].isNotEmpty
                              ? Image.network(p['fotoUrl'],
                              fit: BoxFit.contain, gaplessPlayback: true)
                              : Container(color: AppTheme.border,
                              child: const Icon(Icons.checkroom_outlined,
                                  color: AppTheme.textSecondary, size: 20)),
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
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
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

  Widget _buildPrendaDetalle(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        // Foto prenda
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(11)),
          child: SizedBox(
            width: 100, height: 100,
            child: p['fotoUrl'] != null && p['fotoUrl'].isNotEmpty
                ? Image.network(p['fotoUrl'],
                fit: BoxFit.contain, gaplessPlayback: true)
                : Container(color: AppTheme.border,
                child: const Icon(Icons.checkroom_outlined,
                    color: AppTheme.textSecondary)),
          ),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['nombre'] ?? '',
                style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${p['tipo'] ?? ''} · ${p['color'] ?? ''}',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

// ── Tarjeta outfit estilo Pinterest ────────────────────────────────────────────
class _OutfitCard extends StatelessWidget {
  final Map<String, dynamic> outfit;
  final int? userId;
  final VoidCallback onTap;

  const _OutfitCard({
    super.key,
    required this.outfit,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prendas = (outfit['prendas'] as List?) ?? [];
    final creador = outfit['creadorNombre'] ?? '';
    final nombre = outfit['nombre'] ?? '';
    final likes = outfit['likes'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creador header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    creador.isNotEmpty
                        ? creador.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(creador,
                      style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            // Prendas apiladas verticalmente
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: prendas.isEmpty
                    ? Center(
                    child: Icon(Icons.style_outlined,
                        size: 32,
                        color: AppTheme.textSecondary.withOpacity(0.3)))
                    : Column(
                  children: prendas.take(4).map((p) {
                    final fotoUrl = p['fotoUrl'] ?? '';
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: fotoUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            fotoUrl,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                            const Icon(
                                Icons.checkroom_outlined,
                                size: 16,
                                color: AppTheme.textSecondary),
                          ),
                        )
                            : const Center(
                            child: Icon(Icons.checkroom_outlined,
                                size: 16,
                                color: AppTheme.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Footer likes + nombre
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _LikeButton(outfitId: outfit['id'], userId: userId),
                  ]),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$creador ',
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        TextSpan(
                          text: nombre,
                          style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Like button independiente ──────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    if (widget.userId == null) return;
    try {
      if (_liked) {
        await ApiService.quitarLike(widget.userId!, widget.outfitId);
        setState(() { _liked = false; _count = (_count - 1).clamp(0, 9999); });
      } else {
        await ApiService.darLike(widget.userId!, widget.outfitId);
        setState(() { _liked = true; _count++; });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Row(children: [
        Icon(_liked ? Icons.favorite : Icons.favorite_border,
            size: 13,
            color: _liked ? AppTheme.accent : AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text('$_count likes',
            style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      ]),
    );
  }
}