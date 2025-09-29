class VentaDetalleMdl {
  final int idVenta;
  final int idArticulo;
  final int idPrecio; // Referencia al precio usado en el momento de la venta
  final double nCantidad; // Cantidad vendida
  final double nPrecio;
  final double nCosto;
  final DateTime dtAlta;

  VentaDetalleMdl({
    required this.idVenta,
    required this.idArticulo,
    required this.idPrecio,
    required this.nCantidad,
    required this.nPrecio,
    required this.nCosto,
    required this.dtAlta,
  });

  factory VentaDetalleMdl.fromMap(Map<String, dynamic> map) {
    return VentaDetalleMdl(
      idVenta: map['idVenta'],
      idArticulo: map['idArticulo'],
      idPrecio: map['idPrecio'],
      nCantidad: map['nCantidad']?.toDouble() ?? 1.0,
      nPrecio: map['nPrecio']?.toDouble() ?? 0.0,
      nCosto: map['nCosto']?.toDouble() ?? 0.0,
      dtAlta: DateTime.parse(map['dtAlta']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idVenta': idVenta,
      'idArticulo': idArticulo,
      'idPrecio': idPrecio,
      'nCantidad': nCantidad,
      'nPrecio': nPrecio,
      'nCosto': nCosto,
      'dtAlta': dtAlta.toIso8601String(),
    };
  }

  /// Calcula el subtotal (precio * cantidad)
  double get subtotal => nPrecio * nCantidad;

  /// Calcula el costo total (costo * cantidad)
  double get costoTotal => nCosto * nCantidad;

  /// Calcula la ganancia total por este detalle
  double get gananciaTotal => subtotal - costoTotal;

  /// Calcula el margen de ganancia (%)
  double get margenGanancia =>
      costoTotal > 0 ? (gananciaTotal / costoTotal) * 100 : 0;

  /// Calcula la ganancia unitaria
  double get gananciaUnitaria => nPrecio - nCosto;

  VentaDetalleMdl copyWith({
    int? idVenta,
    int? idArticulo,
    int? idPrecio,
    double? nCantidad,
    double? nPrecio,
    double? nCosto,
    DateTime? dtAlta,
  }) {
    return VentaDetalleMdl(
      idVenta: idVenta ?? this.idVenta,
      idArticulo: idArticulo ?? this.idArticulo,
      idPrecio: idPrecio ?? this.idPrecio,
      nCantidad: nCantidad ?? this.nCantidad,
      nPrecio: nPrecio ?? this.nPrecio,
      nCosto: nCosto ?? this.nCosto,
      dtAlta: dtAlta ?? this.dtAlta,
    );
  }

  @override
  String toString() {
    return 'VentaDetalleMdl{idVenta: $idVenta, idArticulo: $idArticulo, cantidad: $nCantidad, subtotal: ${subtotal.toStringAsFixed(2)}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VentaDetalleMdl &&
        other.idVenta == idVenta &&
        other.idArticulo == idArticulo &&
        other.idPrecio == idPrecio &&
        other.nCantidad == nCantidad &&
        other.nPrecio == nPrecio &&
        other.nCosto == nCosto;
  }

  @override
  int get hashCode {
    return idVenta.hashCode ^
        idArticulo.hashCode ^
        idPrecio.hashCode ^
        nCantidad.hashCode ^
        nPrecio.hashCode ^
        nCosto.hashCode;
  }
}
