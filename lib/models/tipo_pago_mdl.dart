class TipoPagoMdl {
  final int? idTipoPago;
  final String cTipoPago;
  final String nComision;

  TipoPagoMdl({
    this.idTipoPago,
    required this.cTipoPago,
    required this.nComision,
  });

  // Constructor para crear desde Map
  factory TipoPagoMdl.fromMap(Map<String, dynamic> map) {
    return TipoPagoMdl(
      idTipoPago: map['idTipoPago']?.toInt(),
      cTipoPago: map['cTipoPago'] ?? '',
      nComision: map['nComision'] ?? '',
    );
  }

  // Método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'idTipoPago': idTipoPago,
      'cTipoPago': cTipoPago,
      'nComision': nComision,
    };
  }

  // Método para crear una copia con campos modificados
  TipoPagoMdl copyWith({
    int? idTipoPago,
    String? cTipoPago,
    String? nComision,
  }) {
    return TipoPagoMdl(
      idTipoPago: idTipoPago ?? this.idTipoPago,
      cTipoPago: cTipoPago ?? this.cTipoPago,
      nComision: nComision ?? this.nComision,
    );
  }

  @override
  String toString() {
    return 'TipoPago{idTipoPago: $idTipoPago, cTipoPago: $cTipoPago, nComision: $nComision}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TipoPagoMdl &&
        other.idTipoPago == idTipoPago &&
        other.cTipoPago == cTipoPago &&
        other.nComision == nComision;
  }

  @override
  int get hashCode {
    return idTipoPago.hashCode ^ cTipoPago.hashCode ^ nComision.hashCode;
  }
}
