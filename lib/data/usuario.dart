import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/usuario_mdl.dart';
import 'base_crud_repository.dart';
import 'database_manager.dart';

class Usuario extends BaseCrudRepository<UsuarioMdl> {
  // Constructor privado
  Usuario._internal(super.database);

  // Singleton pattern para esta clase
  static Usuario? _instance;

  // Factory constructor que usa el DatabaseManager
  static Future<Usuario> getInstance() async {
    if (_instance == null) {
      final dbManager = DatabaseManager();
      final database = await dbManager.database;
      _instance = Usuario._internal(database);
    }
    return _instance!;
  }

  @override
  String get tableName => 'usuario';

  @override
  String get idColumnName => 'idUsuario';

  @override
  UsuarioMdl fromMap(Map<String, dynamic> map) {
    return UsuarioMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(UsuarioMdl item) {
    return item.toMap();
  }

  // Métodos específicos para Usuario

  /// Encripta una contraseña usando SHA-256
  String encriptarContrasena(String contrasena) {
    final bytes = utf8.encode(contrasena);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Valida las credenciales del usuario
  /// Retorna el usuario si las credenciales son correctas, null si no
  Future<UsuarioMdl?> validarCredenciales(
    String usuario,
    String contrasena,
  ) async {
    try {
      final contrasenaEncriptada = encriptarContrasena(contrasena);

      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'cUsuario = ? AND cContrasena = ?',
        whereArgs: [usuario, contrasenaEncriptada],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al validar credenciales: $e');
    }
  }

  /// Buscar usuario por nombre de usuario
  Future<UsuarioMdl?> buscarPorUsuario(String usuario) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'cUsuario = ?',
        whereArgs: [usuario],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al buscar usuario: $e');
    }
  }

  /// Verificar si existe un usuario con el mismo nombre
  Future<bool> existePorUsuario(String usuario, {int? excludeId}) async {
    try {
      String whereClause = 'LOWER(cUsuario) = LOWER(?)';
      List<dynamic> whereArgs = [usuario];

      if (excludeId != null) {
        whereClause += ' AND idUsuario != ?';
        whereArgs.add(excludeId);
      }

      final result = await database.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia de usuario: $e');
    }
  }

  /// Actualizar contraseña de un usuario
  Future<int> actualizarContrasena(int id, String nuevaContrasena) async {
    try {
      final contrasenaEncriptada = encriptarContrasena(nuevaContrasena);
      return await updateCustom('cContrasena = ?', 'idUsuario = ?', [
        contrasenaEncriptada,
        id,
      ]);
    } catch (e) {
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  /// Crear usuario con contraseña encriptada
  Future<int> crearUsuarioSeguro(UsuarioMdl usuario) async {
    try {
      final usuarioEncriptado = usuario.copyWith(
        cContrasena: encriptarContrasena(usuario.cContrasena),
      );
      return await create(usuarioEncriptado);
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  /// Obtener todos los usuarios (sin contraseñas)
  Future<List<UsuarioMdl>> getAllUsuariosSinContrasena() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        columns: ['idUsuario', 'cUsuario', 'cNombre'],
      );
      return maps.map((map) {
        map['cContrasena'] = ''; // Agregar campo vacío
        return fromMap(map);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }
}

// NOTA: Este es el final del archivo usuario.dart
// Combina la Parte 1 y la Parte 2 en un solo archivo
