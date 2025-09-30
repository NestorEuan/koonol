class UsuarioMdl {
  final int? idUsuario;
  final String cUsuario;
  final String cNombre;
  final String cContrasena;

  UsuarioMdl({
    this.idUsuario,
    required this.cUsuario,
    required this.cNombre,
    required this.cContrasena,
  });

  // Constructor para crear desde Map
  factory UsuarioMdl.fromMap(Map<String, dynamic> map) {
    return UsuarioMdl(
      idUsuario: map['idUsuario']?.toInt(),
      cUsuario: map['cUsuario'] ?? '',
      cNombre: map['cNombre'] ?? '',
      cContrasena: map['cContrasena'] ?? '',
    );
  }

  // Método para convertir a Map
  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'cUsuario': cUsuario,
      'cNombre': cNombre,
      'cContrasena': cContrasena,
    };
  }

  // Método para crear una copia con campos modificados
  UsuarioMdl copyWith({
    int? idUsuario,
    String? cUsuario,
    String? cNombre,
    String? cContrasena,
  }) {
    return UsuarioMdl(
      idUsuario: idUsuario ?? this.idUsuario,
      cUsuario: cUsuario ?? this.cUsuario,
      cNombre: cNombre ?? this.cNombre,
      cContrasena: cContrasena ?? this.cContrasena,
    );
  }

  @override
  String toString() {
    return 'UsuarioMdl{idUsuario: $idUsuario, cUsuario: $cUsuario, cNombre: $cNombre}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsuarioMdl &&
        other.idUsuario == idUsuario &&
        other.cUsuario == cUsuario &&
        other.cNombre == cNombre &&
        other.cContrasena == cContrasena;
  }

  @override
  int get hashCode {
    return idUsuario.hashCode ^
        cUsuario.hashCode ^
        cNombre.hashCode ^
        cContrasena.hashCode;
  }
}
