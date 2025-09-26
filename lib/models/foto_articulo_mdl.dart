class FotoArticuloMdl {
  final int idArticulo;
  final int idFoto;
  final String cNombre;
  final String cRuta;

  FotoArticuloMdl({
    required this.idArticulo,
    required this.idFoto,
    required this.cNombre,
    required this.cRuta,
  });

  // Constructor para crear desde Map
  factory FotoArticuloMdl.fromMap(Map<String, dynamic> map) {
    return FotoArticuloMdl(
      idArticulo: map['idArticulo']?.toInt() ?? 0,
      idFoto: map['idFoto']?.toInt() ?? 0,
      cNombre: map['cNombre'] ?? '',
      cRuta: map['cRuta'] ?? '',
    );
  }

  // Método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'idArticulo': idArticulo,
      'idFoto': idFoto,
      'cNombre': cNombre,
      'cRuta': cRuta,
    };
  }

  // Método para crear una copia con campos modificados
  FotoArticuloMdl copyWith({
    int? idArticulo,
    int? idFoto,
    String? cNombre,
    String? cRuta,
  }) {
    return FotoArticuloMdl(
      idArticulo: idArticulo ?? this.idArticulo,
      idFoto: idFoto ?? this.idFoto,
      cNombre: cNombre ?? this.cNombre,
      cRuta: cRuta ?? this.cRuta,
    );
  }

  @override
  String toString() {
    return 'FotoArticuloMdl{idArticulo: $idArticulo, idFoto: $idFoto, cNombre: $cNombre, cRuta: $cRuta}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FotoArticuloMdl &&
        other.idArticulo == idArticulo &&
        other.idFoto == idFoto &&
        other.cNombre == cNombre &&
        other.cRuta == cRuta;
  }

  @override
  int get hashCode {
    return idArticulo.hashCode ^
        idFoto.hashCode ^
        cNombre.hashCode ^
        cRuta.hashCode;
  }
}
