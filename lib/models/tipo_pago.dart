class TipoPago {
  final int idTipoPago;
  final String descripcion;

  TipoPago({required this.idTipoPago, required this.descripcion});

  factory TipoPago.fromJson(Map<String, dynamic> json) {
    return TipoPago(
      idTipoPago: json['idTipoPago'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idTipoPago': idTipoPago, 'descripcion': descripcion};
  }
}
