import 'package:flutter/foundation.dart';
import '../data/corte_caja.dart';
import '../data/database_manager.dart';
import '../models/corte_caja_mdl.dart';

/// Servicio para manejo de lógica de negocio de Corte de Caja
/// Maneja la validación y creación de cortes diarios
class CorteCajaService {
  static const int _defaultSucursal = 1;
  static const int _defaultUsuario = 1;

  late final CorteCaja _corteCajaRepository;
  static CorteCajaService? _instance;

  // Singleton pattern
  CorteCajaService._internal();

  static Future<CorteCajaService> getInstance() async {
    if (_instance == null) {
      _instance = CorteCajaService._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Inicializa el repositorio
  Future<void> _initialize() async {
    final dbManager = DatabaseManager();
    final database = await dbManager.database;
    _corteCajaRepository = CorteCaja(database);
  }

  /// Obtiene o crea el corte del día actual
  /// Returns: CorteCajaMdl del corte activo del día
  Future<CorteCajaMdl> obtenerOCrearCorteDelDia({
    int? idSucursal,
    int? idUsuario,
  }) async {
    try {
      final DateTime hoy = DateTime.now();
      final int sucursal = idSucursal ?? _defaultSucursal;
      final int usuario = idUsuario ?? _defaultUsuario;

      if (kDebugMode) {
        print(
          '🔍 Verificando corte del día para fecha: ${_formatearFecha(hoy)}',
        );
      }

      // Verificar si ya existe un corte para el día actual
      CorteCajaMdl? corteExistente = await _corteCajaRepository
          .getCorteDiaActivo(hoy, sucursal);

      if (corteExistente != null) {
        if (kDebugMode) {
          print(
            '✅ Corte existente encontrado: ID ${corteExistente.idCorteCaja}',
          );
        }
        return corteExistente;
      }

      // No existe corte, crear uno nuevo
      if (kDebugMode) {
        print('📝 Creando nuevo corte del día...');
      }

      final int idCorteCreado = await _corteCajaRepository.crearCorteDelDia(
        sucursal,
        usuario,
      );

      // Obtener el corte recién creado
      final CorteCajaMdl? corteCreado = await _corteCajaRepository.readById(
        idCorteCreado,
      );

      if (corteCreado == null) {
        throw Exception('Error al recuperar el corte creado');
      }

      if (kDebugMode) {
        print('✅ Corte creado exitosamente: ID ${corteCreado.idCorteCaja}');
      }

      return corteCreado;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en obtenerOCrearCorteDelDia: $e');
      }
      throw Exception('Error al obtener o crear corte del día: $e');
    }
  }

  /// Verifica el estado del corte actual
  /// Returns: Map con información del estado del corte
  Future<Map<String, dynamic>> verificarEstadoCorte({int? idSucursal}) async {
    try {
      final DateTime hoy = DateTime.now();
      final int sucursal = idSucursal ?? _defaultSucursal;

      final CorteCajaMdl? corte = await _corteCajaRepository.getCorteDiaActivo(
        hoy,
        sucursal,
      );

      if (corte == null) {
        return {
          'existe': false,
          'estado': 'NO_EXISTE',
          'mensaje': 'No hay corte activo para el día',
          'fecha': _formatearFecha(hoy),
        };
      }

      return {
        'existe': true,
        'corte': corte,
        'estado': corte.cEstado,
        'mensaje': corte.cEstado == 'ABIERTO'
            ? 'Corte activo y disponible'
            : 'Corte cerrado',
        'fecha': _formatearFecha(corte.dtFecha),
        'importe': corte.nImporte,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en verificarEstadoCorte: $e');
      }
      throw Exception('Error al verificar estado del corte: $e');
    }
  }

  /// Cierra el corte del día con el importe total
  Future<bool> cerrarCorte(int idCorteCaja, double importeTotal) async {
    try {
      if (kDebugMode) {
        print(
          '🔒 Cerrando corte ID: $idCorteCaja con importe: \$${importeTotal.toStringAsFixed(2)}',
        );
      }

      final int filasAfectadas = await _corteCajaRepository.cerrarCorte(
        idCorteCaja,
        importeTotal,
      );

      if (filasAfectadas > 0) {
        if (kDebugMode) {
          print('✅ Corte cerrado exitosamente');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ No se pudo cerrar el corte - No se encontró el registro');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cerrar corte: $e');
      }
      throw Exception('Error al cerrar corte: $e');
    }
  }

  /// Actualiza el importe total del corte
  Future<bool> actualizarImporteCorte(
    int idCorteCaja,
    double nuevoImporte,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '💰 Actualizando importe del corte ID: $idCorteCaja a: \$${nuevoImporte.toStringAsFixed(2)}',
        );
      }

