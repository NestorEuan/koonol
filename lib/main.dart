import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:koonol/data/data_init.dart';
import 'services/corte_caja_service.dart';
import 'screens/ventas_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget que maneja la inicialización de la aplicación
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // No inicializamos aquí, lo haremos desde el splash
  }

  /// Inicializa la aplicación (base de datos y servicios)
  Future<void> _initializeApp() async {
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

      // Marcar como inicializado
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error crítico al inicializar la aplicación: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar la aplicación: $e';
          _isInitialized = true; // Continuar de todos modos
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Mostrar splash screen mientras se inicializa
      return SplashScreen(onInitComplete: _initializeApp);
    }

    // Si hubo error, mostrar mensaje pero continuar a la pantalla principal
    if (_errorMessage != null) {
      // Mostrar error después de la inicialización
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }

    // Mostrar pantalla principal
    //return const VentasScreen();
    // Verificar si hay sesión activa
    return FutureBuilder<bool>(
      future: _verificarSesion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay sesión activa, ir a VentasScreen, si no, ir a LoginScreen
        if (snapshot.data == true) {
          return const VentasScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  // Verifica si hay una sesión activa
  Future<bool> _verificarSesion() async {
    try {
      final authService = await AuthService.getInstance();
      return await authService.verificarSesion();
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar sesión: $e');
      }
      return false;
    }
  }
}
