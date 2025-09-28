class CorteCajaMdl {
  final int? idCorteCaja;
  final int idSucursal;
  final int idUsuario;
  final DateTime dtAlta;
  final DateTime dtFecha; // Fecha del corte (sin hora)
  final String cEstado; // 'ABIERTO', 'CERRADO'
  final double nImporte;

  CorteCajaMdl({
    this.idCorteCaja,
    required this.idSucursal,
    required this.idUsuario,
    required this.dtAlta,
    required this.dtFecha,
    required this.cEstado,
    required this.nImporte,
  });

  factory CorteCajaMdl.fromMap(Map<String, dynamic> map) {
    return CorteCajaMdl(
      idCorteCaja: map['idCorteCaja'],
      idSucursal: map['idSucursal'],
      idUsuario: map['idUsuario'],
      dtAlta: DateTime.parse(map['dtAlta']),
      dtFecha: DateTime.parse(map['dtFecha']),
      cEstado: map['cEstado'],
      nImporte: map['nImporte']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idCorteCaja': idCorteCaja,
      'idSucursal': idSucursal,
      'idUsuario': idUsuario,
      'dtAlta': dtAlta.toIso8601String(),
      'dtFecha': dtFecha.toIso8601String().split('T')[0], // Solo fecha
      'cEstado': cEstado,
      'nImporte': nImporte,
    };
  }

  CorteCajaMdl copyWith({
    int? idCorteCaja,
    int? idSucursal,
    int? idUsuario,
    DateTime? dtAlta,
    DateTime? dtFecha,
    String? cEstado,
    double? nImporte,
  }) {
    return CorteCajaMdl(
      idCorteCaja: idCorteCaja ?? this.idCorteCaja,
      idSucursal: idSucursal ?? this.idSucursal,
      idUsuario: idUsuario ?? this.idUsuario,
      dtAlta: dtAlta ?? this.dtAlta,
      dtFecha: dtFecha ?? this.dtFecha,
      cEstado: cEstado ?? this.cEstado,
      nImporte: nImporte ?? this.nImporte,
    );
  }
}
