import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Sesion extends ChangeNotifier {
  static const _clave = 'prestacontrol.jwt';
  final _storage = const FlutterSecureStorage();

  String? _token;
  String? get token => _token;
  bool get autenticado => _token != null;

  bool restaurando = true;
  bool errorAlRestaurar = false;
  String? aviso;
  Future<void>? _borrado;

  Future<void> restaurar() async {
    restaurando = true;
    errorAlRestaurar = false;
    notifyListeners();
    try {
      final guardado = await _storage.read(key: _clave);
      _token = guardado == null || guardado.isEmpty ? null : guardado;
    } catch (_) {
      errorAlRestaurar = true;
    } finally {
      restaurando = false;
      notifyListeners();
    }
  }

  Future<void> guardar(String token) async {
    await _borrado;
    await _storage.write(key: _clave, value: token);
    _token = token;
    aviso = null;
    notifyListeners();
  }

  Future<void> invalidar(String tokenUsado) async {
    if (_token == tokenUsado) {
      await cerrar(motivo: 'Tu sesión venció. Vuelve a iniciar sesión.');
    }
  }

  Future<void> cerrar({String? motivo}) async {
    if (_token == null) return;
    _token = null;
    aviso = motivo;
    _borrado = _borrarToken();
    notifyListeners();
    await _borrado;
  }

  Future<void> _borrarToken() async {
    try {
      await _storage.delete(key: _clave);
    } catch (_) {
      aviso = 'No pudimos borrar la sesión guardada del dispositivo.';
      notifyListeners();
    }
  }
}
