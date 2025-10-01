class VentaMdl {
  final int? idVenta;
  final int idCliente;
  final double nImporte;
  final double nIVA;
  final double nDescuento;
  final double nTotalPagado;
  final double nCambio;
  final DateTime dtAlta;
  final DateTime dtFecha;
  final String cEstado; // NUEVO: 'ACTIVA', 'CANCELADA'

  VentaMdl({
    this.idVenta,
    required this.idCliente,
    required this.nImporte,
    required this.nIVA,
    required this.nDescuento,
    required this.nTotalPagado,
    required this.nCambio,
    required this.dtAlta,
    required this.dtFecha,
    this.cEstado = 'ACTIVA', // NUEVO: valor por defecto
  });

  factory VentaMdl.fromMap(Map<String, dynamic> map) {
    return VentaMdl(
      idVenta: map['idVenta'],
      idCliente: map['idCliente'],
      nImporte: map['nImporte']?.toDouble() ?? 0.0,
      nIVA: map['nIVA']?.toDouble() ?? 0.0,
      nDescuento: map['nDescuento']?.toDouble() ?? 0.0,
      nTotalPagado: map['nTotalPagado']?.toDouble() ?? 0.0,
      nCambio: map['nCambio']?.toDouble() ?? 0.0,
      dtAlta: DateTime.parse(map['dtAlta']),
      dtFecha: DateTime.parse(map['dtFecha']),
      cEstado: map['cEstado'] ?? 'ACTIVA', // NUEVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idVenta': idVenta,
      'idCliente': idCliente,
      'nImporte': nImporte,
      'nIVA': nIVA,
      'nDescuento': nDescuento,
      'nTotalPagado': nTotalPagado,
      'nCambio': nCambio,
      'dtAlta': dtAlta.toIso8601String(),
      'dtFecha': dtFecha.toIso8601String().split('T')[0],
      'cEstado': cEstado, // NUEVO
    };
  }

  // Método para calcular el total de la venta
  double get total => nImporte + nIVA - nDescuento;

  // NUEVO: Método para verificar si está activa
  bool get estaActiva => cEstado == 'ACTIVA';

  // NUEVO: Método para verificar si está cancelada
  bool get estaCancelada => cEstado == 'CANCELADA';

  VentaMdl copyWith({
    int? idVenta,
    int? idCliente,
    double? nImporte,
    double? nIVA,
    double? nDescuento,
    double? nTotalPagado,
    double? nCambio,
    DateTime? dtAlta,
    DateTime? dtFecha,
    String? cEstado, // NUEVO
  }) {
    return VentaMdl(
      idVenta: idVenta ?? this.idVenta,
      idCliente: idCliente ?? this.idCliente,
      nImporte: nImporte ?? this.nImporte,
      nIVA: nIVA ?? this.nIVA,
      nDescuento: nDescuento ?? this.nDescuento,
      nTotalPagado: nTotalPagado ?? this.nTotalPagado,
      nCambio: nCambio ?? this.nCambio,
      dtAlta: dtAlta ?? this.dtAlta,
      dtFecha: dtFecha ?? this.dtFecha,
      cEstado: cEstado ?? this.cEstado, // NUEVO
    );
  }
}
