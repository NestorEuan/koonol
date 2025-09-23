class Clasificacion {
  final int id;
  final String descripcion;
  final int? idFoto;
  final bool estatus;
  final DateTime fechaAlta;
  final DateTime? fechaBaja;

  Clasificacion({
    required this.id,
    required this.descripcion,
    this.idFoto,
    required this.estatus,
    required this.fechaAlta,
    this.fechaBaja,
  });

  factory Clasificacion.fromJson(Map<String, dynamic> json) {
    return Clasificacion(
      id: json['id'],
      descripcion: json['descripcion'],
      idFoto: json['idfoto'],
      estatus: json['estatus'],
      fechaAlta: DateTime.parse(json['fecha_alta']),
      fechaBaja:
          json['fecha_baja'] != null
              ? DateTime.parse(json['fecha_baja'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'idfoto': idFoto,
      'estatus': estatus,
      'fecha_alta': fechaAlta.toIso8601String(),
      'fecha_baja': fechaBaja?.toIso8601String(),
    };
  }
}
