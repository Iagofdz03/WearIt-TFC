import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../main/main_screen.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isLogin = !_isLogin);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        final token = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
        await ApiService.saveToken(token);
        final me = await ApiService.getMe();
        await ApiService.saveUserData(me['id'], me['email']);
      } else {
        await ApiService.registro(
            _nombreCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
        final token =
        await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
        await ApiService.saveToken(token);
        final me = await ApiService.getMe();
        await ApiService.saveUserData(me['id'], me['email']);
      }
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panel izquierdo decorativo (solo visible en tablets/escritorio)
          if (MediaQuery.of(context).size.width > 600)
            Expanded(
              flex: 1,
              child: Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEAR\nIT',
                      style: GoogleFonts.cormorant(
                        fontSize: 80,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.background,
                        height: 0.9,
                        letterSpacing: -2,
                      ),
                    ),
                    SizedBox(height: 32),
                    Container(width: 40, height: 2, color: AppTheme.accent),
                    SizedBox(height: 24),
                    Text(
                      'Tu armario inteligente.\nOutfits perfectos cada día.',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: AppTheme.background.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Panel formulario
          Expanded(
            flex: MediaQuery.of(context).size.width > 600 ? 1 : 2,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Solo en móvil mostramos el logo
                        if (MediaQuery.of(context).size.width <= 600) ...[
                          Text(
                            'WEARIT',
                            style: GoogleFonts.cormorant(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: AppTheme.primary,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                              width: 30, height: 2, color: AppTheme.accent),
                          SizedBox(height: 32),
                        ],
                        Text(
                          _isLogin ? 'Bienvenido de nuevo' : 'Crear cuenta',
                          style: GoogleFonts.cormorant(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Accede a tu armario'
                              : 'Empieza a organizar tu estilo',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 36),
                        if (!_isLogin) ...[
                          _buildField(
                            controller: _nombreCtrl,
                            label: 'NOMBRE',
                            validator: (v) =>
                            v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          SizedBox(height: 16),
                        ],
                        _buildField(
                          controller: _emailCtrl,
                          label: 'EMAIL',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                          !v!.contains('@') ? 'Email inválido' : null,
                        ),
                        SizedBox(height: 16),
                        _buildField(
                          controller: _passCtrl,
                          label: 'CONTRASEÑA',
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) =>
                          v!.length < 4 ? 'Mínimo 4 caracteres' : null,
                        ),
                        SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                                : Text(_isLogin
                                ? 'ENTRAR'
                                : 'CREAR CUENTA'),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: _toggle,
                            child: Text(
                              _isLogin
                                  ? '¿No tienes cuenta? Regístrate'
                                  : '¿Ya tienes cuenta? Inicia sesión',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppTheme.accent,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
      ),
    );
  }
}