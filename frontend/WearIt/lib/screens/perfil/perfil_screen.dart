import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../auth/auth_screen.dart';
import '../../theme/app_theme.dart';

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
      if (mounted) setState(() { _usuario = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHistorial() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getHistorial(_userId!);
      if (mounted) setState(() => _historial = data);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
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
                  TextButton(onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar',
                          style: GoogleFonts.dmSans(color: AppTheme.textSecondary))),
                  ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); _logout(); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    child: const Text('Salir'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : RefreshIndicator(
        onRefresh: _init,
        color: AppTheme.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1),
              _buildHistorial(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Avatar
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
          const SizedBox(height: 16),
          Text(
            _usuario?['nombre'] ?? '',
            style: GoogleFonts.cormorant(
                fontSize: 26, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            _usuario?['email'] ?? '',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          if (_usuario?['fechaRegistro'] != null)
            Text(
              'Miembro desde ${_formatDate(_usuario!['fechaRegistro'])}',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          const SizedBox(height: 24),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statCard('Looks\nusados', '${_historial.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text('Historial de looks',
                  style: GoogleFonts.cormorant(
                      fontSize: 20, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${_historial.length} registros',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
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
                child: const Icon(Icons.style_outlined,
                    color: AppTheme.textSecondary, size: 20),
              ),
              title: Text(
                outfit != null ? (outfit['nombre'] ?? 'Outfit') : 'Outfit',
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
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      await ApiService.eliminarHistorial(h['id']);
                      await _loadHistorial();
                    },
                    child: const Icon(Icons.close,
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
          fontSize: 32, fontWeight: FontWeight.w300, color: AppTheme.background),
    ),
  );

  Widget _statCard(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      children: [
        Text(value, style: GoogleFonts.cormorant(
            fontSize: 28, fontWeight: FontWeight.w300, color: AppTheme.accent)),
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
      ],
    ),
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