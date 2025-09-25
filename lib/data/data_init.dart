import 'package:flutter/foundation.dart';

import 'database_manager.dart';

class DataInit {
  // Inicializar la base de datos de la aplicación
  static Future<void> initDb() async {
    try {
      final dbManager = DatabaseManager();
      // Al llamar database se ejecuta automáticamente _initDatabase si es necesario
      await dbManager.database;
      if (kDebugMode) {
        print('Base de datos inicializada correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar la base de datos: $e');
      }
      rethrow;
    }
  }

  // Método para cerrar la base de datos (opcional, para casos específicos)
  static Future<void> closeDb() async {
    final dbManager = DatabaseManager();
    await dbManager.close();
  }
}
