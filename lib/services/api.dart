import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/prestamo.dart';
import 'sesion.dart';

class ApiError implements Exception {
  const ApiError(this.mensaje);

  final String mensaje;
}

class PrestaApi {
  PrestaApi(this._sesion);

  final Sesion _sesion;
  final _cliente = http.Client();

  void cerrar() => _cliente.close();

  Future<void> entrar({
    required String email,
    required String password,
    String? nombre,
  }) async {
    final respuesta = await _pedir(
      'POST',
      nombre == null ? '/auth/login' : '/auth/register',
      protegido: false,
      cuerpo: {'email': email, 'password': password, 'nombre': ?nombre},
    );
    final token = (respuesta as Map<String, dynamic>)['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiError('El servidor no devolvió una sesión válida.');
    }
    await _sesion.guardar(token);
  }

  Future<List<Prestamo>> listar() async {
    final json = await _pedir('GET', '/prestamos') as List<dynamic>;
    return json
        .map((item) => Prestamo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenCartera> resumen() async => ResumenCartera.fromJson(
    await _pedir('GET', '/prestamos/resumen') as Map<String, dynamic>,
  );

  Future<Prestamo> obtener(int id) async => Prestamo.fromJson(
    await _pedir('GET', '/prestamos/$id') as Map<String, dynamic>,
  );

  Future<void> guardar(PrestamoDatos datos, {int? id}) async {
    await _pedir(
      id == null ? 'POST' : 'PUT',
      id == null ? '/prestamos' : '/prestamos/$id',
      cuerpo: datos.toJson(),
    );
  }

  Future<void> anular(int id) async {
    await _pedir('DELETE', '/prestamos/$id');
  }

  Future<Object?> _pedir(
    String metodo,
    String ruta, {
    bool protegido = true,
    Map<String, Object>? cuerpo,
  }) async {
    final base = Uri.tryParse(
      apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
    );
    if (base == null ||
        !base.hasAuthority ||
        !{'http', 'https'}.contains(base.scheme)) {
      throw const ApiError(
        'Configura la URL del servidor para usar PrestaControl.',
      );
    }

    final token = protegido ? _sesion.token : null;
    if (protegido && token == null) {
      throw const ApiError('Inicia sesión para continuar.');
    }

    final peticion = http.Request(metodo, Uri.parse('$base$ruta'))
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
    if (cuerpo != null) {
      peticion.headers['Content-Type'] = 'application/json; charset=utf-8';
      peticion.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      respuesta = await _cliente
          .send(peticion)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ApiError(
        'El servidor está tardando en responder. Intenta otra vez.',
      );
    } on SocketException {
      throw const ApiError(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on http.ClientException {
      throw const ApiError(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }

    if (respuesta.statusCode == 401 && token != null) {
      await _sesion.invalidar(token);
      throw const ApiError('Tu sesión venció. Vuelve a iniciar sesión.');
    }

    final correcto = respuesta.statusCode >= 200 && respuesta.statusCode < 300;
    Object? json;
    try {
      if (respuesta.bodyBytes.isNotEmpty) {
        json = jsonDecode(utf8.decode(respuesta.bodyBytes));
      }
    } on FormatException {
      if (correcto) {
        throw const ApiError('El servidor devolvió datos inesperados.');
      }
    }

    if (correcto) return json;
    final mensaje = json is Map<String, dynamic> ? json['mensaje'] : null;
    if (mensaje is String && mensaje.isNotEmpty) throw ApiError(mensaje);
    if (respuesta.statusCode == 401) {
      throw const ApiError('Correo o contraseña incorrectos.');
    }
    throw ApiError(
      'No se pudo completar la operación (${respuesta.statusCode}).',
    );
  }
}
