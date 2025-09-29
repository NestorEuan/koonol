import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/corte_caja_service.dart';
import 'screens/ventas_screen.dart';
import 'data/data_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización normal
  // Inicializar la base de datos antes de ejecutar la app
  try {
    // 1. Inicializar la base de datos
    if (kDebugMode) {
      print('🚀 Inicializando base de datos...');
    }
    await DataInit.initDb();

    // 2. Inicializar el sistema de cortes de caja
    if (kDebugMode) {
      print('📊 Inicializando sistema de cortes...');
    }
    final corteCajaService = await CorteCajaService.getInstance();
    final resultadoCortes = await corteCajaService.inicializarSistemaCortes();

    if (resultadoCortes['inicializado']) {
      if (kDebugMode) {
        print('✅ Sistema inicializado correctamente');
        print('📋 ${corteCajaService.obtenerResumenCorte()}');
      }
    } else {
      if (kDebugMode) {
        print(
          '⚠️ Advertencia en inicialización de cortes: ${resultadoCortes['mensaje']}',
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error crítico al inicializar la aplicación: $e');
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
