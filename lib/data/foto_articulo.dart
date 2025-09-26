import '../models/foto_articulo_mdl.dart';
import 'base_crud_repository.dart';
import 'database_manager.dart';

class FotoArticulo extends BaseCrudRepository<FotoArticuloMdl> {
  // Constructor privado
  FotoArticulo._internal(super.database);

  // Singleton pattern para esta clase
  static FotoArticulo? _instance;

  // Factory constructor que usa el DatabaseManager
  static Future<FotoArticulo> getInstance() async {
    if (_instance == null) {
      final dbManager = DatabaseManager();
      final database = await dbManager.database;
      _instance = FotoArticulo._internal(database);
    }
    return _instance!;
  }

  @override
  String get tableName => 'fotoarticulo';

  @override
  String get idColumnName => 'idArticulo'; // Clave primaria compuesta, usando idArticulo como principal

  @override
  FotoArticuloMdl fromMap(Map<String, dynamic> map) {
    return FotoArticuloMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(FotoArticuloMdl item) {
    return item.toMap();
  }

  // Métodos específicos para FotoArticulo

  // Obtener todas las fotos de un artículo
  Future<List<FotoArticuloMdl>> getFotosByArticulo(int idArticulo) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idArticulo = ?',
        whereArgs: [idArticulo],
        orderBy: 'idFoto ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener fotos del artículo: $e');
    }
  }

  // Obtener una foto específica de un artículo
  Future<FotoArticuloMdl?> getFotoByArticuloAndId(
    int idArticulo,
    int idFoto,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idArticulo = ? AND idFoto = ?',
        whereArgs: [idArticulo, idFoto],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener foto específica: $e');
    }
  }

  // Eliminar todas las fotos de un artículo
  Future<int> deleteByArticulo(int idArticulo) async {
    try {
      return await deleteWhere('idArticulo = ?', [idArticulo]);
    } catch (e) {
      throw Exception('Error al eliminar fotos del artículo: $e');
    }
  }

  // Eliminar una foto específica
  Future<int> deleteByArticuloAndId(int idArticulo, int idFoto) async {
    try {
      return await deleteWhere('idArticulo = ? AND idFoto = ?', [
        idArticulo,
        idFoto,
      ]);
    } catch (e) {
      throw Exception('Error al eliminar foto específica: $e');
    }
  }

  // Verificar si existe una foto específica
  Future<bool> existsFoto(int idArticulo, int idFoto) async {
    try {
      final result = await database.query(
        tableName,
        where: 'idArticulo = ? AND idFoto = ?',
        whereArgs: [idArticulo, idFoto],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia de foto: $e');
    }
  }

  // Obtener el próximo ID de foto para un artículo
  Future<int> getNextIdFoto(int idArticulo) async {
    try {
      final result = await database.rawQuery(
        'SELECT COALESCE(MAX(idFoto), 0) + 1 as nextId FROM $tableName WHERE idArticulo = ?',
        [idArticulo],
      );
      return result.first['nextId'] as int;
    } catch (e) {
      throw Exception('Error al obtener próximo ID de foto: $e');
    }
  }

  // Contar fotos de un artículo
  Future<int> countFotosByArticulo(int idArticulo) async {
    try {
      final result = await database.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE idArticulo = ?',
        [idArticulo],
      );
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Error al contar fotos del artículo: $e');
    }
  }

  // Actualizar la ruta de una foto
  Future<int> updateRuta(int idArticulo, int idFoto, String nuevaRuta) async {
    try {
      return await updateCustom('cRuta = ?', 'idArticulo = ? AND idFoto = ?', [
        nuevaRuta,
        idArticulo,
        idFoto,
      ]);
    } catch (e) {
      throw Exception('Error al actualizar ruta de foto: $e');
    }
  }
}
