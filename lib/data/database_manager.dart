import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseManager {
  static const String _dbName = 'koonol.db';
  static const int _dbVersion =
      5; //4; // Incrementado para agregar nuevas tablas
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

    // Tabla cortecaja
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

    // Tabla venta
    // Tabla venta
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

    // Tabla ventadetalle
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

    // Tabla ventatipopago
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

    // Tabla cortecajaventa
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

    // Tabla acumcortetipopago
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

    // Tabla acumcortedetalle
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

    // Tabla usuario
    await db.execute('''
      CREATE TABLE usuario (
        idUsuario INTEGER PRIMARY KEY AUTOINCREMENT,
        cUsuario TEXT NOT NULL UNIQUE,
        cNombre TEXT NOT NULL,
        cContrasena TEXT NOT NULL
      )
    ''');

    // Insertar datos iniciales
    await _insertInitialData(db);

    if (kDebugMode) {
      print('Base de datos creada exitosamente con datos iniciales');
    }
  }

  // Función auxiliar para encriptar contraseñas
  String encriptarContrasena(String contrasena) {
    final bytes = utf8.encode(contrasena);
    final hash = sha256.convert(bytes);
    return hash.toString();
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

    // Datos iniciales para usuarios
    final contrasenaEncriptada = encriptarContrasena('12345');
    await db.execute('''
      INSERT INTO usuario (cUsuario, cNombre, cContrasena) VALUES 
      ('luis', 'Luis Ek', '$contrasenaEncriptada'),
      ('cajero', 'Cajero de prueba', '$contrasenaEncriptada')
    ''');
  }

  // Manejar actualizaciones de base de datos
  // En lib/data/database_manager.dart
  // Reemplazar el método _onUpgrade completo

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print(
        'Actualizando base de datos de versión $oldVersion a $newVersion...',
      );
    }

    if (oldVersion < 2) {
      // Crear tablas de artículos y fotoarticulo si no existen
      try {
        final tablesResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('articulo', 'fotoarticulo')",
        );

        if (tablesResult.isEmpty) {
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
          (1, 'ca', 'Caja de huevo', 380.0, 350.0),
          (1, 'cr', 'Cartón de huevo', 120.0, 80.0),
          (1, 'kl', 'Kilo de huevo', 80.0, 70.0)
        ''');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error durante la actualización v2: $e');
        }
        rethrow;
      }
    }

    if (oldVersion < 3) {
      // Crear tablas de ventas y cortes
      try {
        final tablesResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('cortecaja', 'venta', 'ventadetalle', 'ventatipopago', 'cortecajaventa', 'acumcortetipopago', 'acumcortedetalle')",
        );

        final existingTables = tablesResult
            .map((row) => row['name'] as String)
            .toSet();

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

        if (kDebugMode) {
          print('Tablas de ventas y cortes creadas exitosamente');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error durante la actualización v3: $e');
        }
        rethrow;
      }
    }

    if (oldVersion < 4) {
      // Crear tabla usuario
      try {
        final tablesResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = 'usuario'",
        );

        if (tablesResult.isEmpty) {
          await db.execute('''
          CREATE TABLE usuario (
            idUsuario INTEGER PRIMARY KEY AUTOINCREMENT,
            cUsuario TEXT NOT NULL UNIQUE,
            cNombre TEXT NOT NULL,
            cContrasena TEXT NOT NULL
          )
        ''');

          String encriptarContrasena(String contrasena) {
            final bytes = utf8.encode(contrasena);
            final hash = sha256.convert(bytes);
            return hash.toString();
          }

          final contrasenaEncriptada = encriptarContrasena('12345');
          await db.execute('''
          INSERT INTO usuario (cUsuario, cNombre, cContrasena) VALUES 
          ('luis', 'Luis Ek', '$contrasenaEncriptada'),
          ('cajero', 'Cajero de prueba', '$contrasenaEncriptada')
        ''');

          if (kDebugMode) {
            print('Tabla usuario creada exitosamente');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error durante la actualización v4: $e');
        }
        rethrow;
      }
    }

    if (oldVersion < 5) {
      // CRÍTICO: Agregar campo cEstado a la tabla venta
      try {
        // Verificar si la columna ya existe
        final columns = await db.rawQuery('PRAGMA table_info(venta)');
        final hasEstado = columns.any((col) => col['name'] == 'cEstado');

        if (!hasEstado) {
          await db.execute('''
          ALTER TABLE venta ADD COLUMN cEstado TEXT NOT NULL DEFAULT 'ACTIVA'
        ''');

          if (kDebugMode) {
            print('✅ Columna cEstado agregada a tabla venta');
          }
        } else {
          if (kDebugMode) {
            print('ℹ️ Columna cEstado ya existe en tabla venta');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error al agregar columna cEstado: $e');
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
