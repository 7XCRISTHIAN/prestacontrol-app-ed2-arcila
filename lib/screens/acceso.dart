import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme.dart';

class Acceso extends StatefulWidget {
  const Acceso({super.key, required this.api, this.aviso});

  final PrestaApi api;
  final String? aviso;

  @override
  State<Acceso> createState() => _AccesoState();
}

class _AccesoState extends State<Acceso> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _registro = false;
  bool _ocultar = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _enviando = true;
    });
    try {
      await widget.api.entrar(
        email: _correo.text.trim(),
        password: _password.text,
        nombre: _registro ? _nombre.text.trim() : null,
      );
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo iniciar la sesión. Intenta otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _cambiarModo() {
    setState(() {
      _registro = !_registro;
      _ocultar = true;
      _error = null;
      _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final aviso = _error ?? widget.aviso;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF163F35), verdeCartera],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(27),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFD5F6E4),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(11),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: verdeCartera,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'PrestaControl',
                                style: texto.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tus préstamos y cobros',
                                style: TextStyle(color: Color(0xFFD7EEE2)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _registro ? 'Crear cuenta' : 'Iniciar sesión',
                          style: texto.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (aviso != null) ...[
                          Aviso(aviso),
                          const SizedBox(height: 14),
                        ],
                        AutofillGroup(
                          child: Form(
                            key: _formulario,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_registro) ...[
                                  TextFormField(
                                    controller: _nombre,
                                    enabled: !_enviando,
                                    autofillHints: const [AutofillHints.name],
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (valor) {
                                      final nombre = valor?.trim() ?? '';
                                      if (nombre.isEmpty) {
                                        return 'Ingresa tu nombre.';
                                      }
                                      if (nombre.length > 100) {
                                        return 'Usa hasta 100 caracteres.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 13),
                                ],
                                TextFormField(
                                  controller: _correo,
                                  enabled: !_enviando,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Correo',
                                    prefixIcon: Icon(Icons.alternate_email),
                                  ),
                                  validator: (valor) {
                                    final correo = valor?.trim() ?? '';
                                    if (!RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(correo) ||
                                        correo.length > 120) {
                                      return 'Ingresa un correo válido.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 13),
                                TextFormField(
                                  controller: _password,
                                  enabled: !_enviando,
                                  obscureText: _ocultar,
                                  autofillHints: [
                                    _registro
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _enviar(),
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _ocultar
                                          ? 'Mostrar contraseña'
                                          : 'Ocultar contraseña',
                                      icon: Icon(
                                        _ocultar
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () =>
                                          setState(() => _ocultar = !_ocultar),
                                    ),
                                  ),
                                  validator: (valor) {
                                    final password = valor ?? '';
                                    if (password.trim().isEmpty) {
                                      return 'Ingresa tu contraseña.';
                                    }
                                    if (_registro && password.length < 8) {
                                      return 'Usa al menos 8 caracteres.';
                                    }
                                    if (utf8.encode(password).length > 72) {
                                      return 'Usa una contraseña más corta.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed: _enviando ? null : _enviar,
                                  child: _enviando
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _registro
                                              ? 'Crear mi cuenta'
                                              : 'Entrar',
                                        ),
                                ),
                                const SizedBox(height: 7),
                                TextButton(
                                  onPressed: _enviando ? null : _cambiarModo,
                                  child: Text(
                                    _registro
                                        ? 'Volver a iniciar sesión'
                                        : 'Crear una cuenta',
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
