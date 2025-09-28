import 'package:koonol/data/base_crud_repository.dart';
import 'package:koonol/models/venta_tipo_pago_mdl.dart';

class VentaTipoPago extends BaseCrudRepository<VentaTipoPagoMdl> {
  VentaTipoPago(super.database);

  @override
  String get tableName => 'ventatipopago';

  @override
  String get idColumnName => 'idVenta'; // Clave compuesta, usamos primera columna

  @override
  VentaTipoPagoMdl fromMap(Map<String, dynamic> map) {
    return VentaTipoPagoMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(VentaTipoPagoMdl item) {
    return item.toMap();
  }

  // Obtener tipos de pago de una venta
  Future<List<VentaTipoPagoMdl>> getTiposPagoPorVenta(int idVenta) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idVenta = ?',
        whereArgs: [idVenta],
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de pago de venta: $e');
    }
  }

  // Insertar múltiples tipos de pago en una transacción
  Future<void> insertarTiposPagoVenta(List<VentaTipoPagoMdl> tiposPago) async {
    final batch = database.batch();
    try {
      for (final tipoPago in tiposPago) {
        batch.insert(tableName, toMap(tipoPago));
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Error al insertar tipos de pago de venta: $e');
    }
  }
}
