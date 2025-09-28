class VentaTipoPagoMdl {
  final int idVenta;
  final int idTipoPago; // 1=Efectivo, 2=Tarjeta, 3=Transferencia, etc.
  final double nImporte;
  final DateTime dtAlta;

  VentaTipoPagoMdl({
    required this.idVenta,
    required this.idTipoPago,
    required this.nImporte,
    required this.dtAlta,
  });

  factory VentaTipoPagoMdl.fromMap(Map<String, dynamic> map) {
    return VentaTipoPagoMdl(
      idVenta: map['idVenta'],
      idTipoPago: map['idTipoPago'],
      nImporte: map['nImporte']?.toDouble() ?? 0.0,
      dtAlta: DateTime.parse(map['dtAlta']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idVenta': idVenta,
      'idTipoPago': idTipoPago,
      'nImporte': nImporte,
      'dtAlta': dtAlta.toIso8601String(),
    };
  }
}
