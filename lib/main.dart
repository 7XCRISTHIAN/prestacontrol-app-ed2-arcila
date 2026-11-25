import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/acceso.dart';
import 'screens/cartera.dart';
import 'services/api.dart';
import 'services/sesion.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PrestaControlApp());
}

class PrestaControlApp extends StatefulWidget {
  const PrestaControlApp({super.key});

  @override
  State<PrestaControlApp> createState() => _PrestaControlAppState();
}

class _PrestaControlAppState extends State<PrestaControlApp> {
  late final Sesion _sesion = Sesion();
  late final PrestaApi _api = PrestaApi(_sesion);

  @override
  void initState() {
    super.initState();
    _sesion.restaurar();
  }

  @override
  void dispose() {
    _api.cerrar();
    _sesion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _sesion,
    builder: (context, _) => MaterialApp(
      // Descarta el formulario o detalle abierto cuando termina la sesión.
      key: ValueKey(_sesion.autenticado),
      title: 'PrestaControl',
      debugShowCheckedModeBanner: false,
      theme: temaPrestaControl(),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _inicio(),
    ),
  );

  Widget _inicio() {
    if (_sesion.restaurando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_sesion.errorAlRestaurar) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo leer la sesión guardada.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _sesion.restaurar,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_sesion.autenticado) return Cartera(api: _api, sesion: _sesion);
    return Acceso(api: _api, aviso: _sesion.aviso);
  }
}
