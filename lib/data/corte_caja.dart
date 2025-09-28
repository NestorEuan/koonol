import '../data/base_crud_repository.dart';
import '../models/corte_caja_mdl.dart';

class CorteCaja extends BaseCrudRepository<CorteCajaMdl> {
  CorteCaja(super.database);

  @override
  String get tableName => 'cortecaja';

  @override
  String get idColumnName => 'idCorteCaja';

  @override
  CorteCajaMdl fromMap(Map<String, dynamic> map) {
    return CorteCajaMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(CorteCajaMdl item) {
    return item.toMap();
  }

  // Método específico: obtener corte activo del día
  Future<CorteCajaMdl?> getCorteDiaActivo(
    DateTime fecha,
    int idSucursal,
  ) async {
    try {
      final fechaStr = fecha.toIso8601String().split('T')[0];
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'dtFecha = ? AND idSucursal = ? AND cEstado = ?',
        whereArgs: [fechaStr, idSucursal, 'ABIERTO'],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener corte del día: $e');
    }
  }

  // Método específico: crear corte del día
  Future<int> crearCorteDelDia(int idSucursal, int idUsuario) async {
    try {
      final ahora = DateTime.now();
      final fecha = DateTime(ahora.year, ahora.month, ahora.day);

      final nuevoCorte = CorteCajaMdl(
        idSucursal: idSucursal,
        idUsuario: idUsuario,
        dtAlta: ahora,
        dtFecha: fecha,
        cEstado: 'ABIERTO',
        nImporte: 0.0,
      );

      return await create(nuevoCorte);
    } catch (e) {
      throw Exception('Error al crear corte del día: $e');
    }
  }

  // Método específico: cerrar corte
  Future<int> cerrarCorte(int idCorteCaja, double importeTotal) async {
    try {
      return await updateCustom(
        'cEstado = ?, nImporte = ?',
        'idCorteCaja = ?',
        ['CERRADO', importeTotal, idCorteCaja],
      );
    } catch (e) {
      throw Exception('Error al cerrar corte: $e');
    }
  }

  // Método específico: actualizar importe del corte
  Future<int> actualizarImporte(int idCorteCaja, double nuevoImporte) async {
    try {
      return await updateCustom('nImporte = ?', 'idCorteCaja = ?', [
        nuevoImporte,
        idCorteCaja,
      ]);
    } catch (e) {
      throw Exception('Error al actualizar importe del corte: $e');
    }
  }
}
