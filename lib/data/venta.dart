import '../data/base_crud_repository.dart';
import '../models/venta_mdl.dart';

class Venta extends BaseCrudRepository<VentaMdl> {
  Venta(super.database);

  @override
  String get tableName => 'venta';

  @override
  String get idColumnName => 'idVenta';

  @override
  VentaMdl fromMap(Map<String, dynamic> map) {
    return VentaMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(VentaMdl item) {
    return item.toMap();
  }

  // Obtener ventas del día
  Future<List<VentaMdl>> getVentasDelDia(DateTime fecha) async {
    try {
      final fechaStr = fecha.toIso8601String().split('T')[0];
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'dtFecha = ?',
        whereArgs: [fechaStr],
        orderBy: 'dtAlta DESC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener ventas del día: $e');
    }
  }

  // Obtener total de ventas del día
  Future<double> getTotalVentasDelDia(DateTime fecha) async {
    try {
      final fechaStr = fecha.toIso8601String().split('T')[0];
      final result = await database.rawQuery(
        'SELECT COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as total FROM $tableName WHERE dtFecha = ?',
        [fechaStr],
      );
      final total = (result.first['total'] as double?) ?? 0.0;
      return total.toDouble();
    } catch (e) {
      throw Exception('Error al obtener total de ventas del día: $e');
    }
  }

