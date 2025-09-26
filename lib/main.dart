import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/ventas_screen.dart';
import 'data/data_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización normal
  // Inicializar la base de datos antes de ejecutar la app
  try {
    await DataInit.initDb();
  } catch (e) {
    if (kDebugMode) {
      print('Error crítico al inicializar la base de datos: $e');
    }
    // Aquí podrías mostrar un dialog de error o manejar el fallo
  }

  // O para recrear completamente la base de datos:
  // await DataInit.recreateDb();

  // O para verificar el estado:
  // final status = await DataInit.checkDatabaseStatus();
  // print('Estado de la DB: $status');

  runApp(const VentasApp());
}

class VentasApp extends StatelessWidget {
  const VentasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Ventas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      home: const VentasScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
