class AcumCorteDetalleMdl {
  final int idCorte;
  final int idArticulo;
  final DateTime dtAlta;
  final double nImporte;
  final double nCosto;

  AcumCorteDetalleMdl({
    required this.idCorte,
    required this.idArticulo,
    required this.dtAlta,
    required this.nImporte,
    required this.nCosto,
  });

  factory AcumCorteDetalleMdl.fromMap(Map<String, dynamic> map) {
    return AcumCorteDetalleMdl(
      idCorte: map['idCorte'],
      idArticulo: map['idArticulo'],
      dtAlta: DateTime.parse(map['dtAlta']),
      nImporte: map['nImporte']?.toDouble() ?? 0.0,
      nCosto: map['nCosto']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idCorte': idCorte,
      'idArticulo': idArticulo,
      'dtAlta': dtAlta.toIso8601String(),
      'nImporte': nImporte,
      'nCosto': nCosto,
    };
  }

  // Método para calcular la ganancia
  double get ganancia => nImporte - nCosto;
}
