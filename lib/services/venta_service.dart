import 'package:flutter/foundation.dart';
import '../data/database_manager.dart';
import '../data/venta.dart';
import '../data/venta_detalle.dart';
import '../data/venta_tipo_pago.dart';
import '../models/venta_mdl.dart';
import '../models/venta_detalle_mdl.dart';
import '../models/venta_tipo_pago_mdl.dart';
import '../models/corte_caja_venta_mdl.dart';
import '../models/acum_corte_detalle_mdl.dart';
import '../models/acum_corte_tipo_pago_mdl.dart';
import '../models/carrito_item.dart';
import '../models/cliente.dart';
import 'corte_caja_service.dart';

/// Servicio principal para el manejo de ventas
/// Coordina todas las operaciones relacionadas con la venta y sus acumulados
class VentaService {
  late final Venta _ventaRepository;
  late final VentaDetalle _ventaDetalleRepository;
  late final VentaTipoPago _ventaTipoPagoRepository;
  late final CorteCajaService _corteCajaService;

  static VentaService? _instance;

  // Singleton pattern
  VentaService._internal();

  static Future<VentaService> getInstance() async {
    if (_instance == null) {
      _instance = VentaService._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Inicializa todos los repositorios necesarios
  Future<void> _initialize() async {
    final dbManager = DatabaseManager();
    final database = await dbManager.database;

    _ventaRepository = Venta(database);
    _ventaDetalleRepository = VentaDetalle(database);
    _ventaTipoPagoRepository = VentaTipoPago(database);
    _corteCajaService = await CorteCajaService.getInstance();
  }

  /// Procesa una venta completa con todos sus detalles y acumulados
  /// Procesa una venta completa con todos sus detalles y acumulados
  /// NOTA: Asume que las validaciones de UI ya se realizaron
  Future<Map<String, dynamic>> procesarVenta({
    required Cliente cliente,
    required List<CarritoItem> carrito,
    required Map<int, double> tiposPago,
    required double totalPagado,
    required double cambio,
    double descuento = 0.0,
    double iva = 0.0,
  }) async {
    try {
      if (kDebugMode) {
        print('🛒 Iniciando procesamiento de venta...');
      }

      // Validación crítica: Verificar que hay corte activo
      final validacionCorte = await _corteCajaService.validarVentaPermitida();
      if (!validacionCorte['permitida']) {
        throw Exception(validacionCorte['mensaje']);
      }

      final corteActivo = validacionCorte['corte'];
      final int idCorteCaja = corteActivo.idCorteCaja;

      // Validaciones mínimas de integridad de datos
      _validarIntegridadDatos(cliente, carrito, tiposPago);

      // Calcular totales
      final totales = _calcularTotalesVenta(carrito, descuento, iva);

      // Ejecutar venta en transacción
      final resultado = await _ejecutarVentaEnTransaccion(
        cliente: cliente,
        carrito: carrito,
        tiposPago: tiposPago,
        totales: totales,
        totalPagado: totalPagado,
        cambio: cambio,
        idCorteCaja: idCorteCaja,
      );

      if (kDebugMode) {
        print('✅ Venta procesada exitosamente - ID: ${resultado['idVenta']}');
      }

      return resultado;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al procesar venta: $e');
      }
      rethrow;
    }
  }

  /// Valida solo la integridad crítica de datos (no validaciones de negocio)
  void _validarIntegridadDatos(
    Cliente cliente,
    List<CarritoItem> carrito,
    Map<int, double> tiposPago,
  ) {
    // Validar cliente existe
    if (cliente.idCliente <= 0) {
      throw Exception('ID de cliente inválido');
    }

    // Validar carrito no está vacío
    if (carrito.isEmpty) {
      throw Exception('El carrito está vacío');
    }

    // Validar integridad de artículos
    for (final item in carrito) {
      if (item.articulo.idArticulo == null || item.articulo.idArticulo! <= 0) {
        throw Exception(
          'ID de artículo inválido: ${item.articulo.cDescripcion}',
        );
      }
      if (item.cantidad <= 0) {
        throw Exception(
          'Cantidad inválida para: ${item.articulo.cDescripcion}',
        );
      }
      if (item.precioVenta < 0) {
        throw Exception('Precio inválido para: ${item.articulo.cDescripcion}');
      }
    }

    // Validar que hay al menos un tipo de pago
    if (tiposPago.isEmpty) {
      throw Exception('No se especificaron formas de pago');
    }

    // Validar IDs de tipos de pago
    for (final idTipoPago in tiposPago.keys) {
      if (idTipoPago <= 0) {
        throw Exception('ID de tipo de pago inválido');
      }
    }
  }

  /// Ejecuta toda la venta en una transacción para garantizar consistencia
  Future<Map<String, dynamic>> _ejecutarVentaEnTransaccion({
    required Cliente cliente,
    required List<CarritoItem> carrito,
    required Map<int, double> tiposPago,
    required Map<String, double> totales,
    required double totalPagado,
    required double cambio,
    required int idCorteCaja,
  }) async {
    final dbManager = DatabaseManager();

    final resultado = await dbManager.transaction<Map<String, dynamic>>((
      txn,
    ) async {
      final DateTime ahora = DateTime.now();
      final DateTime fecha = DateTime(ahora.year, ahora.month, ahora.day);

      // 1. Crear la venta principal
      final venta = VentaMdl(
        idCliente: cliente.idCliente,
        nImporte: totales['subtotal']!,
        nIVA: totales['iva']!,
        nDescuento: totales['descuento']!,
        nTotalPagado: totalPagado,
        nCambio: cambio,
        dtAlta: ahora,
        dtFecha: fecha,
      );

      final int idVenta = await txn.insert('venta', venta.toMap());

      if (kDebugMode) {
        print('📝 Venta creada con ID: $idVenta');
      }

      // 2. Crear los detalles de venta
      await _crearDetallesVenta(txn, idVenta, carrito, ahora);

      // 3. Crear los registros de tipos de pago
      await _crearTiposPagoVenta(txn, idVenta, tiposPago, ahora);

      // 4. Registrar la venta en el corte
      await _registrarVentaEnCorte(txn, idCorteCaja, idVenta, totales, ahora);

      // 5. Actualizar acumulados de tipos de pago
      await _actualizarAcumuladosTipoPago(txn, idCorteCaja, tiposPago, ahora);

      // 6. Actualizar acumulados de detalle
      await _actualizarAcumuladosDetalle(txn, idCorteCaja, carrito, ahora);

      // 7. Actualizar el importe total del corte (dentro de la transacción)
      await _actualizarImporteCorte(txn, idCorteCaja);

      return {
        'success': true,
        'idVenta': idVenta,
        'total': totales['total'],
        'totalPagado': totalPagado,
        'cambio': cambio,
        'idCorteCaja': idCorteCaja,
        'mensaje': 'Venta procesada exitosamente',
      };
    });

    return resultado;
  }

  /// Crea los detalles de la venta
  Future<void> _crearDetallesVenta(
    dynamic txn,
    int idVenta,
    List<CarritoItem> carrito,
    DateTime ahora,
  ) async {
    for (final item in carrito) {
      final detalle = VentaDetalleMdl(
        idVenta: idVenta,
        idArticulo: item.articulo.idArticulo!,
        idPrecio:
            1, // Por ahora usamos 1, más adelante se puede implementar tabla de precios
        nCantidad: item.cantidad,
        nPrecio: item.precioVenta,
        nCosto: item.articulo.nCosto,
        dtAlta: ahora,
      );

      await txn.insert('ventadetalle', detalle.toMap());
    }

    if (kDebugMode) {
      print('📋 ${carrito.length} detalles de venta creados');
    }
  }

  /// Crea los registros de tipos de pago
  Future<void> _crearTiposPagoVenta(
    dynamic txn,
    int idVenta,
    Map<int, double> tiposPago,
    DateTime ahora,
  ) async {
    for (final entry in tiposPago.entries) {
      if (entry.value > 0) {
        final tipoPago = VentaTipoPagoMdl(
          idVenta: idVenta,
          idTipoPago: entry.key,
          nImporte: entry.value,
          dtAlta: ahora,
        );

        await txn.insert('ventatipopago', tipoPago.toMap());
      }
    }

    if (kDebugMode) {
      print('💳 Tipos de pago registrados: ${tiposPago.length}');
    }
  }

  /// Registra la venta en el corte de caja
  Future<void> _registrarVentaEnCorte(
    dynamic txn,
    int idCorteCaja,
    int idVenta,
    Map<String, double> totales,
    DateTime ahora,
  ) async {
    final corteCajaVenta = CorteCajaVentaMdl(
      idCorteCaja: idCorteCaja,
      idVenta: idVenta,
      nImporte: totales['subtotal']!,
      nIVA: totales['iva']!,
      nDescuento: totales['descuento']!,
      dtAlta: ahora,
    );

    await txn.insert('cortecajaventa', corteCajaVenta.toMap());

    if (kDebugMode) {
      print('📊 Venta registrada en corte: $idCorteCaja');
    }
  }

  /// Actualiza los acumulados por tipo de pago
  Future<void> _actualizarAcumuladosTipoPago(
    dynamic txn,
    int idCorteCaja,
    Map<int, double> tiposPago,
    DateTime ahora,
  ) async {
    for (final entry in tiposPago.entries) {
      if (entry.value > 0) {
        // Verificar si ya existe el acumulado
        final existing = await txn.query(
          'acumcortetipopago',
          where: 'idCorteCaja = ? AND idTipoPago = ?',
          whereArgs: [idCorteCaja, entry.key],
        );

        if (existing.isNotEmpty) {
          // Actualizar existente
          final importeActual = (existing.first['nImporte'] as double?) ?? 0.0;
          await txn.update(
            'acumcortetipopago',
            {'nImporte': importeActual + entry.value},
            where: 'idCorteCaja = ? AND idTipoPago = ?',
            whereArgs: [idCorteCaja, entry.key],
          );
        } else {
          // Crear nuevo
          final acumulado = AcumCorteTipoPagoMdl(
            idCorteCaja: idCorteCaja,
            idTipoPago: entry.key,
            nImporte: entry.value,
            dtAlta: ahora,
          );
          await txn.insert('acumcortetipopago', acumulado.toMap());
        }
      }
    }

    if (kDebugMode) {
      print('💰 Acumulados de tipo de pago actualizados');
    }
  }

  /// Actualiza los acumulados por artículo
  Future<void> _actualizarAcumuladosDetalle(
    dynamic txn,
    int idCorteCaja,
    List<CarritoItem> carrito,
    DateTime ahora,
  ) async {
    for (final item in carrito) {
      final double importeItem = item.subtotal;
      final double costoItem = item.articulo.nCosto * item.cantidad;

      // Verificar si ya existe el acumulado
      final existing = await txn.query(
        'acumcortedetalle',
        where: 'idCorte = ? AND idArticulo = ?',
        whereArgs: [idCorteCaja, item.articulo.idArticulo!],
      );

      if (existing.isNotEmpty) {
        // Actualizar existente
        final importeActual = (existing.first['nImporte'] as double?) ?? 0.0;
        final costoActual = (existing.first['nCosto'] as double?) ?? 0.0;
        await txn.update(
          'acumcortedetalle',
          {
            'nImporte': importeActual + importeItem,
            'nCosto': costoActual + costoItem,
          },
          where: 'idCorte = ? AND idArticulo = ?',
          whereArgs: [idCorteCaja, item.articulo.idArticulo!],
        );
      } else {
        // Crear nuevo
        final acumulado = AcumCorteDetalleMdl(
          idCorte: idCorteCaja,
          idArticulo: item.articulo.idArticulo!,
          dtAlta: ahora,
          nImporte: importeItem,
          nCosto: costoItem,
        );
        await txn.insert('acumcortedetalle', acumulado.toMap());
      }
    }

    if (kDebugMode) {
      print('💰 Acumulados de detalle actualizados');
    }
  }

  /// Actualiza el importe total del corte de caja DENTRO de la transacción
  Future<void> _actualizarImporteCorte(dynamic txn, int idCorteCaja) async {
    try {
      // Calcular el total directamente en la transacción
      final result = await txn.rawQuery(
        'SELECT COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as total FROM cortecajaventa WHERE idCorteCaja = ?',
        [idCorteCaja],
      );

      final double totalCorte = (result.first['total'] as double?) ?? 0.0;

      // Actualizar el importe del corte usando la transacción
      await txn.update(
        'cortecaja',
        {'nImporte': totalCorte},
        where: 'idCorteCaja = ?',
        whereArgs: [idCorteCaja],
      );

      if (kDebugMode) {
        print(
          '💼 Importe del corte actualizado: \$${totalCorte.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error al actualizar importe del corte: $e');
      }
      // No lanzamos el error para no afectar la venta
    }
  }

  /// Valida los datos de entrada para la venta
  void _validarDatosVenta(
    Cliente cliente,
    List<CarritoItem> carrito,
    Map<int, double> tiposPago,
  ) {
    // Validar cliente
    if (cliente.idCliente <= 0) {
      throw Exception('Cliente inválido');
    }

    // Validar carrito
    if (carrito.isEmpty) {
      throw Exception('El carrito está vacío');
    }

    for (final item in carrito) {
      if (item.cantidad <= 0) {
        throw Exception(
          'Cantidad inválida para artículo: ${item.articulo.cDescripcion}',
        );
      }
      if (item.precioVenta <= 0) {
        throw Exception(
          'Precio inválido para artículo: ${item.articulo.cDescripcion}',
        );
      }
      if (item.articulo.idArticulo == null || item.articulo.idArticulo! <= 0) {
        throw Exception(
          'ID de artículo inválido: ${item.articulo.cDescripcion}',
        );
      }
    }

    // Validar tipos de pago
    final double totalPagos = tiposPago.values.fold(
      0.0,
      (sum, monto) => sum + monto,
    );
    if (totalPagos <= 0) {
      throw Exception('No se han especificado métodos de pago');
    }

    for (final entry in tiposPago.entries) {
      if (entry.key <= 0) {
        throw Exception('ID de tipo de pago inválido: ${entry.key}');
      }
      if (entry.value < 0) {
        throw Exception('Monto de pago negativo para tipo: ${entry.key}');
      }
    }
  }

  /// Calcula los totales de la venta
  Map<String, double> _calcularTotalesVenta(
    List<CarritoItem> carrito,
    double descuento,
    double iva,
  ) {
    final double subtotal = carrito.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );
    final double total = subtotal + iva - descuento;

    return {
      'subtotal': subtotal,
      'iva': iva,
      'descuento': descuento,
      'total': total,
    };
  }

