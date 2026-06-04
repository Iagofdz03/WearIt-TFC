import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'api/api_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Cargar tema guardado localmente para evitar flash al arrancar
  final prefs = await SharedPreferences.getInstance();
  final temaLocal = prefs.getString('tema_usuario') ?? 'neutro';
  AppTheme.setTema(temaLocal);

  runApp(const WearItApp());
}

// Notifier global para reconstruir la app al cambiar tema
final temaNotifier = ValueNotifier<String>('neutro');

class WearItApp extends StatelessWidget {
  const WearItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: temaNotifier,
      builder: (_, tema, __) {
        AppTheme.setTema(tema);
        return MaterialApp(
          title: 'WearIt',
          theme: AppTheme.theme,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final token = await ApiService.getToken();

    // Si hay sesión, cargar el tema del usuario desde el servidor
    if (token != null) {
      try {
        final me = await ApiService.getMe();
        final tema = me['tema'] ?? 'neutro';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tema_usuario', tema);
        temaNotifier.value = tema; // actualiza la app
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
          token != null ? const MainScreen() : const AuthScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WEAR\nIT',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorant(
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    color: AppTheme.background,
                    height: 0.9,
                    letterSpacing: -2,
                  ),
                ),
                SizedBox(height: 32),
                Container(width: 40, height: 1.5, color: AppTheme.accent),
                SizedBox(height: 20),
                Text(
                  'Tu armario inteligente',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.background.withOpacity(0.5),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}