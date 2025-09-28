import 'package:koonol/data/base_crud_repository.dart';
import 'package:koonol/models/acum_corte_detalle_mdl.dart';

class AcumCorteDetalle extends BaseCrudRepository<AcumCorteDetalleMdl> {
  AcumCorteDetalle(super.database);

  @override
  String get tableName => 'acumcortedetalle';

  @override
  String get idColumnName => 'idCorte'; // Clave compuesta, usamos primera columna

  @override
  AcumCorteDetalleMdl fromMap(Map<String, dynamic> map) {
    return AcumCorteDetalleMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(AcumCorteDetalleMdl item) {
    return item.toMap();
  }

  // Obtener acumulados detalle por corte
  Future<List<AcumCorteDetalleMdl>> getAcumuladosDetallePorCorte(
    int idCorte,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idCorte = ?',
        whereArgs: [idCorte],
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener acumulados detalle por corte: $e');
    }
  }

  // Actualizar o insertar acumulado detalle
  Future<void> upsertAcumuladoDetalle(AcumCorteDetalleMdl acumulado) async {
    try {
      final existing = await database.query(
        tableName,
        where: 'idCorte = ? AND idArticulo = ?',
        whereArgs: [acumulado.idCorte, acumulado.idArticulo],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final importeActual = (existing.first['nImporte'] as double?) ?? 0.0;
        final costoActual = (existing.first['nCosto'] as double?) ?? 0.0;
        // Actualizar existente
        await database.update(
          tableName,
          {
            'nImporte': importeActual + acumulado.nImporte,
            'nCosto': costoActual + acumulado.nCosto,
          },
          where: 'idCorte = ? AND idArticulo = ?',
          whereArgs: [acumulado.idCorte, acumulado.idArticulo],
        );
      } else {
        // Insertar nuevo
        await database.insert(tableName, toMap(acumulado));
      }
    } catch (e) {
      throw Exception('Error al actualizar acumulado detalle: $e');
    }
  }
}
