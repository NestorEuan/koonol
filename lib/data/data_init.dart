import 'package:flutter/foundation.dart';
import 'database_manager.dart';

class DataInit {
  // Inicializar la base de datos de la aplicación
  static Future<void> initDb({bool forceRecreate = false}) async {
    try {
      final dbManager = DatabaseManager();

      if (forceRecreate) {
        if (kDebugMode) {
          print('🔄 Recreando base de datos (DROP y CREATE)...');
        }
        await dbManager.recreateDatabase();
      } else {
        if (kDebugMode) {
          print('🚀 Inicializando base de datos...');
        }
        // Al llamar database se ejecuta automáticamente _initDatabase si es necesario
        await dbManager.database;
      }

      // Mostrar información de las tablas creadas
      await _showDatabaseInfo(dbManager);

      if (kDebugMode) {
        print('✅ Base de datos inicializada correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar la base de datos: $e');
      }
      rethrow;
    }
  }

  // Mostrar información de la base de datos
  static Future<void> _showDatabaseInfo(DatabaseManager dbManager) async {
    if (kDebugMode) {
      try {
        // Obtener lista de tablas
        final tables = await dbManager.getTablesInfo();
        print('📊 Tablas en la base de datos:');

        for (var table in tables) {
          final tableName = table['name'] as String;
          print('  - $tableName');

          // Mostrar estructura de la tabla
          final structure = await dbManager.getTableStructure(tableName);
          for (var column in structure) {
            print('    • ${column['name']} (${column['type']})');
          }
        }

        // Verificar datos de ejemplo en articulos
        final db = await dbManager.database;
        final articulosCount = await db.rawQuery(
          'SELECT COUNT(*) as count FROM articulo',
        );
        final count = articulosCount.first['count'] as int;
        print('📦 Artículos en la base de datos: $count registros');

        if (count > 0) {
          final articulos = await db.query('articulo', limit: 3);
          print('📝 Ejemplos de artículos:');
          for (var articulo in articulos) {
            print(
              '    • ${articulo['cCodigo']}: ${articulo['cDescripcion']} - \$${articulo['nPrecio']}',
            );
          }
        }
      } catch (e) {
        print('⚠️  Error al mostrar información de la base de datos: $e');
      }
    }
  }

  // Método para recrear la base de datos
  static Future<void> recreateDb() async {
    await initDb(forceRecreate: true);
  }

  // Método para verificar el estado de la base de datos
  static Future<Map<String, dynamic>> checkDatabaseStatus() async {
    try {
      final dbManager = DatabaseManager();
      final db = await dbManager.database;

      // Verificar tablas
      final tables = await dbManager.getTablesInfo();
      final tableNames = tables.map((t) => t['name'] as String).toList();

      // Contar registros en cada tabla
      Map<String, int> tableCounts = {};
      for (String tableName in tableNames) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName',
          );
          tableCounts[tableName] = result.first['count'] as int;
        } catch (e) {
          tableCounts[tableName] = -1; // Error al contar
        }
      }

      return {
        'status': 'success',
        'tables': tableNames,
        'counts': tableCounts,
        'isInitialized': dbManager.isInitialized,
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString(), 'isInitialized': false};
    }
  }

  // Método para insertar datos de prueba adicionales
  static Future<void> insertTestData() async {
    try {
      final dbManager = DatabaseManager();
      final db = await dbManager.database;

      if (kDebugMode) {
        print('📊 Insertando datos de prueba adicionales...');
      }

      // Verificar si ya hay datos
      final existingArticulos = await db.rawQuery(
        'SELECT COUNT(*) as count FROM articulo',
      );
      final count = existingArticulos.first['count'] as int;

      if (count <= 3) {
        // Insertar más artículos de prueba
        await db.execute('''
          INSERT INTO articulo (idClasificacion, cCodigo, cDescripcion, nPrecio, nCosto) VALUES 
          (1, 'doc', 'Docena de huevos', 45.0, 38.0),
          (1, 'med', 'Media docena de huevos', 25.0, 20.0),
          (1, 'jum', 'Huevo jumbo', 95.0, 80.0),
          (2, 'pol', 'Pollo entero', 120.0, 95.0),
          (2, 'mus', 'Muslo de pollo', 85.0, 70.0)
        ''');

        if (kDebugMode) {
          print('✅ Datos de prueba adicionales insertados');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️  Ya existen datos en la tabla articulo');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al insertar datos de prueba: $e');
      }
      rethrow;
    }
  }

  // Método para cerrar la base de datos (opcional, para casos específicos)
  static Future<void> closeDb() async {
    final dbManager = DatabaseManager();
    await dbManager.close();

    if (kDebugMode) {
      print('🔒 Base de datos cerrada');
    }
  }

  // Método para limpiar una tabla específica
  static Future<void> clearTable(String tableName) async {
    try {
      final dbManager = DatabaseManager();
      final db = await dbManager.database;

      await db.delete(tableName);

      if (kDebugMode) {
        print('🧹 Tabla $tableName limpiada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al limpiar tabla $tableName: $e');
      }
      rethrow;
    }
  }
}
