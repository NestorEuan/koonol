import 'package:flutter/material.dart';
import 'package:koonol/screens/login_screen.dart';
import 'package:koonol/screens/menu_principal_screen.dart';
import 'package:koonol/services/auth_service.dart';
import 'package:koonol/services/venta_service.dart';
import 'package:koonol/services/ui_service.dart';
import '../models/cliente.dart';
import '../models/articulo_mdl.dart';
import '../models/tipo_pago_mdl.dart';
import '../models/carrito_item.dart';
import '../data/articulo.dart';
import '../data/tipo_pago.dart';
import '../widgets/cliente_search_widget.dart';
import '../widgets/articulo_kilo_simple_widget.dart';
import '../widgets/tipos_pago_widget.dart';
import '../widgets/validacion_cobro_widget.dart';
import '../widgets/total_venta_widget.dart';

/// Pantalla de venta simple
/// Todo el flujo de venta en una sola pantalla usando widgets reutilizables
class VentaSimpleScreen extends StatefulWidget {
  const VentaSimpleScreen({super.key});

  @override
  State<VentaSimpleScreen> createState() => _VentaSimpleScreenState();
}

class _VentaSimpleScreenState extends State<VentaSimpleScreen> {
  // Repositorios y servicios
  VentaService? _ventaService;
  Articulo? _articuloRepository;
  TipoPago? _tipoPagoRepository;

  // Estado de la pantalla
  Cliente? _clienteSeleccionado;
  ArticuloMdl? _articuloKilo;
  List<TipoPagoMdl> _tiposPago = [];
  final Map<int, double> _montosPago = {};

  // Variables para el artículo
  double _cantidadArticulo = 1.0;
  double _precioArticulo = 0.0;

  // Key para forzar reconstrucción del widget
  int _articuloWidgetKey = 0;

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  Future<void> _inicializarPantalla() async {
    try {
      // Inicializar servicios
      _ventaService = await VentaService.getInstance();
      _articuloRepository = await Articulo.getInstance();
      _tipoPagoRepository = await TipoPago.getInstance();

      // Cargar artículo kilo
      await _cargarArticuloKilo();

      // Cargar tipos de pago
      await _cargarTiposPago();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarArticuloKilo() async {
    try {
      final articulos = await _articuloRepository!.searchByCodigo('kl');

      if (articulos.isNotEmpty) {
        setState(() {
          _articuloKilo = articulos.first;
          _precioArticulo =
              articulos.first.nPrecio; // Establecer precio inicial
        });
      } else {
        throw Exception('No se encontró el artículo "Kilo de huevo"');
      }
    } catch (e) {
      throw Exception('Error al cargar artículo: $e');
    }
  }

  Future<void> _cargarTiposPago() async {
    try {
      final tipos = await _tipoPagoRepository!.getTiposPago();
      setState(() {
        _tiposPago = tipos;

        // Inicializar montos en 0
        for (var tipoPago in _tiposPago) {
          final id = tipoPago.idTipoPago ?? 0;
          _montosPago[id] = 0.0;
        }
      });
    } catch (e) {
      throw Exception('Error al cargar tipos de pago: $e');
    }
  }

  void _onClienteSelected(Cliente? cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
    });
  }

  void _onMontoChanged(int idTipoPago, double monto) {
    setState(() {
      _montosPago[idTipoPago] = monto;
    });
  }

  // Cálculos
  double get _totalVenta => _cantidadArticulo * _precioArticulo;

  double get _totalPagos =>
      _montosPago.values.fold(0.0, (sum, monto) => sum + monto);

