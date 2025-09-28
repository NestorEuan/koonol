class AcumCorteTipoPagoMdl {
  final int idCorteCaja;
  final int idTipoPago;
  final double nImporte;
  final DateTime dtAlta;

  AcumCorteTipoPagoMdl({
    required this.idCorteCaja,
    required this.idTipoPago,
    required this.nImporte,
    required this.dtAlta,
  });

  factory AcumCorteTipoPagoMdl.fromMap(Map<String, dynamic> map) {
    return AcumCorteTipoPagoMdl(
      idCorteCaja: map['idCorteCaja'],
      idTipoPago: map['idTipoPago'],
      nImporte: map['nImporte']?.toDouble() ?? 0.0,
      dtAlta: DateTime.parse(map['dtAlta']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idCorteCaja': idCorteCaja,
      'idTipoPago': idTipoPago,
      'nImporte': nImporte,
      'dtAlta': dtAlta.toIso8601String(),
    };
  }
}
