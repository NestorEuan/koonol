import 'package:sqflite/sqflite.dart';

// Clase base abstracta para operaciones CRUD genéricas
abstract class BaseCrudRepository<T> {
  final Database database;

  BaseCrudRepository(this.database);

  // Nombre de la tabla - debe ser implementado por las clases hijas
  String get tableName;

  // Método para convertir un Map a objeto - debe ser implementado
  T fromMap(Map<String, dynamic> map);

  // Método para convertir objeto a Map - debe ser implementado
  Map<String, dynamic> toMap(T item);

  // Método para obtener el nombre de la columna ID - debe ser implementado
  String get idColumnName;

  // Operación CREATE - Insertar un nuevo registro
  Future<int> create(T item) async {
    try {
      final map = toMap(item);
      final id = await database.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw Exception('Error al crear registro en $tableName: $e');
    }
  }

  // Operación CREATE con JOIN - Para catálogos compuestos
  Future<int> createWithJoin(
    T item, {
    String? customQuery,
    List<dynamic>? params,
  }) async {
    try {
      if (customQuery != null && params != null) {
        await database.rawInsert(customQuery, params);
        // Obtener el último ID insertado
        final result = await database.rawQuery(
          'SELECT last_insert_rowid() as id',
        );
        return result.first['id'] as int;
      } else {
        return await create(item);
      }
    } catch (e) {
      throw Exception('Error al crear registro con JOIN en $tableName: $e');
    }
  }

  // Operación READ - Obtener todos los registros
  Future<List<T>> readAll() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(tableName);
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al leer registros de $tableName: $e');
    }
  }

  // Operación READ - Obtener un registro por ID
  Future<T?> readById(dynamic id) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: '$idColumnName = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error al leer registro por ID de $tableName: $e');
    }
  }

  // Operación READ con JOIN - Para catálogos compuestos
  Future<List<Map<String, dynamic>>> readWithJoin(
    String joinQuery, [
    List<dynamic>? params,
  ]) async {
    try {
      final result = await database.rawQuery(joinQuery, params ?? []);
      return result;
    } catch (e) {
      throw Exception('Error al leer con JOIN de $tableName: $e');
    }
  }

  // Operación UPDATE - Actualizar un registro
  Future<int> update(T item, dynamic id) async {
    try {
      final map = toMap(item);
      final count = await database.update(
        tableName,
        map,
        where: '$idColumnName = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      throw Exception('Error al actualizar registro en $tableName: $e');
    }
  }

  // Operación UPDATE personalizada - Para casos especiales como incrementar valores
  Future<int> updateCustom(
    String setClause,
    String whereClause,
    List<dynamic> params,
  ) async {
    try {
      final query = 'UPDATE $tableName SET $setClause WHERE $whereClause';
      final count = await database.rawUpdate(query, params);
      return count;
    } catch (e) {
      throw Exception('Error en actualización personalizada de $tableName: $e');
    }
  }

  // Operación DELETE - Eliminar un registro por ID
  Future<int> delete(dynamic id) async {
    try {
      final count = await database.delete(
        tableName,
        where: '$idColumnName = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      throw Exception('Error al eliminar registro de $tableName: $e');
    }
  }

  // Operación DELETE con condiciones personalizadas
  Future<int> deleteWhere(String whereClause, List<dynamic> whereArgs) async {
    try {
      final count = await database.delete(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );
      return count;
    } catch (e) {
      throw Exception('Error al eliminar registros de $tableName: $e');
    }
  }

  // Método para obtener el conteo total de registros
  Future<int> count() async {
    try {
      final result = await database.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName',
      );
      return result.first['count'] as int;
    } catch (e) {
      throw Exception('Error al contar registros de $tableName: $e');
    }
  }

  // Método para verificar si existe un registro
  Future<bool> exists(dynamic id) async {
    try {
      final result = await database.query(
        tableName,
        where: '$idColumnName = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia en $tableName: $e');
    }
  }
}
