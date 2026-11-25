import 'package:flutter/material.dart';

const verdeCartera = Color(0xFF1A5849);
const fondoClaro = Color(0xFFF6F7F2);
const tinta = Color(0xFF172D27);
const tintaSuave = Color(0xFF4D6259);
const contorno = Color(0xFFDCE5DD);

ThemeData temaPrestaControl() {
  final esquema = ColorScheme.fromSeed(seedColor: verdeCartera).copyWith(
    primary: verdeCartera,
    onSurface: tinta,
    onSurfaceVariant: tintaSuave,
    surface: fondoClaro,
    outline: const Color(0xFF80938A),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: fondoClaro,
    appBarTheme: const AppBarTheme(
      backgroundColor: fondoClaro,
      foregroundColor: tinta,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: contorno),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class Aviso extends StatelessWidget {
  const Aviso(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colores.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colores.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: colores.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
