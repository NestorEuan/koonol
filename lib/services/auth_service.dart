import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koonol/models/usuario_mdl.dart';
import 'package:koonol/data/usuario.dart';

/// Servicio de autenticación
/// Maneja el login, logout y sesión del usuario
class AuthService {
  static const String _keyIdUsuario = 'idUsuario';
  static const String _keyNombreUsuario = 'nombreUsuario';
  static const String _keyUsuario = 'usuario';

  static AuthService? _instance;
  late final Usuario _usuarioRepository;

  // Datos de sesión en memoria
  int? _idUsuarioActual;
  String? _nombreUsuarioActual;
  String? _usuarioActual;

  // Singleton pattern
  AuthService._internal();

  static Future<AuthService> getInstance() async {
    if (_instance == null) {
      _instance = AuthService._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Inicializa el repositorio y carga la sesión si existe
  Future<void> _initialize() async {
    _usuarioRepository = await Usuario.getInstance();
    await _cargarSesion();
  }

  /// Getters para datos de sesión
  int? get idUsuarioActual => _idUsuarioActual;
  String? get nombreUsuarioActual => _nombreUsuarioActual;
  String? get usuarioActual => _usuarioActual;
  bool get estaAutenticado => _idUsuarioActual != null;

  /// Intenta hacer login con las credenciales proporcionadas
  Future<Map<String, dynamic>> login(String usuario, String contrasena) async {
    try {
      if (kDebugMode) {
        print('🔐 Intentando login para usuario: $usuario');
      }

      // Validar que no estén vacíos
      if (usuario.trim().isEmpty || contrasena.trim().isEmpty) {
        return {
          'success': false,
          'mensaje': 'Usuario y contraseña son requeridos',
        };
      }

      // Validar credenciales
      final UsuarioMdl? usuarioValidado = await _usuarioRepository
          .validarCredenciales(usuario.trim(), contrasena);

      if (usuarioValidado == null) {
        if (kDebugMode) {
          print('❌ Credenciales inválidas');
        }
        return {
          'success': false,
          'mensaje': 'Usuario o contraseña incorrectos',
        };
      }

      // Guardar sesión
      await _guardarSesion(
        usuarioValidado.idUsuario!,
        usuarioValidado.cNombre,
        usuarioValidado.cUsuario,
      );

      if (kDebugMode) {
        print('✅ Login exitoso: ${usuarioValidado.cNombre}');
      }

      return {
        'success': true,
        'mensaje': 'Bienvenido ${usuarioValidado.cNombre}',
        'usuario': usuarioValidado,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en login: $e');
      }
      return {'success': false, 'mensaje': 'Error al iniciar sesión: $e'};
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    try {
      if (kDebugMode) {
        print('👋 Cerrando sesión de: $_nombreUsuarioActual');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIdUsuario);
      await prefs.remove(_keyNombreUsuario);
      await prefs.remove(_keyUsuario);

      _idUsuarioActual = null;
      _nombreUsuarioActual = null;
      _usuarioActual = null;

      if (kDebugMode) {
        print('✅ Sesión cerrada correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cerrar sesión: $e');
      }
    }
  }

  /// Guarda los datos de sesión
  Future<void> _guardarSesion(
    int idUsuario,
    String nombreUsuario,
    String usuario,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyIdUsuario, idUsuario);
      await prefs.setString(_keyNombreUsuario, nombreUsuario);
      await prefs.setString(_keyUsuario, usuario);

      _idUsuarioActual = idUsuario;
      _nombreUsuarioActual = nombreUsuario;
      _usuarioActual = usuario;

      if (kDebugMode) {
        print('💾 Sesión guardada: ID=$idUsuario, Nombre=$nombreUsuario');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al guardar sesión: $e');
      }
      throw Exception('Error al guardar sesión: $e');
    }
  }

  /// Carga la sesión guardada si existe
  Future<void> _cargarSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _idUsuarioActual = prefs.getInt(_keyIdUsuario);
      _nombreUsuarioActual = prefs.getString(_keyNombreUsuario);
      _usuarioActual = prefs.getString(_keyUsuario);

      if (_idUsuarioActual != null) {
        if (kDebugMode) {
          print('📂 Sesión cargada: $_nombreUsuarioActual');
        }
      } else {
        if (kDebugMode) {
          print('📂 No hay sesión guardada');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error al cargar sesión: $e');
      }
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> verificarSesion() async {
    await _cargarSesion();
    return estaAutenticado;
  }

  /// Obtiene los datos del usuario actual
  Future<UsuarioMdl?> obtenerUsuarioActual() async {
    if (!estaAutenticado) return null;

    try {
      return await _usuarioRepository.readById(_idUsuarioActual!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener usuario actual: $e');
      }
      return null;
    }
  }
}

// NOTA: Este es el final del archivo auth_service.dart
// Combina la Parte 1 y la Parte 2 en un solo archivo
