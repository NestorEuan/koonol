class ArticuloMdl {
  final int? idArticulo;
  final int idClasificacion;
  final String cCodigo;
  final String cDescripcion;
  final double nPrecio;
  final double nCosto;
  final double existencia;

  ArticuloMdl({
    this.idArticulo,
    required this.idClasificacion,
    required this.cCodigo,
    required this.cDescripcion,
    required this.nPrecio,
    required this.nCosto,
    required this.existencia,
  });

  // Constructor para crear desde Map
  factory ArticuloMdl.fromMap(Map<String, dynamic> map) {
    return ArticuloMdl(
      idArticulo: map['idArticulo']?.toInt(),
      idClasificacion: map['idClasificacion']?.toInt() ?? 0,
      cCodigo: map['cCodigo'] ?? '',
      cDescripcion: map['cDescripcion'] ?? '',
      nPrecio: (map['nPrecio'] ?? 0.0).toDouble(),
      nCosto: (map['nCosto'] ?? 0.0).toDouble(),
      existencia: (map['existencia'] ?? 0.0).toDouble(),
    );
  }

  // Método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'idArticulo': idArticulo,
      'idClasificacion': idClasificacion,
      'cCodigo': cCodigo,
      'cDescripcion': cDescripcion,
      'nPrecio': nPrecio,
      'nCosto': nCosto,
      'existencia': existencia,
    };
  }

  // Método para crear una copia con campos modificados
  ArticuloMdl copyWith({
    int? idArticulo,
    int? idClasificacion,
    String? cCodigo,
    String? cDescripcion,
    double? nPrecio,
    double? nCosto,
  }) {
    return ArticuloMdl(
      idArticulo: idArticulo ?? this.idArticulo,
      idClasificacion: idClasificacion ?? this.idClasificacion,
      cCodigo: cCodigo ?? this.cCodigo,
      cDescripcion: cDescripcion ?? this.cDescripcion,
      nPrecio: nPrecio ?? this.nPrecio,
      nCosto: nCosto ?? this.nCosto,
      existencia: existencia,
    );
  }

  @override
  String toString() {
    return 'ArticuloMdl{idArticulo: $idArticulo, idClasificacion: $idClasificacion, cCodigo: $cCodigo, cDescripcion: $cDescripcion, nPrecio: $nPrecio, nCosto: $nCosto}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArticuloMdl &&
        other.idArticulo == idArticulo &&
        other.idClasificacion == idClasificacion &&
        other.cCodigo == cCodigo &&
        other.cDescripcion == cDescripcion &&
        other.nPrecio == nPrecio &&
        other.nCosto == nCosto &&
        other.existencia == existencia;
  }

  @override
  int get hashCode {
    return idArticulo.hashCode ^
        idClasificacion.hashCode ^
        cCodigo.hashCode ^
        cDescripcion.hashCode ^
        nPrecio.hashCode ^
        nCosto.hashCode ^
        existencia.hashCode;
  }
}
