import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/carrito_item.dart';
import '../models/cliente.dart';

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

  void _incrementarCantidad(int index) {
    final item = _carritoLocal[index];
    if (item.cantidad < item.articulo.existencia) {
      setState(() {
        _carritoLocal[index] = item.copyWith(cantidad: item.cantidad + 1);
      });
      _actualizarCarrito();
    } else {
      _mostrarMensaje('No hay suficiente existencia disponible');
    }
  }

  void _decrementarCantidad(int index) {
    final item = _carritoLocal[index];
    if (item.cantidad > 1) {
      setState(() {
        _carritoLocal[index] = item.copyWith(cantidad: item.cantidad - 1);
      });
      _actualizarCarrito();
    } else {
      _mostrarMensaje('La cantidad mínima es 1');
    }
  }

  void _cambiarCantidad(int index, String valor) {
    final int? nuevaCantidad = int.tryParse(valor);
    if (nuevaCantidad != null && nuevaCantidad > 0) {
      final item = _carritoLocal[index];
      if (nuevaCantidad <= item.articulo.existencia) {
        setState(() {
          _carritoLocal[index] = item.copyWith(cantidad: nuevaCantidad);
        });
        _actualizarCarrito();
      } else {
        _mostrarMensaje('Cantidad excede la existencia disponible');
        // Restaurar el valor anterior
        setState(() {});
      }
    }
  }

  void _cambiarPrecio(int index, String valor) {
    final double? nuevoPrecio = double.tryParse(valor);
    if (nuevoPrecio != null && nuevoPrecio > 0) {
      final item = _carritoLocal[index];
      setState(() {
        _carritoLocal[index] = item.copyWith(precioVenta: nuevoPrecio);
      });
      _actualizarCarrito();
    }
  }

  void _eliminarArticulo(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro de eliminar "${_carritoLocal[index].articulo.descripcion}" del carrito?',
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
                  _carritoLocal.removeAt(index);
                });
                _actualizarCarrito();
                _mostrarMensaje('Artículo eliminado del carrito');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
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

  int _calcularTotalArticulos() {
    return _carritoLocal.fold(0, (total, item) => total + item.cantidad);
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
                  if (widget.cliente != null) _buildInfoCliente(),

                  // Lista de artículos
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _carritoLocal.length,
                      itemBuilder: (context, index) {
                        return _buildCarritoItem(index);
                      },
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

  Widget _buildInfoCliente() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${widget.cliente!.nombre}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.cliente!.telefono.isNotEmpty)
                  Text(
                    'Tel: ${widget.cliente!.telefono}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.cliente!.tipo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoItem(int index) {
    final item = _carritoLocal[index];
    final subtotal = item.subtotal;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),

                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.articulo.descripcion,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${item.articulo.codigo}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disponible: ${item.articulo.existencia}',
                        style: TextStyle(
                          color:
                              item.articulo.existencia <= 5
                                  ? Colors.orange
                                  : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón eliminar
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarArticulo(index),
                  tooltip: 'Eliminar artículo',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Controles de precio, cantidad y subtotal
            Row(
              children: [
                // Precio unitario
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precio',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: item.precioVenta.toStringAsFixed(2),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onFieldSubmitted:
                            (value) => _cambiarPrecio(index, value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Cantidad
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _decrementarCantidad(index),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.cantidad.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onFieldSubmitted:
                                  (value) => _cambiarCantidad(index, value),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _incrementarCantidad(index),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Subtotal
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCarrito() {
    final total = _calcularTotal();
    final totalArticulos = _calcularTotalArticulos();

    return Container(
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
      child: Column(
        children: [
          // Resumen de cantidades
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total de artículos:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              Text(
                '$totalArticulos',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Divider(),

          // Total general
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a pagar:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Continuar Comprando'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onFinalizarVenta,
                  icon: const Icon(Icons.payment),
                  label: const Text('Finalizar Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
