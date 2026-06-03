import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/outfit_canvas_view.dart';

// Widget reutilizable que reproduce el canvas de un outfit
// Uso: OutfitCanvasView(outfitId: 1)
class OutfitCanvasView extends StatefulWidget {
  final int outfitId;
  final double? height;
  final bool interactive; // true = se puede hacer zoom/pan

  const OutfitCanvasView({
    super.key,
    required this.outfitId,
    this.height,
    this.interactive = false,
  });

  @override
  State<OutfitCanvasView> createState() => _OutfitCanvasViewState();
}

class _OutfitCanvasViewState extends State<OutfitCanvasView> {
  List<dynamic> _posiciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      print('>>> Cargando posiciones outfit ${widget.outfitId}');
      final data = await ApiService.getPosiciones(widget.outfitId);
      print('>>> Posiciones recibidas: ${data.length} — $data');
      if (mounted) setState(() {
        _posiciones = data;
        _loading = false;
      });
    } catch (e) {
      print('>>> ERROR cargando posiciones: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? 320.0;

    if (_loading) {
      return SizedBox(
        height: h,
        child: const Center(child: CircularProgressIndicator(
            color: AppTheme.accent, strokeWidth: 2)),
      );
    }

    if (_posiciones.isEmpty) {
      return SizedBox(
        height: h,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.style_outlined, size: 48,
                  color: AppTheme.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text('Sin posiciones guardadas',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Silueta de fondo
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.accessibility_new,
                    size: 200, color: AppTheme.textPrimary),
              ),
            ),
            // Prendas en sus posiciones exactas ordenadas por zIndex
            ..._posiciones.map((pos) => _buildPrendaEnPosicion(pos)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrendaEnPosicion(Map<String, dynamic> pos) {
    final x = (pos['x'] as num).toDouble();
    final y = (pos['y'] as num).toDouble();
    final scale = (pos['scale'] as num).toDouble();
    final fotoUrl = pos['fotoUrl'] as String? ?? '';
    final size = 130.0 * scale;

    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: size,
        height: size,
        child: fotoUrl.isNotEmpty
            ? Image.network(
          fotoUrl,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.checkroom_outlined,
              color: AppTheme.textSecondary),
        )
            : const Icon(Icons.checkroom_outlined,
            color: AppTheme.textSecondary),
      ),
    );
  }
}