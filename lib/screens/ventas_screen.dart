import 'package:flutter/material.dart';
import 'package:koonol/screens/articulos_screen.dart';
import 'package:koonol/screens/carrito_screen.dart';
import 'package:koonol/screens/finalizar_venta.dart';
import '../models/cliente.dart';
import '../models/carrito_item.dart';
import '../widgets/cliente_search_widget.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  Cliente? _clienteSeleccionado;
  List<CarritoItem> _carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarArticulos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _cargarArticulos() {
    setState(() {});

    // Simulamos un pequeño delay para mostrar el loading
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // _articulos = DataProvider.getArticulos();
      });
    });
  }

  void _onClienteSelected(Cliente? cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
    });
  }

  double _getTotalCarrito() {
    return _carrito.fold(0.0, (total, item) => total + item.subtotal);
  }

  void _verCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CarritoScreen(
              carrito: _carrito,
              cliente: _clienteSeleccionado,
              onCarritoChanged: (carritoActualizado) {
                setState(() {
                  _carrito = carritoActualizado;
                });
              },
            ),
      ),
    );
  }

  void _finalizarVenta() {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FinalizarVentaScreen(
              carrito: _carrito,
              cliente: _clienteSeleccionado!,
              onVentaFinalizada: () {
                setState(() {
                  _carrito.clear();
                  _clienteSeleccionado = null;
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Ventas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Botón del carrito
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _verCarrito,
              ),
              if (_carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_carrito.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Widget de búsqueda de cliente
          ClienteSearchWidget(
            onClienteSelected: _onClienteSelected,
            clienteSeleccionado: _clienteSeleccionado,
          ),
          Expanded(
            child: ArticulosWidget(
              carrito: _carrito,
              onCarritoChanged: (carritoActualizado) {
                setState(() {
                  _carrito = carritoActualizado;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Información del total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: \$${_getTotalCarrito().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Artículos: ${_carrito.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Botón ver carrito
            OutlinedButton.icon(
              onPressed: _carrito.isEmpty ? null : _verCarrito,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Ver Carrito'),
            ),
            const SizedBox(width: 8),
            // Botón finalizar venta
            ElevatedButton.icon(
              onPressed:
                  (_carrito.isEmpty || _clienteSeleccionado == null)
                      ? null
                      : _finalizarVenta,
              icon: const Icon(Icons.payment),
              label: const Text('Finalizar Venta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
