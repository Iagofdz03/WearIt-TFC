import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/outfit_card.dart';
import '../../theme/app_theme.dart';
import '../../widgets/forecast_widget.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _outfits = [];
  Map<String, dynamic>? _tiempo;
  bool _loading = true;
  String _ciudad = 'Vigo';
  final _ciudadCtrl = TextEditingController(text: 'Vigo');
  String _filtroOcasion = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await Future.wait([_loadFeed(), _loadTiempo()]);
  }

  Future<void> _loadFeed() async {
    try {
      final data = await ApiService.getOutfitsPublicos();
      if (mounted) {
        setState(() {
          _outfits = data['content'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTiempo() async {
    try {
      final data = await ApiService.getTiempo(_ciudad);
      if (mounted) setState(() => _tiempo = data);
    } catch (_) {}
  }

  Future<void> _buscarCiudad() async {
    setState(() {
      _ciudad = _ciudadCtrl.text.trim();
      _tiempo = null;
    });
    await _loadTiempo();
  }

  List<dynamic> get _outfitsFiltrados {
    if (_filtroOcasion.isEmpty) return _outfits;
    return _outfits
        .where((o) => o['ocasion'] == _filtroOcasion)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'WEARIT',
              style: GoogleFonts.cormorant(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: AppTheme.accent,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.wait([_loadFeed(), _loadTiempo()]),
        color: AppTheme.accent,
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: AppTheme.accent))
            : CustomScrollView(
          slivers: [
            // Widget del tiempo
            SliverToBoxAdapter(child: _buildTiempoCard()),

            // Filtros
            SliverToBoxAdapter(child: _buildFiltros()),

            // Grid outfits
            _outfitsFiltrados.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Text(
                  'Sin outfits públicos aún',
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textSecondary),
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) => OutfitCard(
                    outfit: _outfitsFiltrados[i],
                    userId: _userId,
                    onLikeChanged: _loadFeed,
                  ),
                  childCount: _outfitsFiltrados.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiempoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ciudadCtrl,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.background, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ciudad...',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppTheme.background.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppTheme.background.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search,
                          color: AppTheme.background, size: 18),
                      onPressed: _buscarCiudad,
                    ),
                  ),
                  onSubmitted: (_) => _buscarCiudad(),
                ),
              ),
            ],
          ),
          if (_tiempo != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: _tiempo!['icono'] ?? '',
                  width: 50,
                  height: 50,
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.wb_sunny_outlined,
                      color: AppTheme.accentLight,
                      size: 40),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tiempo!['temperatura']?.toStringAsFixed(0)}°C',
                      style: GoogleFonts.cormorant(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.background,
                      ),
                    ),
                    Text(
                      '${_tiempo!['ciudad']} · ${_tiempo!['descripcion']}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.background.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              ],
            ),
            const SizedBox(height: 12),
            ForecastWidget(ciudad: _ciudad),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                  child:
                  CircularProgressIndicator(color: AppTheme.accentLight)),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final ocasiones = ['', 'casual', 'trabajo', 'fiesta', 'deporte'];
    final labels = {
      '': 'Todos',
      'casual': 'Casual',
      'trabajo': 'Trabajo',
      'fiesta': 'Fiesta',
      'deporte': 'Deporte',
    };

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ocasiones.length,
        itemBuilder: (ctx, i) {
          final oc = ocasiones[i];
          final selected = _filtroOcasion == oc;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[oc]!),
              selected: selected,
              onSelected: (_) => setState(() => _filtroOcasion = oc),
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.cardBg,
              labelStyle: GoogleFonts.dmSans(
                fontSize: 12,
                color: selected ? AppTheme.background : AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide(
                  color: selected ? AppTheme.primary : AppTheme.border),
              checkmarkColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        },
      ),
    );
  }
}