import '../models/articulo_mdl.dart';
import 'base_crud_repository.dart';
import 'database_manager.dart';

class Articulo extends BaseCrudRepository<ArticuloMdl> {
  // Constructor privado
  Articulo._internal(super.database);

  // Singleton pattern para esta clase
  static Articulo? _instance;

  // Factory constructor que usa el DatabaseManager
  static Future<Articulo> getInstance() async {
    if (_instance == null) {
      final dbManager = DatabaseManager();
      final database = await dbManager.database;
      _instance = Articulo._internal(database);
    }
    return _instance!;
  }

  @override
  String get tableName => 'articulo';

  @override
  String get idColumnName => 'idArticulo';

  @override
  ArticuloMdl fromMap(Map<String, dynamic> map) {
    return ArticuloMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ArticuloMdl item) {
    return item.toMap();
  }

  // Métodos específicos para Artículos

  // Obtener todos los artículos con JOIN para compatibilidad con articulos_screen.dart
  Future<List<Map<String, dynamic>>> getArticulos() async {
    try {
      const String query = '''
      SELECT 
        a.idArticulo as id,
        a.cCodigo as codigo,
        a.cDescripcion as descripcion,
        a.nPrecio as precio,
        a.nCosto as costo,
        a.idClasificacion,
        999 as existencia
      FROM articulo a
      ORDER BY a.cDescripcion ASC
    ''';

      return await readWithJoin(query);
    } catch (e) {
      throw Exception('Error al obtener artículos: $e');
    }
  }

  // Buscar artículos por código o descripción con JOIN
  Future<List<Map<String, dynamic>>> buscarArticulos(String query) async {
    try {
      const String sqlQuery = '''
        SELECT 
          a.idArticulo as id,
          a.cCodigo as codigo,
          a.cDescripcion as descripcion,
          a.nPrecio as precio,
          a.nCosto as costo,
          a.idClasificacion,
          999 as existencia
        FROM articulo a
        WHERE LOWER(a.cCodigo) LIKE LOWER(?) 
           OR LOWER(a.cDescripcion) LIKE LOWER(?)
        ORDER BY a.cDescripcion ASC
      ''';

      final String searchPattern = '%$query%';
      return await readWithJoin(sqlQuery, [searchPattern, searchPattern]);
    } catch (e) {
      throw Exception('Error al buscar artículos: $e');
    }
  }

  // Obtener artículos por clasificación
  Future<List<ArticuloMdl>> getArticulosByClasificacion(
    int idClasificacion,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'idClasificacion = ?',
        whereArgs: [idClasificacion],
        orderBy: 'cDescripcion ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener artículos por clasificación: $e');
    }
  }

  // Buscar artículos por código
  Future<List<ArticuloMdl>> searchByCodigo(String codigo) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'LOWER(cCodigo) LIKE LOWER(?)',
        whereArgs: ['%$codigo%'],
        orderBy: 'cCodigo ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al buscar artículos por código: $e');
    }
  }

  // Buscar artículos por descripción
  Future<List<ArticuloMdl>> searchByDescripcion(String descripcion) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'LOWER(cDescripcion) LIKE LOWER(?)',
        whereArgs: ['%$descripcion%'],
        orderBy: 'cDescripcion ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al buscar artículos por descripción: $e');
    }
  }

  // Obtener artículos ordenados por precio
  Future<List<ArticuloMdl>> getAllOrderedByPrice({
    bool ascending = true,
  }) async {
    try {
      final String orderBy = ascending ? 'nPrecio ASC' : 'nPrecio DESC';
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        orderBy: orderBy,
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener artículos ordenados por precio: $e');
    }
  }

  // Obtener artículos en un rango de precio
  Future<List<ArticuloMdl>> getByPriceRange(
    double minPrice,
    double maxPrice,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'nPrecio >= ? AND nPrecio <= ?',
        whereArgs: [minPrice, maxPrice],
        orderBy: 'nPrecio ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener artículos por rango de precio: $e');
    }
  }

  // Verificar si ya existe un artículo con el mismo código
  Future<bool> existsByCodigo(String codigo, {int? excludeId}) async {
    try {
      String whereClause = 'LOWER(cCodigo) = LOWER(?)';
      List<dynamic> whereArgs = [codigo];

      if (excludeId != null) {
        whereClause += ' AND idArticulo != ?';
        whereArgs.add(excludeId);
      }

      final result = await database.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia por código: $e');
    }
  }

  // Actualizar solo el precio de un artículo
  Future<int> updatePrecio(int id, double nuevoPrecio) async {
    try {
      return await updateCustom('nPrecio = ?', 'idArticulo = ?', [
        nuevoPrecio,
        id,
      ]);
    } catch (e) {
      throw Exception('Error al actualizar precio: $e');
    }
  }

  // Actualizar solo el costo de un artículo
  Future<int> updateCosto(int id, double nuevoCosto) async {
    try {
      return await updateCustom('nCosto = ?', 'idArticulo = ?', [
        nuevoCosto,
        id,
      ]);
    } catch (e) {
      throw Exception('Error al actualizar costo: $e');
    }
  }

  // Obtener artículos con margen de ganancia mayor a un porcentaje
  Future<List<ArticuloMdl>> getByMinimumMargin(
    double minimumMarginPercent,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: '((nPrecio - nCosto) / nCosto * 100) >= ?',
        whereArgs: [minimumMarginPercent],
        orderBy: 'cDescripcion ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener artículos por margen mínimo: $e');
    }
  }
}
