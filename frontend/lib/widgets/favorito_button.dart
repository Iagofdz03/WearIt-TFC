import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';

class FavoritoButton extends StatefulWidget {
  final int usuarioId;
  final int itemId;
  final bool esPrenda; // true = prenda, false = outfit
  final double size;

  const FavoritoButton({
    super.key,
    required this.usuarioId,
    required this.itemId,
    required this.esPrenda,
    this.size = 18,
  });

  @override
  State<FavoritoButton> createState() => _FavoritoButtonState();
}

class _FavoritoButtonState extends State<FavoritoButton> {
  bool _favorito = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEstado();
  }

  Future<void> _loadEstado() async {
    try {
      final val = widget.esPrenda
          ? await ApiService.esPrendaFavorita(widget.usuarioId, widget.itemId)
          : await ApiService.esOutfitFavorito(widget.usuarioId, widget.itemId);
      if (mounted) setState(() { _favorito = val; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    setState(() => _favorito = !_favorito);
    try {
      if (widget.esPrenda) {
        await ApiService.togglePrendaFavorita(widget.usuarioId, widget.itemId);
      } else {
        await ApiService.toggleOutfitFavorito(widget.usuarioId, widget.itemId);
      }
    } catch (_) {
      // Revierte si falla
      if (mounted) setState(() => _favorito = !_favorito);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return SizedBox(width: widget.size, height: widget.size);
    return GestureDetector(
      onTap: _toggle,
      child: Icon(
        _favorito ? Icons.star : Icons.star_border,
        size: widget.size,
        color: _favorito ? Colors.amber : AppTheme.textSecondary,
      ),
    );
  }
}