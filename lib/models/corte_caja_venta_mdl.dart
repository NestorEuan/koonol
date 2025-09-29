class CorteCajaVentaMdl {
  final int idCorteCaja;
  final int idVenta;
  final double nImporte;
  final double nIVA;
  final double nDescuento;
  final DateTime dtAlta;

  CorteCajaVentaMdl({
    required this.idCorteCaja,
    required this.idVenta,
    required this.nImporte,
    required this.nIVA,
    required this.nDescuento,
    required this.dtAlta,
  });

  factory CorteCajaVentaMdl.fromMap(Map<String, dynamic> map) {
    return CorteCajaVentaMdl(
      idCorteCaja: map['idCorteCaja'],
      idVenta: map['idVenta'],
      nImporte: map['nImporte']?.toDouble() ?? 0.0,
      nIVA: map['nIVA']?.toDouble() ?? 0.0,
      nDescuento: map['nDescuento']?.toDouble() ?? 0.0,
      dtAlta: DateTime.parse(map['dtAlta']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idCorteCaja': idCorteCaja,
      'idVenta': idVenta,
      'nImporte': nImporte,
      'nIVA': nIVA,
      'nDescuento': nDescuento,
      'dtAlta': dtAlta.toIso8601String(),
    };
  }
}
