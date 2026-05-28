import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Emulador Android: 10.0.2.2 | Dispositivo físico: IP de tu ordenador
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_email');
  }

  static Future<void> saveUserData(int id, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuario_id', id);
    await prefs.setString('usuario_email', email);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('usuario_id');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── AUTH ───────────────────────────────────────────────────────────────────

  static Future<String> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['token'];
    }
    throw Exception(jsonDecode(res.body)['error'] ?? 'Error al iniciar sesión');
  }

  static Future<Map<String, dynamic>> registro(
      String nombre, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: await _headers(auth: false),
      body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception(jsonDecode(res.body)['error'] ?? 'Error al registrarse');
  }

  // ─── USUARIO ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/usuarios/me'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener perfil');
  }

  static Future<Map<String, dynamic>> actualizarUsuario(
      int id, String nombre, String? fotoPerfil) async {
    final res = await http.put(
      Uri.parse('$baseUrl/usuarios/$id'),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'fotoPerfil': fotoPerfil}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al actualizar perfil');
  }

  // ─── PRENDAS ────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getPrendas(int usuarioId,
      {String? tipo,
        String? color,
        String? estilo,
        String? temporada,
        String? nombre}) async {
    String url = '$baseUrl/prendas/usuario/$usuarioId';
    final params = <String, String>{};
    if (tipo != null) params['tipo'] = tipo;
    if (color != null) params['color'] = color;
    if (estilo != null) params['estilo'] = estilo;
    if (temporada != null) params['temporada'] = temporada;
    if (nombre != null) params['nombre'] = nombre;

    if (params.isNotEmpty) {
      url = '$baseUrl/prendas/usuario/$usuarioId/filtrar';
    }

    final uri = Uri.parse(url)
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener prendas');
  }

  static Future<Map<String, dynamic>> crearPrenda(
      Map<String, dynamic> prenda) async {
    print('>>> Creando prenda: ${jsonEncode(prenda)}');
    final token = await getToken();
    print('>>> Token: $token');
    final res = await http.post(
      Uri.parse('$baseUrl/prendas'),
      headers: await _headers(),
      body: jsonEncode(prenda),
    );
    print('>>> Status crear prenda: ${res.statusCode}');
    print('>>> Body crear prenda: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Error al crear prenda');
  }

  static Future<Map<String, dynamic>> actualizarPrenda(
      int id, Map<String, dynamic> prenda) async {
    final res = await http.put(
      Uri.parse('$baseUrl/prendas/$id'),
      headers: await _headers(),
      body: jsonEncode(prenda),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al actualizar prenda');
  }

  static Future<void> eliminarPrenda(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/prendas/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Error al eliminar prenda');
  }

  // ─── OUTFITS ────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getOutfitsUsuario(int usuarioId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/outfits/usuario/$usuarioId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener outfits');
  }

  static Future<Map<String, dynamic>> getOutfitsPublicos(
      {int page = 0, int size = 10}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/outfits/publicos?page=$page&size=$size'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener outfits públicos');
  }

  static Future<List<dynamic>> getRanking() async {
    final res = await http.get(
      Uri.parse('$baseUrl/outfits/ranking'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener ranking');
  }

  static Future<Map<String, dynamic>> crearOutfit(
      Map<String, dynamic> outfit) async {
    final res = await http.post(
      Uri.parse('$baseUrl/outfits'),
      headers: await _headers(),
      body: jsonEncode(outfit),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Error al crear outfit');
  }

  static Future<Map<String, dynamic>> actualizarOutfit(
      int id, Map<String, dynamic> outfit) async {
    final res = await http.put(
      Uri.parse('$baseUrl/outfits/$id'),
      headers: await _headers(),
      body: jsonEncode(outfit),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al actualizar outfit');
  }

  static Future<void> eliminarOutfit(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/outfits/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Error al eliminar outfit');
  }

  // ─── LIKES ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> estadoLike(
      int outfitId, int usuarioId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/likes/outfit/$outfitId/estado/$usuarioId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener estado like');
  }

  static Future<void> darLike(int usuarioId, int outfitId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/likes'),
      headers: await _headers(),
      body: jsonEncode({
        'usuario': {'id': usuarioId},
        'outfit': {'id': outfitId},
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al dar like');
    }
  }

  static Future<void> quitarLike(int usuarioId, int outfitId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/likes/usuario/$usuarioId/outfit/$outfitId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Error al quitar like');
  }

  // ─── HISTORIAL ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getHistorial(int usuarioId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/historial/usuario/$usuarioId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener historial');
  }

  static Future<void> guardarHistorial(int usuarioId, int outfitId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/historial'),
      headers: await _headers(),
      body: jsonEncode({
        'usuario': {'id': usuarioId},
        'outfit': {'id': outfitId},
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al guardar historial');
    }
  }

  static Future<void> eliminarHistorial(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/historial/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Error al eliminar historial');
  }

  // ─── SUGERENCIAS ────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getSugerencias(int usuarioId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/outfits/sugerir/$usuarioId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener sugerencias');
  }

  static Future<List<dynamic>> getSugerenciasTiempo(
      int usuarioId, String? ocasion, String? temporada) async {
    final params = <String, String>{};
    if (ocasion != null) params['ocasion'] = ocasion;
    if (temporada != null) params['temporada'] = temporada;
    final uri = Uri.parse('$baseUrl/outfits/sugerir/$usuarioId/tiempo')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener sugerencias por tiempo');
  }

  // ─── TIEMPO ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTiempo(String ciudad) async {
    print('>>> GET tiempo: $baseUrl/tiempo/$ciudad');
    final res = await http.get(
      Uri.parse('$baseUrl/tiempo/$ciudad'),
      headers: await _headers(),
    );
    print('>>> Status: ${res.statusCode}');
    print('>>> Body: ${res.body}');
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error al obtener el tiempo');
  }

  // ─── IMÁGENES ───────────────────────────────────────────────────────────────

  static Future<String> subirImagen(List<int> bytes, String filename) async {
    print('>>> Subiendo imagen a: $baseUrl/imagenes/subir');
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/imagenes/subir'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    print('>>> Status subir: ${response.statusCode}');
    print('>>> Body subir: $body');
    if (response.statusCode == 200) {
      return jsonDecode(body)['url'];
    }
    throw Exception('Error al subir imagen');
  }

  static Future<String> removeBg(String imageUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/imagenes/remove-bg'),
      headers: await _headers(),
      body: jsonEncode({'url': imageUrl}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['url'];
    throw Exception('Error al quitar fondo');
  }
}