      final int filasAfectadas = await _corteCajaRepository.actualizarImporte(
        idCorteCaja,
        nuevoImporte,
      );

      return filasAfectadas > 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al actualizar importe del corte: $e');
      }
      throw Exception('Error al actualizar importe del corte: $e');
    }
  }

  /// Valida si se puede realizar una venta en el corte actual
  Future<Map<String, dynamic>> validarVentaPermitida({int? idSucursal}) async {
    try {
      final estadoCorte = await verificarEstadoCorte(idSucursal: idSucursal);

      if (!estadoCorte['existe']) {
        return {
          'permitida': false,
          'razon': 'NO_CORTE',
          'mensaje': 'No existe corte activo para realizar ventas',
        };
      }

      final String estado = estadoCorte['estado'];
      if (estado == 'CERRADO') {
        return {
          'permitida': false,
          'razon': 'CORTE_CERRADO',
          'mensaje':
              'El corte del día está cerrado, no se pueden realizar ventas',
        };
      }

      return {
        'permitida': true,
        'corte': estadoCorte['corte'],
        'mensaje': 'Venta permitida en el corte activo',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en validarVentaPermitida: $e');
      }
      return {
        'permitida': false,
        'razon': 'ERROR',
        'mensaje': 'Error al validar permisos de venta: $e',
      };
    }
  }

  /// Inicializa el sistema de cortes al inicio de la aplicación
  /// Debe llamarse al iniciar la aplicación
  Future<Map<String, dynamic>> inicializarSistemaCortes({
    int? idSucursal,
    int? idUsuario,
  }) async {
    try {
      if (kDebugMode) {
        print('🚀 Inicializando sistema de cortes de caja...');
      }

      final corte = await obtenerOCrearCorteDelDia(
        idSucursal: idSucursal,
        idUsuario: idUsuario,
      );

      final estadoCorte = await verificarEstadoCorte(idSucursal: idSucursal);

      if (kDebugMode) {
        print('✅ Sistema de cortes inicializado correctamente');
        print(
          '📊 Corte activo: ID ${corte.idCorteCaja} - Estado: ${corte.cEstado}',
        );
      }

      return {
        'inicializado': true,
        'corte': corte,
        'estado': estadoCorte,
        'mensaje': 'Sistema de cortes inicializado correctamente',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar sistema de cortes: $e');
      }
      return {
        'inicializado': false,
        'error': e.toString(),
        'mensaje': 'Error al inicializar sistema de cortes',
      };
    }
  }

  /// Obtiene el corte activo actual (sin crear uno nuevo)
  Future<CorteCajaMdl?> obtenerCorteActivo({int? idSucursal}) async {
    try {
      final DateTime hoy = DateTime.now();
      final int sucursal = idSucursal ?? _defaultSucursal;

      return await _corteCajaRepository.getCorteDiaActivo(hoy, sucursal);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en obtenerCorteActivo: $e');
      }
      return null;
    }
  }

  // Métodos de utilidad privados

  /// Formatea una fecha para mostrar solo la parte de fecha
  String _formatearFecha(DateTime fecha) {
    return fecha.toIso8601String().split('T')[0];
  }

  /// Valida que los parámetros de sucursal y usuario sean válidos
  bool _validarParametros(int? idSucursal, int? idUsuario) {
    final int sucursal = idSucursal ?? _defaultSucursal;
    final int usuario = idUsuario ?? _defaultUsuario;

    return sucursal > 0 && usuario > 0;
  }

  /// Obtiene información resumida del corte actual
  Future<String> obtenerResumenCorte({int? idSucursal}) async {
    try {
      final estadoCorte = await verificarEstadoCorte(idSucursal: idSucursal);

      if (!estadoCorte['existe']) {
        return 'Sin corte activo';
      }

      final CorteCajaMdl corte = estadoCorte['corte'];
      final String fecha = _formatearFecha(corte.dtFecha);
      final String importe = corte.nImporte.toStringAsFixed(2);

      return 'Corte ${corte.idCorteCaja} - $fecha - \$importe - ${corte.cEstado}';
    } catch (e) {
      return 'Error al obtener resumen del corte';
    }
  }
}
