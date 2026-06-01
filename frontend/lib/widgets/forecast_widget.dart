
// Widget reutilizable — ponlo donde quieras en feed_screen o sugerencias_screen
// Uso: ForecastWidget(ciudad: 'Madrid')

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_service.dart';
import '../../theme/app_theme.dart';

class ForecastWidget extends StatefulWidget {
  final String ciudad;
  const ForecastWidget({super.key, required this.ciudad});

  @override
  State<ForecastWidget> createState() => _ForecastWidgetState();
}

class _ForecastWidgetState extends State<ForecastWidget> {
  List<dynamic> _forecast = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ForecastWidget old) {
    super.didUpdateWidget(old);
    if (old.ciudad != widget.ciudad) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getForecast(widget.ciudad);
      if (mounted) setState(() { _forecast = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(
            color: AppTheme.accent, strokeWidth: 2)),
      );
    }
    if (_forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Próximos 5 días',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.background.withOpacity(0.7))),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast.length,
            itemBuilder: (ctx, i) => _buildDia(_forecast[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildDia(Map<String, dynamic> dia) {
    final fecha = dia['fecha'] as String;
    // Convierte "2026-05-28" a "Mié 28"
    final dt = DateTime.tryParse(fecha);
    final diasSemana = ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    final label = dt != null
        ? '${diasSemana[dt.weekday - 1]} ${dt.day}'
        : fecha.substring(5);

    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: AppTheme.background,
                  fontWeight: FontWeight.w600)),
          Image.network(dia['icono'] ?? '',
              width: 28, height: 28,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.wb_sunny_outlined,
                  size: 20, color: AppTheme.accentLight)),
          Text('${(dia['tempMax'] as num).toStringAsFixed(0)}°/'
              '${(dia['tempMin'] as num).toStringAsFixed(0)}°',
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: AppTheme.background)),
        ],
      ),
    );
  }
}