  double get _montoEfectivo {
    try {
      final efectivo = _tiposPago.firstWhere(
        (tipo) => tipo.cTipoPago.toLowerCase().contains('efectivo'),
      );
      return _montosPago[efectivo.idTipoPago] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double get _cambio {
    if (_montoEfectivo > 0 && _totalPagos > _totalVenta) {
      final exceso = _totalPagos - _totalVenta;
      return exceso <= _montoEfectivo ? exceso : _montoEfectivo;
    }
    return 0.0;
  }

  bool get _puedeConfirmar {
    return _clienteSeleccionado != null &&
        _cantidadArticulo > 0 &&
        _precioArticulo > 0 &&
        _totalPagos >= _totalVenta &&
        (_totalPagos == _totalVenta || _montoEfectivo > 0);
  }

  Future<void> _finalizarVenta() async {
    if (!_puedeConfirmar) {
      UIService.showWarning(context, 'Verifique los datos de la venta');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Crear carrito con el artículo
      final carrito = [
        CarritoItem(
          articulo: _articuloKilo!,
          cantidad: _cantidadArticulo,
          precioVenta: _precioArticulo,
        ),
      ];

      // Filtrar solo los tipos de pago con monto > 0
      final Map<int, double> tiposPagoFiltrados = {};
      _montosPago.forEach((id, monto) {
        if (monto > 0) {
          tiposPagoFiltrados[id] = monto;
        }
      });

      // Procesar venta
      final resultado = await _ventaService!.procesarVenta(
        cliente: _clienteSeleccionado!,
        carrito: carrito,
        tiposPago: tiposPagoFiltrados,
        totalPagado: _totalPagos,
        cambio: _cambio,
        descuento: 0.0,
        iva: 0.0,
      );

      if (mounted) {
        setState(() => _isProcessing = false);

        if (resultado['success']) {
          // Mostrar resultado exitoso
          await _mostrarResumenVenta(resultado);

          // Limpiar todo
          _limpiarFormulario();
        } else {
          UIService.showError(
            context,
            'Error al procesar venta: ${resultado['mensaje'] ?? 'Error desconocido'}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        UIService.showError(context, 'Error al procesar venta: $e');
      }
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _clienteSeleccionado = null;
      _cantidadArticulo = 1.0;
      _precioArticulo = _articuloKilo?.nPrecio ?? 0.0;
      _montosPago.updateAll((key, value) => 0.0);
      _articuloWidgetKey++; // Forzar reconstrucción del widget
    });
  }

  Future<void> _mostrarResumenVenta(Map<String, dynamic> resultado) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Venta Completada',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumenRow('Venta ID:', '#${resultado['idVenta']}'),
            _buildResumenRow(
              'Total:',
              '\$${resultado['total'].toStringAsFixed(2)}',
            ),
            _buildResumenRow(
              'Pagado:',
              '\$${resultado['totalPagado'].toStringAsFixed(2)}',
            ),
            if (_cambio > 0)
              _buildResumenRow(
                'Cambio:',
                '\$${_cambio.toStringAsFixed(2)}',
                color: Colors.red,
                esBold: true,
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: const Text('Nueva Venta', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(
    String label,
    String valor, {
    bool esBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: esBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: esBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Ventas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _mostrarMenuOpciones(context),
          tooltip: 'Menú',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _inicializarPantalla,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Inicializando sistema de ventas...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _inicializarPantalla,
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Mostrar todos los widgets siempre
    return Column(
      children: [
        // Widget de búsqueda de cliente
        ClienteSearchWidget(
          onClienteSelected: _onClienteSelected,
          clienteSeleccionado: _clienteSeleccionado,
        ),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Widget del artículo kilo
                if (_articuloKilo != null)
                  ArticuloKiloSimpleWidget(
                    key: ValueKey(_articuloWidgetKey),
                    articulo: _articuloKilo!,
                    onCantidadPrecioChanged: (double cantidad, double precio) {
                      setState(() {
                        _cantidadArticulo = cantidad;
                        _precioArticulo = precio;
                      });
                    },
                  ),

                const SizedBox(height: 8),

                // Widget del total de venta
                TotalVentaWidget(
                  total: _totalVenta,
                  icon: Icons.shopping_cart,
                  compacto: true,
                ),

                const SizedBox(height: 8),

                // Widget de tipos de pago
                TiposPagoWidget(
                  tiposPago: _tiposPago,
                  montosPago: _montosPago,
                  onMontoChanged: _onMontoChanged,
                  enabled: !_isProcessing && _clienteSeleccionado != null,
                  compacto: true,
                ),

                const SizedBox(height: 8),

                // Widget de validación de cobro
                ValidacionCobroWidget(
                  totalVenta: _totalVenta,
                  totalPagos: _totalPagos,
                  cambio: _cambio,
                  montoEfectivo: _montoEfectivo,
                  compacto: true,
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildFloatingButton() {
    if (_clienteSeleccionado == null) return null;

    return FloatingActionButton.extended(
      onPressed: _isProcessing || !_puedeConfirmar ? null : _finalizarVenta,
      backgroundColor: _puedeConfirmar ? Colors.green : Colors.grey,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.check_circle),
      label: Text(_isProcessing ? 'Procesando...' : 'Finalizar Venta'),
    );
  }

  void _mostrarMenuOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text('Ir a Inicio'),
              onTap: () {
                Navigator.pop(context);
                _irAInicio(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _cerrarSesion(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _irAInicio(BuildContext context) async {
    try {
      final authService = await AuthService.getInstance();
      final usuario = authService.usuarioActual ?? '';

      if (!mounted) return;

      if (usuario.toLowerCase() == 'cajero') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya estás en la pantalla de inicio'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MenuPrincipalScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
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
      try {
        final authService = await AuthService.getInstance();
        await authService.logout();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
