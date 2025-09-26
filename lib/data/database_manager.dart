import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseManager {
  static const String _dbName = 'koonol.db';
  static const int _dbVersion = 2; // Incrementado para agregar nuevas tablas
  static Database? _database;
  static bool _isInitialized = false;

  // Singleton pattern
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  // Inicializar SQLite factory si es necesario
  static Future<void> _ensureSQLiteInitialized() async {
    if (!_isInitialized) {
      // Esta línea asegura que el factory esté disponible
      databaseFactory = databaseFactory;
      _isInitialized = true;
    }
  }

  // Getter para obtener la base de datos
  Future<Database> get database async {
    await _ensureSQLiteInitialized();
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Habilitar foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Crear las tablas iniciales
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print('Creando base de datos versión $version...');
    }

    // Tabla tipodepago
    await db.execute('''
      CREATE TABLE tipodepago (
        idTipoPago INTEGER PRIMARY KEY AUTOINCREMENT,
        cTipoPago TEXT NOT NULL,
        nComision TEXT NOT NULL
      )
    ''');

    // Tabla articulo
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

    // Tabla fotoarticulo
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

    // Insertar datos iniciales
    await _insertInitialData(db);

    if (kDebugMode) {
      print('Base de datos creada exitosamente con datos iniciales');
    }
  }

  // Insertar datos iniciales
  Future<void> _insertInitialData(Database db) async {
    if (kDebugMode) {
      print('Insertando datos iniciales...');
    }

    // Datos iniciales para tipodepago
    await db.execute('''
      INSERT INTO tipodepago (cTipoPago, nComision) VALUES 
      ('Efectivo', '0'),
      ('Tarjeta de Crédito/Débito', '3.0'),
      ('Transferencia', '0'),
      ('Cheque', '0')
    ''');

    // Datos iniciales para articulos
    await db.execute('''
      INSERT INTO articulo (idClasificacion, cCodigo, cDescripcion, nPrecio, nCosto) VALUES 
      (1, 'ca', 'Caja de huevo', 380.0, 350.0),
      (1, 'cr', 'Cartón de huevo', 120.0, 80.0),
      (1, 'kl', 'Kilo de huevo', 80.0, 70.0)
    ''');

    if (kDebugMode) {
      print('Datos iniciales insertados correctamente');
    }
  }

  // Manejar actualizaciones de base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print(
        'Actualizando base de datos de versión $oldVersion a $newVersion...',
      );
    }

    if (oldVersion < 2) {
      // Agregar tablas de artículos y fotoarticulo
      try {
        // Verificar si las tablas ya existen
        final tablesResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('articulo', 'fotoarticulo')",
        );

        if (tablesResult.isEmpty) {
          if (kDebugMode) {
            print('Creando nuevas tablas: articulo y fotoarticulo');
          }

          // Crear tabla articulo
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

          // Crear tabla fotoarticulo
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

          // Insertar datos iniciales de artículos
          await db.execute('''
            INSERT INTO articulo (idClasificacion, cCodigo, cDescripcion, nPrecio, nCosto) VALUES 
            (1, 'ca', 'Caja de huevo', 380.0, 350.0),
            (1, 'cr', 'Cartón de huevo', 120.0, 80.0),
            (1, 'kl', 'Kilo de huevo', 80.0, 70.0)
          ''');

          if (kDebugMode) {
            print('Tablas creadas y datos iniciales insertados');
          }
        } else {
          if (kDebugMode) {
            print('Las tablas articulo y/o fotoarticulo ya existen');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error durante la actualización: $e');
        }
        rethrow;
      }
    }

    if (kDebugMode) {
      print('Actualización de base de datos completada');
    }
  }

  // Cerrar la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Método para ejecutar en transacción
  Future<T> transaction<T>(Future<T> Function(Transaction) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Método para verificar si la base de datos está inicializada
  bool get isInitialized => _database != null;

  // Método para recrear la base de datos (DROP y CREATE)
  Future<void> recreateDatabase() async {
    if (kDebugMode) {
      print('Recreando base de datos...');
    }

    // Cerrar la base de datos actual
    await close();

    // Eliminar el archivo de la base de datos
    String path = join(await getDatabasesPath(), _dbName);
    await deleteDatabase(path);

    if (kDebugMode) {
      print('Base de datos eliminada. Creando nueva...');
    }

    // Inicializar de nuevo
    _database = await _initDatabase();

    if (kDebugMode) {
      print('Base de datos recreada exitosamente');
    }
  }

  // Método para obtener información de las tablas
  Future<List<Map<String, dynamic>>> getTablesInfo() async {
    final db = await database;
    return await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
  }

  // Método para verificar la estructura de una tabla
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    final db = await database;
    return await db.rawQuery("PRAGMA table_info($tableName)");
  }
}
