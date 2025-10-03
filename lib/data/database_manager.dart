import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// DatabaseManager consolidado
/// Maneja toda la gestión de la base de datos:
/// - Creación y conexión
/// - Esquema de tablas
/// - Datos iniciales
/// - Migraciones
/// - Utilidades de desarrollo
class DatabaseManager {
  static const String _dbName = 'koonol.db';
  static const int _dbVersion = 5;
  static Database? _database;
  static bool _isInitialized = false;

  // Singleton pattern
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  // ==================== GESTIÓN DE CONEXIÓN ====================

  /// Inicializa el factory de SQLite
  static Future<void> _ensureSQLiteInitialized() async {
    if (!_isInitialized) {
      databaseFactory = databaseFactory;
      _isInitialized = true;
    }
  }

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    await _ensureSQLiteInitialized();
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ==================== CREACIÓN DE TABLAS ====================

  /// Crea todas las tablas en una nueva base de datos
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print('📦 Creando base de datos versión $version...');
    }

    await _createAllTables(db);
    await _insertInitialData(db);

    if (kDebugMode) {
      print('✅ Base de datos creada exitosamente');
    }
  }

  /// Crea todas las tablas del sistema en un solo método
  Future<void> _createAllTables(Database db) async {
    // TABLA: tipodepago
    await db.execute('''
      CREATE TABLE tipodepago (
        idTipoPago INTEGER PRIMARY KEY AUTOINCREMENT,
        cTipoPago TEXT NOT NULL,
        nComision TEXT NOT NULL
      )
    ''');

    // TABLA: articulo
    await db.execute('''
      CREATE TABLE articulo (
        idArticulo INTEGER PRIMARY KEY AUTOINCREMENT,
        idClasificacion INTEGER NOT NULL DEFAULT 1,
        cCodigo TEXT NOT NULL UNIQUE,
        cDescripcion TEXT NOT NULL,
        nPrecio REAL NOT NULL DEFAULT 0.0,
        nCosto REAL NOT NULL DEFAULT 0.0,
        CONSTRAINT chk_precio CHECK (nPrecio >= 0),
        CONSTRAINT chk_costo CHECK (nCosto >= 0)
      )
    ''');

    // TABLA: fotoarticulo
    await db.execute('''
      CREATE TABLE fotoarticulo (
        idArticulo INTEGER NOT NULL,
        idFoto INTEGER NOT NULL,
        cNombre TEXT NOT NULL,
        cRuta TEXT NOT NULL,
        PRIMARY KEY (idArticulo, idFoto),
        FOREIGN KEY (idArticulo) REFERENCES articulo(idArticulo) ON DELETE CASCADE
      )
    ''');

    // TABLA: cortecaja
    await db.execute('''
      CREATE TABLE cortecaja (
        idCorteCaja INTEGER PRIMARY KEY AUTOINCREMENT,
        idSucursal INTEGER NOT NULL DEFAULT 1,
        idUsuario INTEGER NOT NULL DEFAULT 1,
        dtAlta TEXT NOT NULL,
        dtFecha TEXT NOT NULL,
        cEstado TEXT NOT NULL DEFAULT 'ABIERTO',
        nImporte REAL NOT NULL DEFAULT 0.0,
        CONSTRAINT chk_estado CHECK (cEstado IN ('ABIERTO', 'CERRADO'))
      )
    ''');

    // TABLA: venta
    await db.execute('''
      CREATE TABLE venta (
        idVenta INTEGER PRIMARY KEY AUTOINCREMENT,
        idCliente INTEGER NOT NULL,
        nImporte REAL NOT NULL DEFAULT 0.0,
        nIVA REAL NOT NULL DEFAULT 0.0,
        nDescuento REAL NOT NULL DEFAULT 0.0,
        nTotalPagado REAL NOT NULL DEFAULT 0.0,
        nCambio REAL NOT NULL DEFAULT 0.0,
        dtAlta TEXT NOT NULL,
        dtFecha TEXT NOT NULL,
        cEstado TEXT NOT NULL DEFAULT 'ACTIVA',
        CONSTRAINT chk_importe CHECK (nImporte >= 0),
        CONSTRAINT chk_iva CHECK (nIVA >= 0),
        CONSTRAINT chk_descuento CHECK (nDescuento >= 0),
        CONSTRAINT chk_estado CHECK (cEstado IN ('ACTIVA', 'CANCELADA'))
      )
    ''');

    // TABLA: ventadetalle
    await db.execute('''
      CREATE TABLE ventadetalle (
        idVenta INTEGER NOT NULL,
        idArticulo INTEGER NOT NULL,
        idPrecio INTEGER NOT NULL DEFAULT 1,
        nCantidad REAL NOT NULL DEFAULT 1.0,
        nPrecio REAL NOT NULL DEFAULT 0.0,
        nCosto REAL NOT NULL DEFAULT 0.0,
        dtAlta TEXT NOT NULL,
        PRIMARY KEY (idVenta, idArticulo),
        FOREIGN KEY (idVenta) REFERENCES venta(idVenta) ON DELETE CASCADE,
        FOREIGN KEY (idArticulo) REFERENCES articulo(idArticulo),
        CONSTRAINT chk_cantidad CHECK (nCantidad > 0),
        CONSTRAINT chk_precio_det CHECK (nPrecio >= 0),
        CONSTRAINT chk_costo_det CHECK (nCosto >= 0)
      )
    ''');

    // TABLA: ventatipopago
    await db.execute('''
      CREATE TABLE ventatipopago (
        idVenta INTEGER NOT NULL,
        idTipoPago INTEGER NOT NULL,
        nImporte REAL NOT NULL DEFAULT 0.0,
        dtAlta TEXT NOT NULL,
        PRIMARY KEY (idVenta, idTipoPago),
        FOREIGN KEY (idVenta) REFERENCES venta(idVenta) ON DELETE CASCADE,
        FOREIGN KEY (idTipoPago) REFERENCES tipodepago(idTipoPago),
        CONSTRAINT chk_importe_pago CHECK (nImporte >= 0)
      )
    ''');

    // TABLA: cortecajaventa
    await db.execute('''
      CREATE TABLE cortecajaventa (
        idCorteCaja INTEGER NOT NULL,
        idVenta INTEGER NOT NULL,
        nImporte REAL NOT NULL DEFAULT 0.0,
        nIVA REAL NOT NULL DEFAULT 0.0,
        nDescuento REAL NOT NULL DEFAULT 0.0,
        dtAlta TEXT NOT NULL,
        PRIMARY KEY (idCorteCaja, idVenta),
        FOREIGN KEY (idCorteCaja) REFERENCES cortecaja(idCorteCaja),
        FOREIGN KEY (idVenta) REFERENCES venta(idVenta) ON DELETE CASCADE
      )
    ''');

    // TABLA: acumcortetipopago
    await db.execute('''
      CREATE TABLE acumcortetipopago (
        idCorteCaja INTEGER NOT NULL,
        idTipoPago INTEGER NOT NULL,
        nImporte REAL NOT NULL DEFAULT 0.0,
        dtAlta TEXT NOT NULL,
        PRIMARY KEY (idCorteCaja, idTipoPago),
        FOREIGN KEY (idCorteCaja) REFERENCES cortecaja(idCorteCaja),
        FOREIGN KEY (idTipoPago) REFERENCES tipodepago(idTipoPago)
      )
    ''');

    // TABLA: acumcortedetalle
    await db.execute('''
      CREATE TABLE acumcortedetalle (
        idCorte INTEGER NOT NULL,
        idArticulo INTEGER NOT NULL,
        dtAlta TEXT NOT NULL,
        nImporte REAL NOT NULL DEFAULT 0.0,
        nCosto REAL NOT NULL DEFAULT 0.0,
        PRIMARY KEY (idCorte, idArticulo),
        FOREIGN KEY (idCorte) REFERENCES cortecaja(idCorteCaja),
        FOREIGN KEY (idArticulo) REFERENCES articulo(idArticulo)
      )
    ''');

    // TABLA: usuario
    await db.execute('''
      CREATE TABLE usuario (
        idUsuario INTEGER PRIMARY KEY AUTOINCREMENT,
        cUsuario TEXT NOT NULL UNIQUE,
        cNombre TEXT NOT NULL,
        cContrasena TEXT NOT NULL
      )
    ''');

    if (kDebugMode) {
      print('✅ Todas las tablas creadas exitosamente');
    }
  }

  // ==================== DATOS INICIALES ====================

  /// Encripta contraseñas usando SHA-256
  String encriptarContrasena(String contrasena) {
    final bytes = utf8.encode(contrasena);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Inserta datos iniciales en las tablas
  Future<void> _insertInitialData(Database db) async {
    if (kDebugMode) {
      print('📝 Insertando datos iniciales...');
    }

    // Datos: tipodepago
    await db.execute('''
      INSERT INTO tipodepago (cTipoPago, nComision) VALUES 
      ('Efectivo', '0'),
      ('Transferencia', '0')
    ''');
    /*
      ('T Crédito/Débito', '3.0'),
      ('Cheque', '0')
    */

    // Datos: articulos
    await db.execute('''
      INSERT INTO articulo (idClasificacion, cCodigo, cDescripcion, nPrecio, nCosto) VALUES 
      (1, 'kl', 'Kilo de huevo', 80.0, 70.0),
      (1, 'ca', 'Caja de huevo', 80.0, 350.0),
      (1, 'cr', 'Cartón de huevo', 80.0, 80.0)
    ''');

    // Datos: usuarios
    final contrasenaEncriptada = encriptarContrasena('12345');
    await db.execute('''
      INSERT INTO usuario (cUsuario, cNombre, cContrasena) VALUES 
      ('luis', 'Luis Ek', '$contrasenaEncriptada'),
      ('cajero', 'Cajero de prueba', '$contrasenaEncriptada')
    ''');

    if (kDebugMode) {
      print('✅ Datos iniciales insertados correctamente');
    }
  }

  /// Inserta datos de prueba adicionales (para desarrollo)
  Future<void> insertTestData() async {
    try {
      final db = await database;

      if (kDebugMode) {
        print('📊 Insertando datos de prueba adicionales...');
      }

      // Verificar si ya hay datos
      final existingArticulos = await db.rawQuery(
        'SELECT COUNT(*) as count FROM articulo',
      );
      final count = existingArticulos.first['count'] as int;

      if (count <= 3) {
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
          print('ℹ️ Ya existen datos suficientes en articulo');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al insertar datos de prueba: $e');
      }
      rethrow;
    }
  }

  // ==================== MIGRACIONES ====================

  /// Maneja actualizaciones de versiones de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('🔄 Actualizando BD de v$oldVersion a v$newVersion...');
    }

    // Migración a versión 2: Agregar tablas articulo y fotoarticulo
    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }

    // Migración a versión 3: Agregar tablas de ventas y cortes
    if (oldVersion < 3) {
      await _migrateToVersion3(db);
    }

    // Migración a versión 4: Agregar tabla usuario
    if (oldVersion < 4) {
      await _migrateToVersion4(db);
    }

    // Migración a versión 5: Agregar campo cEstado a venta
    if (oldVersion < 5) {
      await _migrateToVersion5(db);
    }

    if (kDebugMode) {
      print('✅ Actualización completada');
    }
  }

  Future<void> _migrateToVersion2(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('articulo', 'fotoarticulo')",
    );

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE articulo (
          idArticulo INTEGER PRIMARY KEY AUTOINCREMENT,
          idClasificacion INTEGER NOT NULL DEFAULT 1,
          cCodigo TEXT NOT NULL UNIQUE,
          cDescripcion TEXT NOT NULL,
          nPrecio REAL NOT NULL DEFAULT 0.0,
          nCosto REAL NOT NULL DEFAULT 0.0,
          CONSTRAINT chk_precio CHECK (nPrecio >= 0),
          CONSTRAINT chk_costo CHECK (nCosto >= 0)
        )
      ''');

      await db.execute('''
        CREATE TABLE fotoarticulo (
          idArticulo INTEGER NOT NULL,
          idFoto INTEGER NOT NULL,
          cNombre TEXT NOT NULL,
          cRuta TEXT NOT NULL,
          PRIMARY KEY (idArticulo, idFoto),
          FOREIGN KEY (idArticulo) REFERENCES articulo(idArticulo) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        INSERT INTO articulo (idClasificacion, cCodigo, cDescripcion, nPrecio, nCosto) VALUES 
        (1, 'kl', 'Kilo de huevo', 80.0, 70.0)
        (1, 'ca', 'Caja de huevo', 80.0, 350.0),
        (1, 'cr', 'Cartón de huevo', 80.0, 80.0),
      ''');
    }
  }

  Future<void> _migrateToVersion3(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('cortecaja', 'venta')",
    );

    final existingTables = tables.map((row) => row['name'] as String).toSet();

    if (!existingTables.contains('cortecaja')) {
      await db.execute('''
        CREATE TABLE cortecaja (
          idCorteCaja INTEGER PRIMARY KEY AUTOINCREMENT,
          idSucursal INTEGER NOT NULL DEFAULT 1,
          idUsuario INTEGER NOT NULL DEFAULT 1,
          dtAlta TEXT NOT NULL,
          dtFecha TEXT NOT NULL,
          cEstado TEXT NOT NULL DEFAULT 'ABIERTO',
          nImporte REAL NOT NULL DEFAULT 0.0,
          CONSTRAINT chk_estado CHECK (cEstado IN ('ABIERTO', 'CERRADO'))
        )
      ''');
    }

    if (!existingTables.contains('venta')) {
      await db.execute('''
        CREATE TABLE venta (
          idVenta INTEGER PRIMARY KEY AUTOINCREMENT,
          idCliente INTEGER NOT NULL,
          nImporte REAL NOT NULL DEFAULT 0.0,
          nIVA REAL NOT NULL DEFAULT 0.0,
          nDescuento REAL NOT NULL DEFAULT 0.0,
          nTotalPagado REAL NOT NULL DEFAULT 0.0,
          nCambio REAL NOT NULL DEFAULT 0.0,
          dtAlta TEXT NOT NULL,
          dtFecha TEXT NOT NULL,
          cEstado TEXT NOT NULL DEFAULT 'ACTIVA',
          CONSTRAINT chk_importe CHECK (nImporte >= 0),
          CONSTRAINT chk_iva CHECK (nIVA >= 0),
          CONSTRAINT chk_descuento CHECK (nDescuento >= 0),
          CONSTRAINT chk_estado CHECK (cEstado IN ('ACTIVA', 'CANCELADA'))
        )
      ''');
    }

    // Crear tablas relacionadas si no existen
    if (!existingTables.contains('ventadetalle')) {
      await db.execute('''
        CREATE TABLE ventadetalle (
          idVenta INTEGER NOT NULL,
          idArticulo INTEGER NOT NULL,
          idPrecio INTEGER NOT NULL DEFAULT 1,
          nCantidad REAL NOT NULL DEFAULT 1.0,
          nPrecio REAL NOT NULL DEFAULT 0.0,
          nCosto REAL NOT NULL DEFAULT 0.0,
          dtAlta TEXT NOT NULL,
          PRIMARY KEY (idVenta, idArticulo),
          FOREIGN KEY (idVenta) REFERENCES venta(idVenta) ON DELETE CASCADE,
          FOREIGN KEY (idArticulo) REFERENCES articulo(idArticulo),
          CONSTRAINT chk_cantidad CHECK (nCantidad > 0),
          CONSTRAINT chk_precio_det CHECK (nPrecio >= 0),
          CONSTRAINT chk_costo_det CHECK (nCosto >= 0)
        )
      ''');
    }

    if (!existingTables.contains('ventatipopago')) {
      await db.execute('''
        CREATE TABLE ventatipopago (
          idVenta INTEGER NOT NULL,
          idTipoPago INTEGER NOT NULL,
          nImporte REAL NOT NULL DEFAULT 0.0,
          dtAlta TEXT NOT NULL,
          PRIMARY KEY (idVenta, idTipoPago),
          FOREIGN KEY (idVenta) REFERENCES venta(idVenta) ON DELETE CASCADE,
          FOREIGN KEY (idTipoPago) REFERENCES tipodepago(idTipoPago),
          CONSTRAINT chk_importe_pago CHECK (nImporte >= 0)
        )
      ''');
    }

    if (!existingTables.contains('cortecajaventa')) {
      await db.execute('''
        CREATE TABLE cortecajaventa (
          idCorteCaja INTEGER NOT NULL,
          idVenta INTEGER NOT NULL,
          nImporte REAL NOT NULL DEFAULT 0.0,
          nIVA REAL NOT NULL DEFAULT 0.0,
          nDescuento REAL NOT NULL DEFAULT 0.0,
          dtAlta TEXT NOT NULL,
          PRIMARY KEY (idCorteCaja, idVenta),
          FOREIGN KEY (idCorteCaja) REFERENCES cortecaja(idCorteCaja),
          FOREIGN KEY (idVenta) REFERENCES venta(idVenta) ON DELETE CASCADE
        )
      ''');
    }

    if (!existingTables.contains('acumcortetipopago')) {
      await db.execute('''
        CREATE TABLE acumcortetipopago (
          idCorteCaja INTEGER NOT NULL,
          idTipoPago INTEGER NOT NULL,
          nImporte REAL NOT NULL DEFAULT 0.0,
          dtAlta TEXT NOT NULL,
          PRIMARY KEY (idCorteCaja, idTipoPago),
          FOREIGN KEY (idCorteCaja) REFERENCES cortecaja(idCorteCaja),
          FOREIGN KEY (idTipoPago) REFERENCES tipodepago(idTipoPago)
        )
      ''');
    }

    if (!existingTables.contains('acumcortedetalle')) {
      await db.execute('''
        CREATE TABLE acumcortedetalle (
          idCorte INTEGER NOT NULL,
          idArticulo INTEGER NOT NULL,
          dtAlta TEXT NOT NULL,
          nImporte REAL NOT NULL DEFAULT 0.0,
          nCosto REAL NOT NULL DEFAULT 0.0,
          PRIMARY KEY (idCorte, idArticulo),
          FOREIGN KEY (idCorte) REFERENCES cortecaja(idCorteCaja),
          FOREIGN KEY (idArticulo) REFERENCES articulo(idArticulo)
        )
      ''');
    }
  }

  Future<void> _migrateToVersion4(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = 'usuario'",
    );

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE usuario (
          idUsuario INTEGER PRIMARY KEY AUTOINCREMENT,
          cUsuario TEXT NOT NULL UNIQUE,
          cNombre TEXT NOT NULL,
          cContrasena TEXT NOT NULL
        )
      ''');

      final contrasenaEncriptada = encriptarContrasena('12345');
      await db.execute('''
        INSERT INTO usuario (cUsuario, cNombre, cContrasena) VALUES 
        ('luis', 'Luis Ek', '$contrasenaEncriptada'),
        ('cajero', 'Cajero de prueba', '$contrasenaEncriptada')
      ''');
    }
  }

  Future<void> _migrateToVersion5(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(venta)');
    final hasEstado = columns.any((col) => col['name'] == 'cEstado');

    if (!hasEstado) {
      await db.execute(
        "ALTER TABLE venta ADD COLUMN cEstado TEXT NOT NULL DEFAULT 'ACTIVA'",
      );
    }
  }

  // ==================== UTILIDADES ====================

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Ejecuta operaciones en transacción
  Future<T> transaction<T>(Future<T> Function(Transaction) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Verifica si la base de datos está inicializada
  bool get isInitialized => _database != null;

  /// Recrea completamente la base de datos (DROP y CREATE)
  Future<void> recreateDatabase() async {
    if (kDebugMode) {
      print('🔄 Recreando base de datos...');
    }

    await close();
    String path = join(await getDatabasesPath(), _dbName);
    await deleteDatabase(path);

    if (kDebugMode) {
      print('🗑️ Base de datos eliminada');
    }

    _database = await _initDatabase();

    if (kDebugMode) {
      print('✅ Base de datos recreada exitosamente');
    }
  }

  /// Obtiene información de todas las tablas
  Future<List<Map<String, dynamic>>> getTablesInfo() async {
    final db = await database;
    return await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
  }

  /// Obtiene la estructura de una tabla específica
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    final db = await database;
    return await db.rawQuery("PRAGMA table_info($tableName)");
  }

  /// Limpia una tabla específica (elimina todos los registros)
  Future<void> clearTable(String tableName) async {
    try {
      final db = await database;
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

  /// Verifica el estado de la base de datos (para debugging)
  Future<Map<String, dynamic>> checkDatabaseStatus() async {
    try {
      final db = await database;
      final tables = await getTablesInfo();
      final tableNames = tables.map((t) => t['name'] as String).toList();

      Map<String, int> tableCounts = {};
      for (String tableName in tableNames) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName',
          );
          tableCounts[tableName] = result.first['count'] as int;
        } catch (e) {
          tableCounts[tableName] = -1;
        }
      }

      return {
        'status': 'success',
        'tables': tableNames,
        'counts': tableCounts,
        'isInitialized': isInitialized,
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString(), 'isInitialized': false};
    }
  }

  /// Muestra información de debug de la base de datos
  Future<void> showDatabaseInfo() async {
    if (kDebugMode) {
      try {
        final tables = await getTablesInfo();
        print('📊 Tablas en la base de datos:');

        for (var table in tables) {
          final tableName = table['name'] as String;
          print('  - $tableName');

          final structure = await getTableStructure(tableName);
          for (var column in structure) {
            print('    • ${column['name']} (${column['type']})');
          }
        }

        final db = await database;
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
        print('⚠️ Error al mostrar información: $e');
      }
    }
  }

  // ==================== MÉTODO DE INICIALIZACIÓN PRINCIPAL ====================

  /// Inicializa la base de datos desde la aplicación
  /// Este es el método principal que debe llamarse al inicio
  static Future<void> initialize({bool forceRecreate = false}) async {
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
        await dbManager.database;
      }

      await dbManager.showDatabaseInfo();

      if (kDebugMode) {
        print('✅ Base de datos lista para usar');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar la base de datos: $e');
      }
      rethrow;
    }
  }
}
