import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/articulo.dart';
import '../models/carrito_item.dart';
import '../data/data_provider.dart';
import '../widgets/cliente_search_widget.dart';
import '../widgets/articulo_item_widget.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  Cliente? _clienteSeleccionado;
  List<Articulo> _articulos = [];
  final List<CarritoItem> _carrito = [];
  final TextEditingController _searchArticuloController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarArticulos();
  }

  @override
  void dispose() {
    _searchArticuloController.dispose();
    super.dispose();
  }

  void _cargarArticulos() {
    setState(() {
      _isLoading = true;
    });

    // Simulamos un pequeño delay para mostrar el loading
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _articulos = DataProvider.getArticulos();
        _isLoading = false;
      });
    });
  }

  void _onClienteSelected(Cliente? cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
    });
  }

  void _onSearchArticulo(String query) {
    setState(() {
      if (query.isEmpty) {
        _articulos = DataProvider.getArticulos();
      } else {
        _articulos = DataProvider.buscarArticulos(query);
      }
    });
  }

  void _agregarAlCarrito(Articulo articulo, int cantidad, double precio) {
    setState(() {
      // Buscar si el artículo ya está en el carrito
      final int index = _carrito.indexWhere(
        (item) => item.articulo.id == articulo.id,
      );

      if (index >= 0) {
        // Si ya existe, actualizar cantidad y precio
        _carrito[index] = CarritoItem(
          articulo: articulo,
          cantidad: _carrito[index].cantidad + cantidad,
          precioVenta: precio,
        );
      } else {
        // Si no existe, agregar nuevo item
        _carrito.add(
          CarritoItem(
            articulo: articulo,
            cantidad: cantidad,
            precioVenta: precio,
          ),
        );
      }
    });
  }

  int _getCantidadEnCarrito(int articuloId) {
    final item = _carrito.where((item) => item.articulo.id == articuloId);
    return item.isEmpty ? 0 : item.first.cantidad;
  }

  double _getTotalCarrito() {
    return _carrito.fold(0.0, (total, item) => total + item.subtotal);
  }

  void _verCarrito() {
    // TODO: Navegar a la pantalla del carrito
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Carrito de Compras'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Artículos: ${_carrito.length}'),
                Text('Total: \$${_getTotalCarrito().toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
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

    // TODO: Navegar a la pantalla de finalizar venta
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finalizar Venta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Cliente: ${_clienteSeleccionado!.nombre}'),
                Text('Artículos: ${_carrito.length}'),
                Text('Total: \$${_getTotalCarrito().toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Procesar venta
                },
                child: const Text('Procesar'),
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

          // Búsqueda de artículos
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchArticuloController,
              decoration: InputDecoration(
                hintText: 'Buscar artículo por código o descripción',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchArticuloController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchArticuloController.clear();
                            _onSearchArticulo('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearchArticulo,
            ),
          ),

          // Lista de artículos
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _articulos.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No se encontraron artículos',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _articulos.length,
                      itemBuilder: (context, index) {
                        final articulo = _articulos[index];
                        return ArticuloItemWidget(
                          articulo: articulo,
                          onAddToCart: _agregarAlCarrito,
                          cantidadEnCarrito: _getCantidadEnCarrito(articulo.id),
                        );
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