  // Obtener ventas por rango de fechas
  Future<List<VentaMdl>> getVentasPorRango(
    DateTime fechaInicio,
    DateTime fechaFin, {
    String? estado, // 'ACTIVA', 'CANCELADA', o null para todas
  }) async {
    try {
      final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin.toIso8601String().split('T')[0];

      String whereClause = 'dtFecha >= ? AND dtFecha <= ?';
      List<dynamic> whereArgs = [fechaInicioStr, fechaFinStr];

      if (estado != null) {
        whereClause += ' AND cEstado = ?';
        whereArgs.add(estado);
      }

      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'dtFecha DESC, dtAlta DESC',
      );

      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener ventas por rango: $e');
    }
  }

  // Obtener ventas de la semana actual
  Future<List<VentaMdl>> getVentasSemanaActual({String? estado}) async {
    try {
      final ahora = DateTime.now();
      final inicioDeSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
      final inicioSemana = DateTime(
        inicioDeSemana.year,
        inicioDeSemana.month,
        inicioDeSemana.day,
      );
      final finSemana = inicioSemana.add(const Duration(days: 6));

      return await getVentasPorRango(inicioSemana, finSemana, estado: estado);
    } catch (e) {
      throw Exception('Error al obtener ventas de la semana: $e');
    }
  }

  // Cancelar una venta
  Future<bool> cancelarVenta(int idVenta) async {
    try {
      final count = await updateCustom("cEstado = 'CANCELADA'", 'idVenta = ?', [
        idVenta,
      ]);
      return count > 0;
    } catch (e) {
      throw Exception('Error al cancelar venta: $e');
    }
  }

  // Obtener estadísticas de ventas por rango de fechas
  Future<Map<String, dynamic>> getEstadisticasPorRango(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin.toIso8601String().split('T')[0];

      final result = await database.rawQuery(
        '''
      SELECT 
        COUNT(*) as totalVentas,
        COALESCE(SUM(CASE WHEN cEstado = 'ACTIVA' THEN nImporte + nIVA - nDescuento ELSE 0 END), 0) as montoTotal,
        COALESCE(AVG(CASE WHEN cEstado = 'ACTIVA' THEN nImporte + nIVA - nDescuento ELSE NULL END), 0) as promedioVenta,
        COALESCE(SUM(CASE WHEN cEstado = 'ACTIVA' THEN 1 ELSE 0 END), 0) as ventasActivas,
        COALESCE(SUM(CASE WHEN cEstado = 'CANCELADA' THEN 1 ELSE 0 END), 0) as ventasCanceladas
      FROM venta
      WHERE dtFecha >= ? AND dtFecha <= ?
      ''',
        [fechaInicioStr, fechaFinStr],
      );

      final data = result.first;
      return {
        'totalVentas': data['totalVentas'] as int,
        'montoTotal': (data['montoTotal'] as double?) ?? 0.0,
        'promedioVenta': (data['promedioVenta'] as double?) ?? 0.0,
        'ventasActivas': data['ventasActivas'] as int,
        'ventasCanceladas': data['ventasCanceladas'] as int,
        'fechaInicio': fechaInicioStr,
        'fechaFin': fechaFinStr,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas por rango: $e');
    }
  }

  // Obtener ventas agrupadas por fecha para gráficos
  Future<Map<String, double>> getVentasAgrupadasPorFecha(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin.toIso8601String().split('T')[0];

      final result = await database.rawQuery(
        '''
      SELECT 
        dtFecha,
        COALESCE(SUM(CASE WHEN cEstado = 'ACTIVA' THEN nImporte + nIVA - nDescuento ELSE 0 END), 0) as total
      FROM venta
      WHERE dtFecha >= ? AND dtFecha <= ?
      GROUP BY dtFecha
      ORDER BY dtFecha ASC
      ''',
        [fechaInicioStr, fechaFinStr],
      );

      final Map<String, double> ventasPorFecha = {};

      // Llenar con ceros todos los días del rango
      DateTime fecha = fechaInicio;
      while (fecha.isBefore(fechaFin) || fecha.isAtSameMomentAs(fechaFin)) {
        final fechaStr = fecha.toIso8601String().split('T')[0];
        ventasPorFecha[fechaStr] = 0.0;
        fecha = fecha.add(const Duration(days: 1));
      }

      // Llenar con los datos reales
      for (var row in result) {
        final fechaStr = row['dtFecha'] as String;
        final total = (row['total'] as double?) ?? 0.0;
        ventasPorFecha[fechaStr] = total;
      }

      return ventasPorFecha;
    } catch (e) {
      throw Exception('Error al obtener ventas agrupadas por fecha: $e');
    }
  }

  // Obtener total de ventas por rango (solo activas)
  Future<double> getTotalVentasPorRango(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final fechaInicioStr = fechaInicio.toIso8601String().split('T')[0];
      final fechaFinStr = fechaFin.toIso8601String().split('T')[0];

      final result = await database.rawQuery(
        '''
      SELECT COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as total 
      FROM $tableName 
      WHERE dtFecha >= ? AND dtFecha <= ? AND cEstado = 'ACTIVA'
      ''',
        [fechaInicioStr, fechaFinStr],
      );

      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      throw Exception('Error al obtener total de ventas por rango: $e');
    }
  }

  // Verificar si una venta se puede cancelar
  Future<bool> puedeCancelarVenta(int idVenta) async {
    try {
      final venta = await readById(idVenta);
      if (venta == null) return false;

      // Solo se pueden cancelar ventas activas
      if (venta.cEstado != 'ACTIVA') return false;

      // Verificar que la venta sea del día actual o días anteriores
      // (Puedes agregar más validaciones según tus reglas de negocio)
      return true;
    } catch (e) {
      throw Exception('Error al verificar si puede cancelar venta: $e');
    }
  }

  // Obtener detalle completo de una venta (para mostrar antes de cancelar)
  Future<Map<String, dynamic>?> getDetalleCompletoVenta(int idVenta) async {
    try {
      // Obtener venta
      final venta = await readById(idVenta);
      if (venta == null) return null;

      // Obtener detalles de artículos
      final detallesResult = await database.rawQuery(
        '''
      SELECT 
        vd.*,
        a.cDescripcion as descripcionArticulo,
        a.cCodigo as codigoArticulo
      FROM ventadetalle vd
      LEFT JOIN articulo a ON vd.idArticulo = a.idArticulo
      WHERE vd.idVenta = ?
      ORDER BY vd.dtAlta
      ''',
        [idVenta],
      );

      // Obtener tipos de pago
      final tiposPagoResult = await database.rawQuery(
        '''
      SELECT 
        vtp.*,
        tp.cTipoPago as descripcionTipoPago
      FROM ventatipopago vtp
      LEFT JOIN tipodepago tp ON vtp.idTipoPago = tp.idTipoPago
      WHERE vtp.idVenta = ?
      ''',
        [idVenta],
      );

      return {
        'venta': venta,
        'detalles': detallesResult,
        'tiposPago': tiposPagoResult,
        'totalArticulos': detallesResult.fold<double>(
          0,
          (sum, item) => sum + ((item['nCantidad'] as double?) ?? 0.0),
        ),
        'totalItems': detallesResult.length,
      };
    } catch (e) {
      throw Exception('Error al obtener detalle completo de venta: $e');
    }
  }
}
