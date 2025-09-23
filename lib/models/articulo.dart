class Articulo {
  final int id;
  final String codigo;
  final String descripcion;
  final double precio;
  final int existencia;
  final int idClasificacion;
  final bool estatus;
  final DateTime fechaAlta;
  final DateTime? fechaBaja;

  Articulo({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.precio,
    required this.existencia,
    required this.idClasificacion,
    required this.estatus,
    required this.fechaAlta,
    this.fechaBaja,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      id: json['id'],
      codigo: json['codigo'],
      descripcion: json['descripcion'],
      precio: json['precio'].toDouble(),
      existencia: json['existencia'],
      idClasificacion: json['idClasificacion'],
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
      'codigo': codigo,
      'descripcion': descripcion,
      'precio': precio,
      'existencia': existencia,
      'idClasificacion': idClasificacion,
      'estatus': estatus,
      'fecha_alta': fechaAlta.toIso8601String(),
      'fecha_baja': fechaBaja?.toIso8601String(),
    };
  }
}
