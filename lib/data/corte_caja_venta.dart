import '../models/corte_caja_venta_mdl.dart';
import '../data/base_crud_repository.dart';

class CorteCajaVenta extends BaseCrudRepository<CorteCajaVentaMdl> {
  CorteCajaVenta(super.database);

  @override
  String get tableName => 'cortecajaventa';

  @override
  String get idColumnName => 'idCorteCaja'; // Clave compuesta, usamos primera columna

  @override
  CorteCajaVentaMdl fromMap(Map<String, dynamic> map) {
    return CorteCajaVentaMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(CorteCajaVentaMdl item) {
    return item.toMap();
  }

  /// Obtiene todas las ventas de un corte específico
  Future<List<CorteCajaVentaMdl>> getVentasPorCorte(int idCorteCaja) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idCorteCaja = ?',
        whereArgs: [idCorteCaja],
        orderBy: 'dtAlta ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener ventas por corte: $e');
    }
  }

  /// Obtiene una venta específica de un corte
  Future<CorteCajaVentaMdl?> getVentaEnCorte(
    int idCorteCaja,
    int idVenta,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idCorteCaja = ? AND idVenta = ?',
        whereArgs: [idCorteCaja, idVenta],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener venta en corte: $e');
    }
  }

  /// Obtiene el total de ventas de un corte
  Future<double> getTotalVentasCorte(int idCorteCaja) async {
    try {
      final result = await database.rawQuery(
        'SELECT COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as total FROM $tableName WHERE idCorteCaja = ?',
        [idCorteCaja],
      );
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      throw Exception('Error al obtener total de ventas del corte: $e');
    }
  }

  /// Cuenta el número de ventas en un corte
  Future<int> contarVentasEnCorte(int idCorteCaja) async {
    try {
      final result = await database.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE idCorteCaja = ?',
        [idCorteCaja],
      );
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Error al contar ventas en corte: $e');
    }
  }

  /// Verifica si una venta ya está registrada en un corte
  Future<bool> existeVentaEnCorte(int idCorteCaja, int idVenta) async {
    try {
      final result = await database.query(
        tableName,
        where: 'idCorteCaja = ? AND idVenta = ?',
        whereArgs: [idCorteCaja, idVenta],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia de venta en corte: $e');
    }
  }

  /// Elimina todas las ventas de un corte
  Future<int> eliminarVentasDelCorte(int idCorteCaja) async {
    try {
      return await deleteWhere('idCorteCaja = ?', [idCorteCaja]);
    } catch (e) {
      throw Exception('Error al eliminar ventas del corte: $e');
    }
  }

  /// Obtiene estadísticas de ventas de un corte
  Future<Map<String, dynamic>> getEstadisticasCorte(int idCorteCaja) async {
    try {
      final result = await database.rawQuery(
        '''
        SELECT 
          COUNT(*) as totalVentas,
          COALESCE(SUM(nImporte), 0) as totalImporte,
          COALESCE(SUM(nIVA), 0) as totalIVA,
          COALESCE(SUM(nDescuento), 0) as totalDescuento,
          COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as totalNeto,
          COALESCE(AVG(nImporte + nIVA - nDescuento), 0) as promedioVenta,
          COALESCE(MIN(nImporte + nIVA - nDescuento), 0) as ventaMinima,
          COALESCE(MAX(nImporte + nIVA - nDescuento), 0) as ventaMaxima
        FROM $tableName 
        WHERE idCorteCaja = ?
      ''',
        [idCorteCaja],
      );

      final data = result.first;
      return {
        'totalVentas': data['totalVentas'] as int,
        'totalImporte': (data['totalImporte'] as double?) ?? 0.0,
        'totalIVA': (data['totalIVA'] as double?) ?? 0.0,
        'totalDescuento': (data['totalDescuento'] as double?) ?? 0.0,
        'totalNeto': (data['totalNeto'] as double?) ?? 0.0,
        'promedioVenta': (data['promedioVenta'] as double?) ?? 0.0,
        'ventaMinima': (data['ventaMinima'] as double?) ?? 0.0,
        'ventaMaxima': (data['ventaMaxima'] as double?) ?? 0.0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas del corte: $e');
    }
  }
}
