import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/formatos.dart';
import '../models/prestamo.dart';
import '../services/api.dart';
import '../theme.dart';

class FormularioPrestamo extends StatefulWidget {
  const FormularioPrestamo({super.key, required this.api, this.prestamo});

  final PrestaApi api;
  final Prestamo? prestamo;

  @override
  State<FormularioPrestamo> createState() => _FormularioPrestamoState();
}

class _FormularioPrestamoState extends State<FormularioPrestamo> {
  final _formulario = GlobalKey<FormState>();
  final _fecha = TextEditingController();
  late final _cliente = TextEditingController(
    text: widget.prestamo?.datos.cliente,
  );
  late final _dni = TextEditingController(text: widget.prestamo?.datos.dni);
  late final _monto = TextEditingController(
    text: _importeInicial(widget.prestamo?.datos.monto),
  );
  late final _interes = TextEditingController(
    text: _importeInicial(widget.prestamo?.datos.interes),
  );
  late final _fechaInicial = widget.prestamo?.fechaPrestamo ?? hoyEnPeru();
  DateTime? _vencimiento;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vencimiento = widget.prestamo?.datos.fechaVencimiento;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vencimiento case final DateTime fecha) _fecha.text = fechaCorta(fecha);
  }

  @override
  void dispose() {
    _fecha.dispose();
    _cliente.dispose();
    _dni.dispose();
    _monto.dispose();
    _interes.dispose();
    super.dispose();
  }

  String? _importeInicial(double? valor) =>
      valor == null ? null : importeEditable(valor);

  double _decimal(String texto) =>
      double.parse(texto.trim().replaceAll(',', '.'));

  String? _validarImporte(String? valor, {required bool esMonto}) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Campo obligatorio.';
    final formato = esMonto
        ? r'^\d{1,8}([.,]\d{1,2})?$'
        : r'^\d{1,3}([.,]\d{1,2})?$';
    if (!RegExp(formato).hasMatch(texto)) {
      return 'Revisa el importe y sus decimales.';
    }
    if (esMonto && _decimal(texto) <= 0) return 'Debe ser mayor que cero.';
    return null;
  }

  Future<void> _elegirFecha() async {
    FocusScope.of(context).unfocus();
    final ultimaFecha = DateTime(2100, 12, 31);
    final fechaActual = _vencimiento ?? hoyEnPeru();
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaActual.isBefore(_fechaInicial)
          ? _fechaInicial
          : fechaActual,
      firstDate: _fechaInicial,
      lastDate: fechaActual.isAfter(ultimaFecha) ? fechaActual : ultimaFecha,
      helpText: 'Selecciona el vencimiento',
    );
    if (!mounted || elegida == null) return;
    setState(() {
      _vencimiento = elegida;
      _fecha.text = fechaCorta(elegida);
    });
  }

  Future<void> _guardar() async {
    if (_guardando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.api.guardar(
        PrestamoDatos(
          cliente: _cliente.text.trim(),
          dni: _dni.text,
          monto: _decimal(_monto.text),
          interes: _decimal(_interes.text),
          fechaVencimiento: _vencimiento!,
        ),
        id: widget.prestamo?.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar el préstamo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nuevo = widget.prestamo == null;
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(nuevo ? 'Nuevo préstamo' : 'Editar préstamo'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formulario,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      'Datos del cliente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    if (_error case final String mensaje) ...[
                      Aviso(mensaje),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _cliente,
                      enabled: !_guardando,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del cliente',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (valor) {
                        final cliente = valor?.trim() ?? '';
                        if (cliente.isEmpty) {
                          return 'Ingresa el nombre del cliente.';
                        }
                        if (cliente.length > 100) {
                          return 'Usa hasta 100 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dni,
                      enabled: !_guardando,
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (valor) => (valor?.length ?? 0) == 8
                          ? null
                          : 'El DNI debe tener 8 dígitos.',
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Condiciones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _monto,
                      enabled: !_guardando,
                      decoration: const InputDecoration(
                        labelText: 'Monto prestado',
                        prefixText: 'S/ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (valor) =>
                          _validarImporte(valor, esMonto: true),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _interes,
                      enabled: !_guardando,
                      decoration: const InputDecoration(
                        labelText: 'Interés',
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (valor) =>
                          _validarImporte(valor, esMonto: false),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fecha,
                      readOnly: true,
                      enabled: !_guardando,
                      onTap: _elegirFecha,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de vencimiento',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      validator: (_) => _vencimiento == null
                          ? 'Selecciona un vencimiento.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        nuevo ? 'Registrar préstamo' : 'Guardar cambios',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
