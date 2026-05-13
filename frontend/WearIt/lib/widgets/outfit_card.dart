import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';


class OutfitCard extends StatefulWidget {
  final Map<String, dynamic> outfit;
  final int? userId;
  final VoidCallback? onLikeChanged;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.userId,
    this.onLikeChanged,
  });

  @override
  State<OutfitCard> createState() => _OutfitCardState();
}

class _OutfitCardState extends State<OutfitCard> {
  bool _liked = false;
  int _count = 0;
  bool _loadingLike = false;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    if (widget.userId == null) return;
    try {
      final data = await ApiService.estadoLike(
          widget.outfit['id'], widget.userId!);
      if (mounted) {
        setState(() {
          _liked = data['yaDiLike'] ?? false;
          _count = data['count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (widget.userId == null || _loadingLike) return;
    setState(() => _loadingLike = true);
    try {
      if (_liked) {
        await ApiService.quitarLike(widget.userId!, widget.outfit['id']);
        setState(() {
          _liked = false;
          _count = (_count - 1).clamp(0, 9999);
        });
      } else {
        await ApiService.darLike(widget.userId!, widget.outfit['id']);
        setState(() {
          _liked = true;
          _count++;
        });
      }
      widget.onLikeChanged?.call();
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingLike = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prendas = (widget.outfit['prendas'] as List?) ?? [];
    final fotoUrl = prendas.isNotEmpty ? prendas[0]['fotoUrl'] : null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen / placeholder
          Expanded(
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
              child: fotoUrl != null && fotoUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: fotoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                    color: AppTheme.border,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 1))),
                errorWidget: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.outfit['nombre'] ?? 'Outfit',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        widget.outfit['ocasion'] ?? '',
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        children: [
                          Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _liked ? AppTheme.accent : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$_count',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.border,
      child: Center(
        child: Icon(Icons.style_outlined,
            size: 40, color: AppTheme.textSecondary.withOpacity(0.4)),
      ),
    );
  }
}