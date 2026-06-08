import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import '../auth/auth_screen.dart';
import '../../theme/app_theme.dart';
import '../../../main.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _usuario;
  List<dynamic> _historial = [];
  bool _loading = true;
  int? _userId;
  String _temaActual = 'neutro';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    await Future.wait([_loadPerfil(), _loadHistorial()]);
  }

  Future<void> _loadPerfil() async {
    try {
      final data = await ApiService.getMe();
      if (mounted) setState(() {
        _usuario = data;
        _temaActual = data['tema'] ?? 'neutro';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _exportarCSV() async {
    if (_historial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay historial para exportar')),
      );
      return;
    }
    try {
      final buffer = StringBuffer();
      buffer.writeln('Fecha,Outfit,Ocasion');
      for (final h in _historial) {
        final fecha = (h['fechaUso'] ?? '').toString();
        final fechaCorta = fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
        final nombre = (h['outfit']?['nombre'] ?? '').toString().replaceAll('"', '""');
        final ocasion = (h['outfit']?['ocasion'] ?? '').toString().replaceAll('"', '""');
        buffer.writeln('"$fechaCorta","$nombre","$ocasion"');
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/historial_wearit.csv');
      await file.writeAsString(buffer.toString(), encoding: utf8);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ CSV exportado en Documentos'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _loadHistorial() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getHistorial(_userId!);
      if (mounted) setState(() => _historial = data);
    } catch (_) {}
  }

  Future<void> _cambiarTema(String nuevoTema) async {
    if (_userId == null) return;
    try {
      // Guardar en backend
      await ApiService.cambiarTema(_userId!, nuevoTema);

      // Guardar localmente para próximo arranque
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tema_usuario', nuevoTema);

      // Actualizar la app entera inmediatamente
      temaNotifier.value = nuevoTema;

      if (mounted) setState(() => _temaActual = nuevoTema);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cambiar tema: $e'),
                backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editarPerfil,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.background,
                title: Text('Cerrar sesión',
                    style: GoogleFonts.cormorant(fontSize: 20)),
                content: Text('¿Quieres cerrar sesión?',
                    style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar',
                          style: GoogleFonts.dmSans(
                              color: AppTheme.textSecondary))),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); _logout(); },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error),
                    child: const Text('Salir'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(
          color: AppTheme.accent))
          : RefreshIndicator(
        onRefresh: _init,
        color: AppTheme.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1),
              _buildSelectorTema(),
              const Divider(height: 1),
              _buildHistorial(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editarPerfil() async {
    final nombreCtrl = TextEditingController(text: _usuario?['nombre'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar perfil',
                style: GoogleFonts.cormorant(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            TextField(
              controller: nombreCtrl,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: const InputDecoration(labelText: 'NOMBRE'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiService.actualizarUsuario(
                      _userId!,
                      nombreCtrl.text.trim(),
                      _usuario?['fotoPerfil'],
                    );
                    await _loadPerfil();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'),
                              backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: const Text('GUARDAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: _usuario?['fotoPerfil'] != null
                ? ClipOval(child: Image.network(
                _usuario!['fotoPerfil'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarInitial()))
                : _avatarInitial(),
          ),
          SizedBox(height: 16),
          Text(_usuario?['nombre'] ?? '',
              style: GoogleFonts.cormorant(
                  fontSize: 26, fontWeight: FontWeight.w400)),
          SizedBox(height: 4),
          Text(_usuario?['email'] ?? '',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textSecondary)),
          SizedBox(height: 4),
          if (_usuario?['fechaRegistro'] != null)
            Text('Miembro desde ${_formatDate(_usuario!['fechaRegistro'])}',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppTheme.textSecondary)),
          SizedBox(height: 24),
          _statCard('Looks\nusados', '${_historial.length}'),
        ],
      ),
    );
  }

  // ── Selector de temas ────────────────────────────────────────────────────────
  Widget _buildSelectorTema() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.palette_outlined, size: 18, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('Estilo visual',
                style: GoogleFonts.cormorant(
                    fontSize: 20, fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: 4),
          Text('Personaliza cómo se ve la app',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textSecondary)),
          SizedBox(height: 16),
          // Grid de temas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: AppTemas.todos.values
                .map((t) => _buildTemaCard(t))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemaCard(TemaConfig tema) {
    final seleccionado = _temaActual == tema.id;
    return GestureDetector(
      onTap: () => _cambiarTema(tema.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tema.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? AppTheme.accent : AppTheme.border,
            width: seleccionado ? 2.5 : 1,
          ),
          boxShadow: seleccionado
              ? [BoxShadow(
              color: AppTheme.accent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview de colores del tema
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _colorDot(tema.primary),
                SizedBox(width: 4),
                _colorDot(tema.accent),
                SizedBox(width: 4),
                _colorDot(tema.background,
                    border: true),
              ],
            ),
            SizedBox(height: 8),
            Text(tema.emoji, style: const TextStyle(fontSize: 18)),
            SizedBox(height: 4),
            Text(tema.nombre,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: seleccionado
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: tema.textPrimary)),
            if (seleccionado)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle,
                    size: 14, color: AppTheme.accent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color, {bool border = false}) => Container(
    width: 14, height: 14,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: border
          ? Border.all(color: Colors.grey.shade300, width: 0.5)
          : null,
    ),
  );

  // ── Historial ────────────────────────────────────────────────────────────────
  Widget _buildHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(children: [
            Text('Historial de looks',
                style: GoogleFonts.cormorant(
                    fontSize: 20, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('${_historial.length} registros',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textSecondary)),
            IconButton(
              icon: Icon(Icons.download_outlined, size: 18, color: AppTheme.textSecondary),
              onPressed: _exportarCSV,
              tooltip: 'Exportar CSV',
            ),
          ]),
        ),
        _historial.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text('Aún no has registrado ningún look',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _historial.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final h = _historial[i];
            final outfit = h['outfit'];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 4),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.style_outlined,
                    color: AppTheme.textSecondary, size: 20),
              ),
              title: Text(
                outfit != null
                    ? (outfit['nombre'] ?? 'Outfit')
                    : 'Outfit',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                outfit != null ? (outfit['ocasion'] ?? '') : '',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatDate(h['fechaUso'] ?? ''),
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      await ApiService.eliminarHistorial(h['id']);
                      await _loadHistorial();
                    },
                    child: Icon(Icons.close,
                        size: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _avatarInitial() => Center(
    child: Text(
      (_usuario?['nombre'] ?? 'U').substring(0, 1).toUpperCase(),
      style: GoogleFonts.cormorant(
          fontSize: 32, fontWeight: FontWeight.w300,
          color: AppTheme.background),
    ),
  );

  Widget _statCard(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.cormorant(
          fontSize: 28, fontWeight: FontWeight.w300, color: AppTheme.accent)),
      Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center),
    ]),
  );

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}