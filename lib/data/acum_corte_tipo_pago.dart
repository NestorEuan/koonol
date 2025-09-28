import 'package:koonol/data/base_crud_repository.dart';
import 'package:koonol/models/acum_corte_tipo_pago_mdl.dart';

class AcumCorteTipoPago extends BaseCrudRepository<AcumCorteTipoPagoMdl> {
  AcumCorteTipoPago(super.database);

  @override
  String get tableName => 'acumcortetipopago';

  @override
  String get idColumnName => 'idCorteCaja'; // Clave compuesta, usamos primera columna

  @override
  AcumCorteTipoPagoMdl fromMap(Map<String, dynamic> map) {
    return AcumCorteTipoPagoMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(AcumCorteTipoPagoMdl item) {
    return item.toMap();
  }

  // Obtener acumulados por corte
  Future<List<AcumCorteTipoPagoMdl>> getAcumuladosPorCorte(
    int idCorteCaja,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idCorteCaja = ?',
        whereArgs: [idCorteCaja],
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener acumulados por corte: $e');
    }
  }

  // Actualizar o insertar acumulado
  Future<void> upsertAcumulado(AcumCorteTipoPagoMdl acumulado) async {
    try {
      final existing = await database.query(
        tableName,
        where: 'idCorteCaja = ? AND idTipoPago = ?',
        whereArgs: [acumulado.idCorteCaja, acumulado.idTipoPago],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Actualizar existente
        final importeActual = (existing.first['nImporte'] as double?) ?? 0.0;
        await database.update(
          tableName,
          {'nImporte': importeActual + acumulado.nImporte},
          where: 'idCorteCaja = ? AND idTipoPago = ?',
          whereArgs: [acumulado.idCorteCaja, acumulado.idTipoPago],
        );
      } else {
        // Insertar nuevo
        await database.insert(tableName, toMap(acumulado));
      }
    } catch (e) {
      throw Exception('Error al actualizar acumulado de tipo de pago: $e');
    }
  }
}