  /// Obtiene el resumen de una venta por ID
  Future<Map<String, dynamic>?> obtenerResumenVenta(int idVenta) async {
    try {
      final venta = await _ventaRepository.readById(idVenta);
      if (venta == null) return null;

      final detalles = await _ventaDetalleRepository.getDetallesPorVenta(
        idVenta,
      );
      final tiposPago = await _ventaTipoPagoRepository.getTiposPagoPorVenta(
        idVenta,
      );

      return {
        'venta': venta,
        'detalles': detalles,
        'tiposPago': tiposPago,
        'totalArticulos': detalles.fold(0.0, (sum, det) => sum + det.nCantidad),
        'gananciaTotal': detalles.fold(
          0.0,
          (sum, det) => sum + det.gananciaTotal,
        ),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener resumen de venta: $e');
      }
      return null;
    }
  }

  /// Obtiene las ventas del día actual
  Future<List<VentaMdl>> obtenerVentasDelDia([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      return await _ventaRepository.getVentasDelDia(fechaConsulta);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener ventas del día: $e');
      }
      return [];
    }
  }

  /// Obtiene el total de ventas del día
  Future<double> obtenerTotalVentasDelDia([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      return await _ventaRepository.getTotalVentasDelDia(fechaConsulta);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener total de ventas del día: $e');
      }
      return 0.0;
    }
  }

  /// Valida si se puede procesar una venta
  /// SIMPLIFICAR - Solo validaciones para consultas, no para ventas
  Future<Map<String, dynamic>> validarProcesamientoVenta({
    required Cliente cliente,
    required List<CarritoItem> carrito,
    required Map<int, double> tiposPago,
  }) async {
    try {
      // Solo validar corte activo
      final validacionCorte = await _corteCajaService.validarVentaPermitida();
      if (!validacionCorte['permitida']) {
        return {
          'valida': false,
          'razon': 'CORTE_INVALIDO',
          'mensaje': validacionCorte['mensaje'],
        };
      }

      // Validar integridad básica
      try {
        _validarIntegridadDatos(cliente, carrito, tiposPago);
      } catch (e) {
        return {
          'valida': false,
          'razon': 'DATOS_INVALIDOS',
          'mensaje': e.toString(),
        };
      }

      return {'valida': true, 'mensaje': 'Venta válida para procesar'};
    } catch (e) {
      return {
        'valida': false,
        'razon': 'ERROR_VALIDACION',
        'mensaje': 'Error al validar la venta: $e',
      };
    }
  }

  /// Obtiene estadísticas básicas de ventas
  /// Obtiene estadísticas básicas de ventas (OPTIMIZADO)
  Future<Map<String, dynamic>> obtenerEstadisticasVentas([
    DateTime? fecha,
  ]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final fechaStr = fechaConsulta.toIso8601String().split('T')[0];

      final dbManager = DatabaseManager();
      final db = await dbManager.database;

      // Una sola query para obtener todas las estadísticas
      final result = await db.rawQuery(
        '''
      SELECT 
        COUNT(*) as totalVentas,
        COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as montoTotal,
        COALESCE(AVG(nImporte + nIVA - nDescuento), 0) as promedioVenta,
        COALESCE(MIN(nImporte + nIVA - nDescuento), 0) as ventaMinima,
        COALESCE(MAX(nImporte + nIVA - nDescuento), 0) as ventaMaxima
      FROM venta
      WHERE dtFecha = ?
      ''',
        [fechaStr],
      );

      final data = result.first;
      return {
        'totalVentas': data['totalVentas'] as int,
        'montoTotal': (data['montoTotal'] as double?) ?? 0.0,
        'promedioVenta': (data['promedioVenta'] as double?) ?? 0.0,
        'ventaMinima': (data['ventaMinima'] as double?) ?? 0.0,
        'ventaMaxima': (data['ventaMaxima'] as double?) ?? 0.0,
        'fecha': fechaStr,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener estadísticas: $e');
      }
      return {
        'totalVentas': 0,
        'montoTotal': 0.0,
        'promedioVenta': 0.0,
        'ventaMinima': 0.0,
        'ventaMaxima': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Obtiene el detalle completo de una venta incluyendo información de artículos
  Future<Map<String, dynamic>?> obtenerVentaCompleta(int idVenta) async {
    try {
      final resumen = await obtenerResumenVenta(idVenta);
      if (resumen == null) return null;

      // Enriquecer con información de artículos
      final detalles = resumen['detalles'] as List<VentaDetalleMdl>;
      final List<Map<String, dynamic>> detallesEnriquecidos = [];

      for (final detalle in detalles) {
        // Aquí podrías agregar información del artículo si necesitas más datos
        detallesEnriquecidos.add({
          'detalle': detalle,
          'subtotal': detalle.subtotal,
          'ganancia': detalle.gananciaTotal,
          'margen': detalle.margenGanancia,
        });
      }

      return {
        ...resumen,
        'detallesEnriquecidos': detallesEnriquecidos,
        'totalGanancia': detallesEnriquecidos.fold(
          0.0,
          (sum, det) => sum + (det['ganancia'] as double),
        ),
        'margenPromedio': detallesEnriquecidos.isNotEmpty
            ? detallesEnriquecidos.fold(
                    0.0,
                    (sum, det) => sum + (det['margen'] as double),
                  ) /
                  detallesEnriquecidos.length
            : 0.0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener venta completa: $e');
      }
      return null;
    }
  }

  /// Obtiene las ventas de un período específico
  Future<List<VentaMdl>> obtenerVentasPeriodo(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      // Esta funcionalidad se puede implementar más adelante con un método específico
      // Por ahora devolvemos lista vacía
      if (kDebugMode) {
        print('📅 Consulta de período no implementada aún');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener ventas del período: $e');
      }
      return [];
    }
  }

  /// Cancela una venta (soft delete o marcar como cancelada)
  Future<bool> cancelarVenta(int idVenta, String motivo) async {
    try {
      // Esta funcionalidad se puede implementar más adelante
      // Requeriría agregar un campo de estado a la tabla venta
      if (kDebugMode) {
        print('❌ Cancelación de ventas no implementada aún');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cancelar venta: $e');
      }
      return false;
    }
  }

  /// Obtiene un resumen del día actual para el dashboard
  Future<Map<String, dynamic>> obtenerResumenDiario([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final estadisticas = await obtenerEstadisticasVentas(fechaConsulta);
      final estadoCorte = await _corteCajaService.verificarEstadoCorte();

      return {
        'fecha': fechaConsulta.toIso8601String().split('T')[0],
        'ventas': estadisticas,
        'corte': estadoCorte,
        'activo': estadoCorte['existe'] && estadoCorte['estado'] == 'ABIERTO',
        'resumen':
            '${estadisticas['totalVentas']} ventas por \$${estadisticas['montoTotal'].toStringAsFixed(2)}',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener resumen diario: $e');
      }
      return {
        'fecha': DateTime.now().toIso8601String().split('T')[0],
        'error': e.toString(),
        'activo': false,
      };
    }
  }

  /// Cancela una venta y actualiza los acumulados correspondientes
  Future<Map<String, dynamic>> cancelarVentaCompleta(int idVenta) async {
    try {
      if (kDebugMode) {
        print('🚫 Cancelando venta ID: $idVenta');
      }

      // Obtener detalle completo antes de cancelar
      final detalle = await _ventaRepository.getDetalleCompletoVenta(idVenta);
      if (detalle == null) {
        return {'success': false, 'mensaje': 'Venta no encontrada'};
      }

      final venta = detalle['venta'] as VentaMdl;

      // Validar que esté activa
      if (venta.cEstado == 'CANCELADA') {
        return {'success': false, 'mensaje': 'La venta ya está cancelada'};
      }

      // Obtener el corte asociado
      final dbManager = DatabaseManager();
      final db = await dbManager.database;

      final corteCajaVenta = await db.query(
        'cortecajaventa',
        where: 'idVenta = ?',
        whereArgs: [idVenta],
        limit: 1,
      );

      if (corteCajaVenta.isEmpty) {
        return {
          'success': false,
          'mensaje': 'No se encontró el corte asociado',
        };
      }

      final idCorteCaja = corteCajaVenta.first['idCorteCaja'] as int;

      // Ejecutar cancelación en transacción
      await dbManager.transaction((txn) async {
        // 1. Cancelar la venta
        await txn.update(
          'venta',
          {'cEstado': 'CANCELADA'},
          where: 'idVenta = ?',
          whereArgs: [idVenta],
        );

        // 2. Obtener detalles y restar de acumulados de artículos
        final detalles = await txn.query(
          'ventadetalle',
          where: 'idVenta = ?',
          whereArgs: [idVenta],
        );

        for (var detalle in detalles) {
          final idArticulo = detalle['idArticulo'] as int;
          final cantidad = (detalle['nCantidad'] as double?) ?? 0.0;
          final precio = (detalle['nPrecio'] as double?) ?? 0.0;
          final costo = (detalle['nCosto'] as double?) ?? 0.0;

          final importeItem = -(cantidad * precio); // Negativo para restar
          final costoItem = -(cantidad * costo);

          // Actualizar acumulado (usando valores negativos)
          final existing = await txn.query(
            'acumcortedetalle',
            where: 'idCorte = ? AND idArticulo = ?',
            whereArgs: [idCorteCaja, idArticulo],
          );

          if (existing.isNotEmpty) {
            final importeActual =
                (existing.first['nImporte'] as double?) ?? 0.0;
            final costoActual = (existing.first['nCosto'] as double?) ?? 0.0;

            await txn.update(
              'acumcortedetalle',
              {
                'nImporte': importeActual + importeItem,
                'nCosto': costoActual + costoItem,
              },
              where: 'idCorte = ? AND idArticulo = ?',
              whereArgs: [idCorteCaja, idArticulo],
            );
          }
        }

        // 3. Restar de acumulados de tipos de pago
        final tiposPago = await txn.query(
          'ventatipopago',
          where: 'idVenta = ?',
          whereArgs: [idVenta],
        );

        for (var tipoPago in tiposPago) {
          final idTipoPago = tipoPago['idTipoPago'] as int;
          final importe =
              -((tipoPago['nImporte'] as double?) ?? 0.0); // Negativo

          final existing = await txn.query(
            'acumcortetipopago',
            where: 'idCorteCaja = ? AND idTipoPago = ?',
            whereArgs: [idCorteCaja, idTipoPago],
          );

          if (existing.isNotEmpty) {
            final importeActual =
                (existing.first['nImporte'] as double?) ?? 0.0;

            await txn.update(
              'acumcortetipopago',
              {'nImporte': importeActual + importe},
              where: 'idCorteCaja = ? AND idTipoPago = ?',
              whereArgs: [idCorteCaja, idTipoPago],
            );
          }
        }

        // 4. Eliminar de cortecajaventa
        await txn.delete(
          'cortecajaventa',
          where: 'idVenta = ?',
          whereArgs: [idVenta],
        );

        // 5. Actualizar importe del corte
        final totalResult = await txn.rawQuery(
          'SELECT COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as total FROM cortecajaventa WHERE idCorteCaja = ?',
          [idCorteCaja],
        );

        final totalCorte = (totalResult.first['total'] as double?) ?? 0.0;

        await txn.update(
          'cortecaja',
          {'nImporte': totalCorte},
          where: 'idCorteCaja = ?',
          whereArgs: [idCorteCaja],
        );
      });

      return {
        'success': true,
        'mensaje': 'Venta cancelada exitosamente',
        'idVenta': idVenta,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cancelar venta: $e');
      }
      return {'success': false, 'mensaje': 'Error: $e'};
    }
  }

  /// Método para limpiar recursos (opcional)
  void dispose() {
    // Aquí se pueden limpiar recursos si es necesario en el futuro
    if (kDebugMode) {
      print('🧹 VentaService recursos liberados');
    }
  }
}
