class Cliente {
  final int idCliente;
  final String tipo;
  final String nombre;
  final String direccion;
  final String telefono;
  final String rfc;
  final String mail;
  final bool estatus;
  final DateTime fechaAlta;
  final DateTime? fechaBaja;

  Cliente({
    required this.idCliente,
    required this.tipo,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.rfc,
    required this.mail,
    required this.estatus,
    required this.fechaAlta,
    this.fechaBaja,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['idcliente'],
      tipo: json['tipo'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      rfc: json['RFC'],
      mail: json['mail'],
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
      'idcliente': idCliente,
      'tipo': tipo,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'RFC': rfc,
      'mail': mail,
      'estatus': estatus,
      'fecha_alta': fechaAlta.toIso8601String(),
      'fecha_baja': fechaBaja?.toIso8601String(),
    };
  }
}
