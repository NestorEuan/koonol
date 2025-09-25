import '../models/tipo_pago_mdl.dart';
import 'base_crud_repository.dart';
import 'database_manager.dart';

class TipoPago extends BaseCrudRepository<TipoPagoMdl> {
  // Constructor privado
  TipoPago._internal(super.database);

  // Singleton pattern para esta clase
  static TipoPago? _instance;

  // Factory constructor que usa el DatabaseManager
  static Future<TipoPago> getInstance() async {
    if (_instance == null) {
      final dbManager = DatabaseManager();
      final database = await dbManager.database;
      _instance = TipoPago._internal(database);
    }
    return _instance!;
  }

  @override
  String get tableName => 'tipodepago';

  @override
  String get idColumnName => 'idTipoPago';

  @override
  TipoPagoMdl fromMap(Map<String, dynamic> map) {
    return TipoPagoMdl.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(TipoPagoMdl item) {
    return item.toMap();
  }

  // Métodos específicos para TipoDePago

  Future<List<TipoPagoMdl>> getTiposPago() async {
    try {
      return await readAll();
    } catch (e) {
      throw Exception('Error al buscar tipos de pago: $e');
    }
  }

  // Buscar tipos de pago por descripción
  Future<List<TipoPagoMdl>> searchByDescription(String description) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'cTipoPago LIKE ?',
        whereArgs: ['%$description%'],
        orderBy: 'cTipoPago ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al buscar tipos de pago: $e');
    }
  }

  // Obtener tipos de pago ordenados por descripción
  Future<List<TipoPagoMdl>> getAllOrderedByDescription() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        orderBy: 'cTipoPago ASC',
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de pago ordenados: $e');
    }
  }

  // Obtener tipos de pago con comisión específica
  Future<List<TipoPagoMdl>> getByComision(String comision) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'nComision = ?',
        whereArgs: [comision],
      );
      return maps.map((map) => fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de pago por comisión: $e');
    }
  }

  // Verificar si ya existe un tipo de pago con la misma descripción
  Future<bool> existsByDescription(String description, {int? excludeId}) async {
    try {
      String whereClause = 'LOWER(cTipoPago) = LOWER(?)';
      List<dynamic> whereArgs = [description];

      if (excludeId != null) {
        whereClause += ' AND idTipoPago != ?';
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
      throw Exception('Error al verificar existencia por descripción: $e');
    }
  }

  // Actualizar solo la comisión de un tipo de pago
  Future<int> updateComision(int id, String nuevaComision) async {
    try {
      return await updateCustom('nComision = ?', 'idTipoPago = ?', [
        nuevaComision,
        id,
      ]);
    } catch (e) {
      throw Exception('Error al actualizar comisión: $e');
    }
  }
}
