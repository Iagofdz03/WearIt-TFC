import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/forecast_widget.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _trending = [];
  List<dynamic> _prendas = [];
  List<dynamic> _outfitsPublicos = [];
  Map<String, dynamic>? _tiempo;
  Map<String, dynamic>? _usuario;
  bool _loading = true;
  String _ciudad = 'Madrid';
  final _ciudadCtrl = TextEditingController(text: 'Madrid');
  int? _userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await Future.wait([
      _loadTiempo(),
      _loadTrending(),
      _loadPrendas(),
      _loadOutfitsPublicos(),
      _loadUsuario(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadTiempo() async {
    try {
      final t = await ApiService.getTiempo(_ciudad);
      if (mounted) setState(() => _tiempo = t);
    } catch (_) {}
  }

  Future<void> _loadTrending() async {
    try {
      final data = await ApiService.getRanking();
      if (mounted) setState(() => _trending = data.take(5).toList());
    } catch (_) {}
  }

  Future<void> _loadPrendas() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getPrendas(_userId!);
      if (mounted) setState(() => _prendas = data.take(6).toList());
    } catch (_) {}
  }

  Future<void> _loadOutfitsPublicos() async {
    try {
      final data = await ApiService.getOutfitsPublicos();
      if (mounted) {
        setState(() => _outfitsPublicos =
            ((data['content'] as List?) ?? []).take(6).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadUsuario() async {
    try {
      final data = await ApiService.getMe();
      if (mounted) setState(() => _usuario = data);
    } catch (_) {}
  }

  Future<void> _buscarCiudad() async {
    final ciudad = _ciudadCtrl.text.trim();
    if (ciudad.isEmpty) return;
    setState(() { _ciudad = ciudad; _tiempo = null; });
    await _loadTiempo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
        onRefresh: _init,
        color: AppTheme.accent,
        child: CustomScrollView(
          slivers: [
            // ── AppBar con header revista ──────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Widget tiempo + forecast ───────────────────────────────
            SliverToBoxAdapter(child: _buildTiempoCard()),

            // ── Tendencias ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSeccionTitulo(
                'Tendencias', Icons.trending_up)),
            SliverToBoxAdapter(child: _buildTrending()),

            // ── Tu armario hoy ─────────────────────────────────────────
            if (_prendas.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSeccionTitulo(
                  'Tu armario hoy', Icons.checkroom_outlined)),
              SliverToBoxAdapter(child: _buildArmarioHoy()),
            ],

            // ── Inspiración ────────────────────────────────────────────
            if (_outfitsPublicos.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSeccionTitulo(
                  'Inspiración', Icons.auto_awesome_outlined)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildInspirationCard(
                        _outfitsPublicos[i]),
                    childCount: _outfitsPublicos.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // ── Header revista ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final nombre = _usuario?['nombre'] ?? '';
    final hora = DateTime.now().hour;
    final saludo = hora < 12 ? 'Buenos días' : hora < 20 ? 'Buenas tardes' : 'Buenas noches';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(saludo,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.background.withOpacity(0.6),
                          letterSpacing: 0.5)),
                  if (nombre.isNotEmpty)
                    Text(nombre,
                        style: GoogleFonts.cormorant(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.background,
                            letterSpacing: -0.5)),
                ],
              ),
              // Logo
              Text('WEARIT',
                  style: GoogleFonts.cormorant(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.accent,
                      letterSpacing: 3)),
            ],
          ),
          const SizedBox(height: 20),
          // Buscador ciudad
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ciudadCtrl,
                style: GoogleFonts.dmSans(
                    color: AppTheme.background, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ciudad...',
                  hintStyle: GoogleFonts.dmSans(
                      color: AppTheme.background.withOpacity(0.4)),
                  filled: true,
                  fillColor: AppTheme.background.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppTheme.background.withOpacity(0.6), size: 16),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _buscarCiudad(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _buscarCiudad,
              icon: const Icon(Icons.search,
                  color: AppTheme.background, size: 20),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Tiempo + forecast ──────────────────────────────────────────────────────
  Widget _buildTiempoCard() {
    if (_tiempo == null) {
      return Container(
        color: AppTheme.primary,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: const Center(
            child: CircularProgressIndicator(
                color: AppTheme.accentLight, strokeWidth: 2)),
      );
    }

    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Temperatura actual
          Row(children: [
            Image.network(
              _tiempo!['icono'] ?? '',
              width: 56, height: 56,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppTheme.accentLight, size: 46),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(_tiempo!['temperatura'] as num).toStringAsFixed(0)}°C',
                  style: GoogleFonts.cormorant(
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      color: AppTheme.background,
                      height: 1),
                ),
                Text(
                  '${_tiempo!['ciudad']} · ${_tiempo!['descripcion']}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.background.withOpacity(0.65)),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tiempo!['temporadaRecomendada'] ?? '',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Forecast 5 días
          ForecastWidget(ciudad: _ciudad),
        ],
      ),
    );
  }

  // ── Título de sección ──────────────────────────────────────────────────────
  Widget _buildSeccionTitulo(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(children: [
        Icon(icono, size: 18, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(titulo,
            style: GoogleFonts.cormorant(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
        const Spacer(),
        Container(width: 40, height: 1, color: AppTheme.border),
      ]),
    );
  }

  // ── Tendencias ─────────────────────────────────────────────────────────────
  Widget _buildTrending() {
    if (_trending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Sin tendencias aún',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppTheme.textSecondary)),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _trending.length,
        itemBuilder: (ctx, i) => _buildTrendingCard(_trending[i], i),
      ),
    );
  }

  Widget _buildTrendingCard(Map<String, dynamic> outfit, int index) {
    final prendas = (outfit['prendas'] as List?) ?? [];
    final likes = outfit['likes'] ?? 0;
    final fotoUrl = prendas.isNotEmpty ? prendas[0]['fotoUrl'] : null;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: index == 0 ? AppTheme.accent : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Expanded(
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(9)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  fotoUrl != null && fotoUrl.isNotEmpty
                      ? Image.network(fotoUrl,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.border,
                          child: const Icon(Icons.style_outlined,
                              color: AppTheme.textSecondary)))
                      : Container(
                      color: AppTheme.border,
                      child: const Icon(Icons.style_outlined,
                          color: AppTheme.textSecondary)),
                  // Badge posición
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppTheme.accent
                            : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${index + 1}',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outfit['nombre'] ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.favorite,
                      size: 11, color: AppTheme.accent),
                  const SizedBox(width: 3),
                  Text('$likes',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppTheme.textSecondary)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tu armario hoy ─────────────────────────────────────────────────────────
  Widget _buildArmarioHoy() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _prendas.length,
        itemBuilder: (ctx, i) {
          final p = _prendas[i];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7)),
                    child: p['fotoUrl'] != null && p['fotoUrl'].isNotEmpty
                        ? Image.network(p['fotoUrl'],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.border,
                            child: const Icon(Icons.checkroom_outlined,
                                size: 24,
                                color: AppTheme.textSecondary)))
                        : Container(
                        color: AppTheme.border,
                        child: const Icon(Icons.checkroom_outlined,
                            size: 24,
                            color: AppTheme.textSecondary)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Text(p['nombre'] ?? '',
                      style: GoogleFonts.dmSans(
                          fontSize: 9, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Inspiración grid ───────────────────────────────────────────────────────
  Widget _buildInspirationCard(Map<String, dynamic> outfit) {
    final prendas = (outfit['prendas'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview fotos
          Expanded(
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(9)),
              child: _buildOutfitPreview(prendas),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outfit['nombre'] ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
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
    );
  }

  Widget _buildOutfitPreview(List prendas) {
    final fotos = prendas
        .where((p) => p['fotoUrl'] != null && p['fotoUrl'].isNotEmpty)
        .take(4)
        .toList();

    if (fotos.isEmpty) {
      return Container(
        color: AppTheme.border,
        child: const Center(child: Icon(Icons.style_outlined,
            size: 36, color: AppTheme.textSecondary)),
      );
    }
    if (fotos.length == 1) {
      return Image.network(fotos[0]['fotoUrl'],
          fit: BoxFit.contain, gaplessPlayback: true,
          width: double.infinity);
    }
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
              size: 18, color: AppTheme.textSecondary),
        ),
      )).toList(),
    );
  }
}

// ── Like button independiente ─────────────────────────────────────────────────
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
            size: 14,
            color: _liked ? AppTheme.accent : AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text('$_count',
            style: GoogleFonts.dmSans(
                fontSize: 10, color: AppTheme.textSecondary)),
      ]),
    );
  }
}