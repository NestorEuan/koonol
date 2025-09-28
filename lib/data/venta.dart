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
}
