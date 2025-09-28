import 'package:koonol/data/base_crud_repository.dart';
import 'package:koonol/models/venta_detalle_mdl.dart';

class VentaDetalle extends BaseCrudRepository<VentaDetalleMdl> {
  VentaDetalle(super.database);

  @override
  String get tableName => 'ventadetalle';

  @override
  String get idColumnName => 'idVenta'; // Clave compuesta, usamos primera columna

  @override
  VentaDetalleMdl fromMap(Map<String, dynamic> map) {
    return VentaDetalleMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(VentaDetalleMdl item) {
    return item.toMap();
  }

  // Obtener detalles de una venta
  Future<List<VentaDetalleMdl>> getDetallesPorVenta(int idVenta) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idVenta = ?',
        whereArgs: [idVenta],
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener detalles de venta: $e');
    }
  }

  // Insertar múltiples detalles en una transacción
  Future<void> insertarDetallesVenta(List<VentaDetalleMdl> detalles) async {
    final batch = database.batch();
    try {
      for (final detalle in detalles) {
        batch.insert(tableName, toMap(detalle));
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Error al insertar detalles de venta: $e');
    }
  }
}
