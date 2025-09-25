import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static const String _dbName = 'koonol.db';
  static const int _dbVersion = 1;
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
        // Habilitar foreign keys si las necesitas
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Crear las tablas iniciales
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tipodepago (
        idTipoPago INTEGER PRIMARY KEY AUTOINCREMENT,
        cTipoPago TEXT NOT NULL,
        nComision TEXT NOT NULL
      )
    ''');

    // Insertar datos iniciales
    await db.execute('''
      INSERT INTO tipodepago (cTipoPago, nComision) VALUES 
      ('Efectivo', '0'),
      ('Tarjeta de Crédito/Débito', '3.0'),
      ('Transferencia', '0'),
      ('Cheque', '0')
    ''');

    // Aquí puedes agregar más tablas conforme las necesites
    // await db.execute('''CREATE TABLE ventas (...) ''');
    // await db.execute('''CREATE TABLE detalle_ventas (...) ''');
  }

  // Manejar actualizaciones de base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí manejarás las migraciones cuando actualices la estructura
    if (oldVersion < 2) {
      // Ejemplo: await db.execute('ALTER TABLE tipodepago ADD COLUMN nuevo_campo TEXT');
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
}
