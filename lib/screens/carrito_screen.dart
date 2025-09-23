import 'package:flutter/material.dart';
import '../models/carrito_item.dart';
import '../models/cliente.dart';
import '../widgets/cliente_vista_reducida_widget.dart';
import '../widgets/articulo_listado_reducido_widget.dart';

class CarritoScreen extends StatefulWidget {
  final List<CarritoItem> carrito;
  final Cliente? cliente;
  final Function(List<CarritoItem>) onCarritoChanged;
  final VoidCallback? onFinalizarVenta;

  const CarritoScreen({
    super.key,
    required this.carrito,
    this.cliente,
    required this.onCarritoChanged,
    this.onFinalizarVenta,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<CarritoItem> _carritoLocal;

  @override
  void initState() {
    super.initState();
    // Crear una copia local del carrito para modificaciones
    _carritoLocal =
        widget.carrito
            .map(
              (item) => CarritoItem(
                articulo: item.articulo,
                cantidad: item.cantidad,
                precioVenta: item.precioVenta,
              ),
            )
            .toList();
  }

  void _limpiarCarrito() {
    if (_carritoLocal.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar carrito'),
          content: const Text(
            '¿Está seguro de eliminar todos los artículos del carrito?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _carritoLocal.clear();
                });
                _actualizarCarrito();
                _mostrarMensaje('Carrito limpiado');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
  }

  void _actualizarCarrito() {
    widget.onCarritoChanged(_carritoLocal);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  double _calcularTotal() {
    return _carritoLocal.fold(0.0, (total, item) => total + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_carritoLocal.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _limpiarCarrito,
              tooltip: 'Limpiar carrito',
            ),
        ],
      ),
      body:
          _carritoLocal.isEmpty
              ? _buildCarritoVacio()
              : Column(
                children: [
                  // Información del cliente
                  if (widget.cliente != null)
                    ClienteVistaReducidaWidget(cliente: widget.cliente!),

                  // Lista de artículos
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: ArticuloListadoReducidoWidget(
                        items: _carritoLocal,
                        editable: true,
                        onItemsChanged: (items) {
                          setState(() {
                            _carritoLocal = items;
                          });
                          _actualizarCarrito();
                        },
                      ),
                    ),
                  ),

                  // Resumen del carrito
                  _buildResumenCarrito(),
                ],
              ),
    );
  }

  Widget _buildCarritoVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'El carrito está vacío',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agregue productos para comenzar',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCarrito() {
    final total = _calcularTotal();

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          // Total general
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(
                    'Continuar Comprando',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onFinalizarVenta,
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text(
                    'Finalizar Venta',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
