import 'package:flutter/foundation.dart';
import '../data/database_manager.dart';
import '../data/venta.dart';
import '../data/venta_detalle.dart';
import '../data/venta_tipo_pago.dart';
import '../data/corte_caja_venta.dart';
import '../data/acum_corte_detalle.dart';
import '../data/acum_corte_tipo_pago.dart';
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
  late final CorteCajaVenta _corteCajaVentaRepository;
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
    _corteCajaVentaRepository = CorteCajaVenta(database);
    _corteCajaService = await CorteCajaService.getInstance();
  }

  /// Procesa una venta completa con todos sus detalles y acumulados
  Future<Map<String, dynamic>> procesarVenta({
    required Cliente cliente,
    required List<CarritoItem> carrito,
    required Map<int, double> tiposPago,
    double descuento = 0.0,
    double iva = 0.0,
  }) async {
    try {
      if (kDebugMode) {
        print('🛒 Iniciando procesamiento de venta...');
      }

      // Validar que se puede realizar la venta
      final validacionCorte = await _corteCajaService.validarVentaPermitida();
      if (!validacionCorte['permitida']) {
        throw Exception(validacionCorte['mensaje']);
      }

      final corteActivo = validacionCorte['corte'];
      final int idCorteCaja = corteActivo.idCorteCaja;

      // Validar datos de entrada
      _validarDatosVenta(cliente, carrito, tiposPago);

      // Calcular totales
      final totales = _calcularTotalesVenta(carrito, descuento, iva);
      final double totalPagado = tiposPago.values.fold(
        0.0,
        (sum, monto) => sum + monto,
      );
      final double cambio = _calcularCambio(
        totales['total']!,
        totalPagado,
        tiposPago,
      );

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

    return await dbManager.transaction<Map<String, dynamic>>((txn) async {
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

      // 7. Actualizar el importe total del corte
      await _actualizarImporteCorte(idCorteCaja);

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

  /// Actualiza el importe total del corte de caja
  Future<void> _actualizarImporteCorte(int idCorteCaja) async {
    try {
      final double totalCorte = await _corteCajaVentaRepository
          .getTotalVentasCorte(idCorteCaja);
      await _corteCajaService.actualizarImporteCorte(idCorteCaja, totalCorte);

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

  /// Calcula el cambio a entregar
  double _calcularCambio(
    double totalVenta,
    double totalPagado,
    Map<int, double> tiposPago,
  ) {
    if (totalPagado <= totalVenta) {
      return 0.0;
    }

    // Buscar si hay pago en efectivo (asumiendo que efectivo tiene ID 1)
    final double efectivo = tiposPago[1] ?? 0.0;

    if (efectivo <= 0) {
      return 0.0; // No hay efectivo, no se puede dar cambio
    }

    final double exceso = totalPagado - totalVenta;
    return exceso <= efectivo ? exceso : efectivo;
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
  Future<Map<String, dynamic>> validarProcesamientoVenta({
    required Cliente cliente,
    required List<CarritoItem> carrito,
    required Map<int, double> tiposPago,
  }) async {
    try {
      // Validar corte activo
      final validacionCorte = await _corteCajaService.validarVentaPermitida();
      if (!validacionCorte['permitida']) {
        return {
          'valida': false,
          'razon': 'CORTE_INVALIDO',
          'mensaje': validacionCorte['mensaje'],
        };
      }

      // Validar datos básicos
      try {
        _validarDatosVenta(cliente, carrito, tiposPago);
      } catch (e) {
        return {
          'valida': false,
          'razon': 'DATOS_INVALIDOS',
          'mensaje': e.toString(),
        };
      }

      // Validar que el total de pagos cubra la venta
      final totales = _calcularTotalesVenta(carrito, 0.0, 0.0);
      final double totalPagado = tiposPago.values.fold(
        0.0,
        (sum, monto) => sum + monto,
      );

      if (totalPagado < totales['total']!) {
        return {
          'valida': false,
          'razon': 'PAGO_INSUFICIENTE',
          'mensaje': 'El monto pagado es insuficiente',
          'faltante': totales['total']! - totalPagado,
        };
      }

      // Validar cambio si hay exceso
      if (totalPagado > totales['total']!) {
        final double cambio = _calcularCambio(
          totales['total']!,
          totalPagado,
          tiposPago,
        );
        final double exceso = totalPagado - totales['total']!;

        if (cambio < exceso) {
          return {
            'valida': false,
            'razon': 'CAMBIO_INVALIDO',
            'mensaje':
                'No se puede dar el cambio completo sin efectivo suficiente',
            'cambioMaximo': cambio,
            'excesoTotal': exceso,
          };
        }
      }

      return {
        'valida': true,
        'mensaje': 'Venta válida para procesar',
        'totales': totales,
        'totalPagado': totalPagado,
        'cambio': _calcularCambio(totales['total']!, totalPagado, tiposPago),
      };
    } catch (e) {
      return {
        'valida': false,
        'razon': 'ERROR_VALIDACION',
        'mensaje': 'Error al validar la venta: $e',
      };
    }
  }

  /// Obtiene estadísticas básicas de ventas
  Future<Map<String, dynamic>> obtenerEstadisticasVentas([
    DateTime? fecha,
  ]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final ventas = await obtenerVentasDelDia(fechaConsulta);
      final total = await obtenerTotalVentasDelDia(fechaConsulta);

      if (ventas.isEmpty) {
        return {
          'totalVentas': 0,
          'montoTotal': 0.0,
          'promedioVenta': 0.0,
          'ventaMinima': 0.0,
          'ventaMaxima': 0.0,
        };
      }

      final List<double> montos = ventas.map((v) => v.total).toList();
      montos.sort();

      return {
        'totalVentas': ventas.length,
        'montoTotal': total,
        'promedioVenta': total / ventas.length,
        'ventaMinima': montos.first,
        'ventaMaxima': montos.last,
        'fecha': fechaConsulta.toIso8601String().split('T')[0],
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

  /// Método auxiliar para obtener el tipo de cambio de efectivo
  int _getEfectivoTipoPagoId() {
    // Por defecto asumimos que el efectivo tiene ID 1
    // Esto se puede hacer más robusto consultando la base de datos
    return 1;
  }

  /// Método para limpiar recursos (opcional)
  void dispose() {
    // Aquí se pueden limpiar recursos si es necesario en el futuro
    if (kDebugMode) {
      print('🧹 VentaService recursos liberados');
    }
  }
}
