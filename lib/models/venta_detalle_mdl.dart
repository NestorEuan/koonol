class VentaDetalleMdl {
  final int idVenta;
  final int idArticulo;
  final int idPrecio; // Referencia al precio usado en el momento de la venta
  final double nPrecio;
  final double nCosto;
  final DateTime dtAlta;

  VentaDetalleMdl({
    required this.idVenta,
    required this.idArticulo,
    required this.idPrecio,
    required this.nPrecio,
    required this.nCosto,
    required this.dtAlta,
  });

  factory VentaDetalleMdl.fromMap(Map<String, dynamic> map) {
    return VentaDetalleMdl(
      idVenta: map['idVenta'],
      idArticulo: map['idArticulo'],
      idPrecio: map['idPrecio'],
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
      'nPrecio': nPrecio,
      'nCosto': nCosto,
      'dtAlta': dtAlta.toIso8601String(),
    };
  }

  // Método para calcular la ganancia por artículo
  double get ganancia => nPrecio - nCosto;

  // Método para calcular el margen de ganancia (%)
  double get margenGanancia =>
      nCosto > 0 ? ((nPrecio - nCosto) / nCosto) * 100 : 0;
}
