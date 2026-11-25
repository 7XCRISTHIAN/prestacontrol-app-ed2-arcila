import 'package:flutter/material.dart';

import '../config/formatos.dart';
import '../models/prestamo.dart';
import '../services/api.dart';
import '../services/sesion.dart';
import '../theme.dart';
import 'formulario_prestamo.dart';

enum _Filtro { porCobrar, cobrados }

enum _Accion { editar, cobrar, anular }

class Cartera extends StatefulWidget {
  const Cartera({super.key, required this.api, required this.sesion});

  final PrestaApi api;
  final Sesion sesion;

  @override
  State<Cartera> createState() => _CarteraState();
}

class _CarteraState extends State<Cartera> {
  final _busqueda = TextEditingController();
  List<Prestamo>? _prestamos;
  ResumenCartera? _resumen;
  _Filtro _filtro = _Filtro.porCobrar;
  String? _error;
  bool _cargando = false;
  bool _operando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Future.wait([
        widget.api.listar().then((prestamos) {
          if (mounted) setState(() => _prestamos = prestamos);
        }),
        widget.api.resumen().then((resumen) {
          if (mounted) setState(() => _resumen = resumen);
        }),
      ]);
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar la cartera.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirFormulario([Prestamo? actual]) async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioPrestamo(api: widget.api, prestamo: actual),
      ),
    );
    if (!mounted || cambio != true) return;
    if (actual == null) {
      setState(() {
        _filtro = _Filtro.porCobrar;
        _busqueda.clear();
      });
    }
    await _cargar();
    if (mounted) {
      _avisar(actual == null ? 'Préstamo registrado.' : 'Cambios guardados.');
    }
  }

  Future<void> _detalle(Prestamo prestamo) async {
    if (_operando) return;
    setState(() => _operando = true);
    try {
      final detalle = await widget.api.obtener(prestamo.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detalle.datos.cliente,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'DNI ${detalle.datos.dni}',
                  style: const TextStyle(color: tintaSuave),
                ),
                const SizedBox(height: 20),
                _Dato('Monto prestado', soles(detalle.datos.monto)),
                _Dato('Interés', porcentaje(detalle.datos.interes)),
                _Dato('Fecha de préstamo', fechaCorta(detalle.fechaPrestamo)),
                _Dato(
                  'Vencimiento',
                  fechaCorta(detalle.datos.fechaVencimiento),
                ),
                const Divider(height: 28),
                _Dato(
                  'Total a cobrar',
                  soles(detalle.totalCobrar),
                  destacado: true,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _Estado(
                    prestamo: detalle,
                    vencido: detalle.vencidoAl(hoyEnPeru()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on ApiError catch (error) {
      if (mounted) _avisar(error.mensaje);
    } catch (_) {
      if (mounted) _avisar('No se pudo consultar el préstamo.');
    } finally {
      if (mounted) setState(() => _operando = false);
    }
  }

  Future<void> _accion(Prestamo prestamo, _Accion accion) async {
    if (_operando) return;
    if (accion == _Accion.editar) {
      await _abrirFormulario(prestamo);
      return;
    }
    final cobrando = accion == _Accion.cobrar;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cobrando ? '¿Marcar como pagado?' : '¿Anular préstamo?'),
        content: Text(
          cobrando
              ? 'Se registrará el cobro de ${soles(prestamo.totalCobrar)} a ${prestamo.datos.cliente}.'
              : 'Se eliminará el préstamo de ${prestamo.datos.cliente} de la cartera.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(cobrando ? 'Confirmar cobro' : 'Sí, anular'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;
    setState(() => _operando = true);
    try {
      if (cobrando) {
        await widget.api.guardar(prestamo.marcarPagado(), id: prestamo.id);
      } else {
        await widget.api.anular(prestamo.id);
      }
      if (!mounted) return;
      await _cargar();
      if (mounted) {
        _avisar(cobrando ? 'Cobro registrado.' : 'Préstamo anulado.');
      }
    } on ApiError catch (error) {
      if (mounted) _avisar(error.mensaje);
    } catch (_) {
      if (mounted) _avisar('No se pudo completar la operación.');
    } finally {
      if (mounted) setState(() => _operando = false);
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _normalizar(String entrada) {
    final texto = entrada.toLowerCase().trim();
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
    };
    return texto.replaceAllMapped(
      RegExp('[áéíóúü]'),
      (letra) => acentos[letra[0]]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoy = hoyEnPeru();
    final busqueda = _normalizar(_busqueda.text);
    final visibles = (_prestamos ?? []).where((prestamo) {
      final datos = prestamo.datos;
      return prestamo.pagado == (_filtro == _Filtro.cobrados) &&
          (_normalizar(datos.cliente).contains(busqueda) ||
              datos.dni.contains(busqueda));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'PrestaControl',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.6),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar cartera',
            onPressed: _cargando || _operando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => widget.sesion.cerrar(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _operando || _cargando ? null : _abrirFormulario,
        backgroundColor: verdeCartera,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo préstamo'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverList.list(
                      children: [
                        if (_resumen case final ResumenCartera resumen) ...[
                          _Resumen(resumen: resumen),
                          const SizedBox(height: 24),
                        ],
                        if (_cargando || _operando) ...[
                          const LinearProgressIndicator(minHeight: 2),
                          const SizedBox(height: 12),
                        ],
                        if (_error case final String mensaje) ...[
                          Aviso(mensaje),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _cargar,
                              child: const Text('Reintentar'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Préstamos',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _busqueda,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o DNI',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _busqueda.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () => setState(_busqueda.clear),
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<_Filtro>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: _Filtro.porCobrar,
                              label: Text('Por cobrar'),
                              icon: Icon(Icons.schedule),
                            ),
                            ButtonSegment(
                              value: _Filtro.cobrados,
                              label: Text('Cobrados'),
                              icon: Icon(Icons.task_alt),
                            ),
                          ],
                          selected: {_filtro},
                          onSelectionChanged: (seleccion) =>
                              setState(() => _filtro = seleccion.first),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (_prestamos != null && visibles.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                        child: Column(
                          children: [
                            Icon(
                              busqueda.isEmpty
                                  ? Icons.receipt_long_outlined
                                  : Icons.search_off,
                              color: tintaSuave,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              busqueda.isNotEmpty
                                  ? 'No hay coincidencias.'
                                  : _filtro == _Filtro.cobrados
                                  ? 'Aún no hay préstamos cobrados.'
                                  : 'No hay préstamos por cobrar.',
                              style: const TextStyle(color: tintaSuave),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 92),
                    sliver: SliverList.builder(
                      itemCount: visibles.length,
                      itemBuilder: (context, index) {
                        final prestamo = visibles[index];
                        return _TarjetaPrestamo(
                          prestamo: prestamo,
                          vencido: prestamo.vencidoAl(hoy),
                          habilitado: !_operando && !_cargando,
                          onTap: () => _detalle(prestamo),
                          onAccion: (accion) => _accion(prestamo, accion),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.resumen});

  final ResumenCartera resumen;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143D33), verdeCartera],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFA6E7C2),
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Total por cobrar',
                  style: TextStyle(
                    color: Color(0xFFD8F1E4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              soles(resumen.totalPorCobrar),
              style: texto.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const Divider(color: Color(0xFF598474), height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Indicador(
                  'Capital prestado',
                  soles(resumen.capitalPrestado),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Indicador(
                  'Ganancia esperada',
                  soles(resumen.gananciaEsperada),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador(this.nombre, this.valor);

  final String nombre;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        nombre,
        style: const TextStyle(color: Color(0xFFD8F1E4), fontSize: 12),
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _TarjetaPrestamo extends StatelessWidget {
  const _TarjetaPrestamo({
    required this.prestamo,
    required this.vencido,
    required this.habilitado,
    required this.onTap,
    required this.onAccion,
  });

  final Prestamo prestamo;
  final bool vencido;
  final bool habilitado;
  final VoidCallback onTap;
  final ValueChanged<_Accion> onAccion;

  @override
  Widget build(BuildContext context) {
    final datos = prestamo.datos;
    final colorBorde = vencido ? const Color(0xFFE8B6AA) : contorno;
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: vencido ? const Color(0xFFFFF7F5) : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: BorderSide(color: colorBorde),
        ),
        child: InkWell(
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 6, 6, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        datos.cliente,
                        style: texto.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    PopupMenuButton<_Accion>(
                      tooltip: 'Acciones del préstamo',
                      enabled: habilitado,
                      onSelected: onAccion,
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: _Accion.editar,
                          child: Text('Editar'),
                        ),
                        if (!prestamo.pagado)
                          const PopupMenuItem(
                            value: _Accion.cobrar,
                            child: Text('Marcar como pagado'),
                          ),
                        const PopupMenuItem(
                          value: _Accion.anular,
                          child: Text('Anular'),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Estado(prestamo: prestamo, vencido: vencido),
                      Text(
                        'Vence ${fechaCorta(datos.fechaVencimiento)}',
                        style: const TextStyle(color: tintaSuave, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '${soles(datos.monto)} · ${porcentaje(datos.interes)}',
                          style: const TextStyle(
                            color: tintaSuave,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(color: tintaSuave, fontSize: 12),
                            ),
                            Text(
                              soles(prestamo.totalCobrar),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: verdeCartera,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _Estado extends StatelessWidget {
  const _Estado({required this.prestamo, required this.vencido});

  final Prestamo prestamo;
  final bool vencido;

  @override
  Widget build(BuildContext context) {
    final (texto, fondo, tinta) = switch ((prestamo.pagado, vencido)) {
      (true, _) => (
        'Cobrado',
        const Color(0xFFDFF1E8),
        const Color(0xFF205D46),
      ),
      (_, true) => (
        'Vencido',
        const Color(0xFFFBE0D9),
        const Color(0xFF8D3025),
      ),
      _ => ('Pendiente', const Color(0xFFF5EBCC), const Color(0xFF68531E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: tinta,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.nombre, this.valor, {this.destacado = false});

  final String nombre;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(nombre, style: const TextStyle(color: tintaSuave)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
