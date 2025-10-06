import 'package:flutter/material.dart';
import 'package:koonol/screens/consulta_ventas_screen.dart';
import 'package:koonol/screens/graficos_ventas_screen.dart';
import 'package:koonol/screens/venta_simple_screen.dart';
import '../services/auth_service.dart';
import 'ventas_screen.dart';
import 'login_screen.dart';

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  AuthService? _authService;
  String _nombreUsuario = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    _authService = await AuthService.getInstance();
    setState(() {
      _nombreUsuario = _authService?.nombreUsuarioActual ?? 'Usuario';
      _isLoading = false;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _authService?.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navegarAVentas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VentaSimpleScreen()),
    );
  }

  void _navegarAGraficos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GraficosVentasScreen()),
    );
  }

  void _navegarAConsultaVentas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConsultaVentasScreen()),
    );
  }

  void _mostrarEnDesarrollo(String opcion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Has seleccionado: $opcion'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: SafeArea(
            child: Column(
              children: [
                // Header con bienvenida y botón cerrar sesión
                _buildHeader(),

                // Contenido del menú
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildMenuOptions(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _nombreUsuario,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo/Título
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.store, size: 60, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 24),
          Text(
            'Koonol',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Menú Principal',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Opciones del menú
          _buildMenuCard(
            icon: Icons.shopping_cart,
            title: 'Ventas',
            subtitle: 'Realizar nueva venta',
            color: Colors.green,
            onTap: _navegarAVentas,
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            icon: Icons.bar_chart,
            title: 'Gráficos de Ventas',
            subtitle: 'Visualizar estadísticas',
            color: Colors.purple,
            onTap: _navegarAGraficos,
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            icon: Icons.receipt_long,
            title: 'Consulta de Ventas',
            subtitle: 'Ver historial de ventas',
            color: Colors.blue,
            onTap: _navegarAConsultaVentas,
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            icon: Icons.inventory_2,
            title: 'Artículos',
            subtitle: 'Gestionar inventario',
            color: Colors.orange,
            onTap: () => _mostrarEnDesarrollo('Artículos'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
