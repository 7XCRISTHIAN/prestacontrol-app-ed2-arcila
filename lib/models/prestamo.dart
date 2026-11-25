class PrestamoDatos {
  const PrestamoDatos({
    required this.cliente,
    required this.dni,
    required this.monto,
    required this.interes,
    required this.fechaVencimiento,
    this.pagado,
  });

  final String cliente;
  final String dni;
  final double monto;
  final double interes;
  final DateTime fechaVencimiento;
  final bool? pagado;

  Map<String, Object> toJson() => {
    'cliente': cliente,
    'dni': dni,
    'monto': monto,
    'interes': interes,
    'fechaVencimiento': fechaVencimiento.toIso8601String().split('T').first,
    if (pagado case final bool estado) 'pagado': estado,
  };
}

class Prestamo {
  const Prestamo({
    required this.id,
    required this.datos,
    required this.fechaPrestamo,
    required this.totalCobrar,
  });

  final int id;
  final PrestamoDatos datos;
  final DateTime fechaPrestamo;
  final double totalCobrar;

  bool get pagado => datos.pagado ?? false;

  bool vencidoAl(DateTime dia) =>
      !pagado && datos.fechaVencimiento.isBefore(dia);

  PrestamoDatos marcarPagado() => PrestamoDatos(
    cliente: datos.cliente,
    dni: datos.dni,
    monto: datos.monto,
    interes: datos.interes,
    fechaVencimiento: datos.fechaVencimiento,
    pagado: true,
  );

  factory Prestamo.fromJson(Map<String, dynamic> json) => Prestamo(
    id: json['id'] as int,
    datos: PrestamoDatos(
      cliente: json['cliente'] as String,
      dni: json['dni'] as String,
      monto: (json['monto'] as num).toDouble(),
      interes: (json['interes'] as num).toDouble(),
      fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
      pagado: json['pagado'] as bool,
    ),
    fechaPrestamo: DateTime.parse(json['fechaPrestamo'] as String),
    totalCobrar: (json['totalCobrar'] as num).toDouble(),
  );
}

class ResumenCartera {
  const ResumenCartera({
    required this.capitalPrestado,
    required this.totalPorCobrar,
    required this.gananciaEsperada,
  });

  final double capitalPrestado;
  final double totalPorCobrar;
  final double gananciaEsperada;

  factory ResumenCartera.fromJson(Map<String, dynamic> json) => ResumenCartera(
    capitalPrestado: (json['capitalPrestado'] as num).toDouble(),
    totalPorCobrar: (json['totalPorCobrar'] as num).toDouble(),
    gananciaEsperada: (json['gananciaEsperada'] as num).toDouble(),
  );
}
