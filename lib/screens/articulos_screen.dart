import 'package:flutter/material.dart';
import '../models/articulo.dart';
import '../models/carrito_item.dart';
import '../data/data_provider.dart';
import '../widgets/articulo_grid_item_widget.dart';

class ArticulosWidget extends StatefulWidget {
  final List<CarritoItem> carrito;
  final Function(List<CarritoItem>) onCarritoChanged;

  const ArticulosWidget({
    super.key,
    required this.carrito,
    required this.onCarritoChanged,
  });

  @override
  State<ArticulosWidget> createState() => _ArticulosWidgetState();
}

class _ArticulosWidgetState extends State<ArticulosWidget> {
  List<Articulo> _articulos = [];
  late List<CarritoItem> _carritoLocal;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carritoLocal = List.from(widget.carrito);
    _cargarArticulos();
  }

  @override
  void didUpdateWidget(ArticulosWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el carrito local cuando el widget padre lo actualice
    if (widget.carrito != oldWidget.carrito) {
      setState(() {
        _carritoLocal = List.from(widget.carrito);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarArticulos() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _articulos = DataProvider.getArticulos();
          _isLoading = false;
        });
      }
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
      final int index = _carritoLocal.indexWhere(
        (item) => item.articulo.id == articulo.id,
      );

      if (index >= 0) {
        _carritoLocal[index] = CarritoItem(
          articulo: articulo,
          cantidad: _carritoLocal[index].cantidad + cantidad,
          precioVenta: precio,
        );
      } else {
        _carritoLocal.add(
          CarritoItem(
            articulo: articulo,
            cantidad: cantidad,
            precioVenta: precio,
          ),
        );
      }
    });

    // Notificar al widget padre
    widget.onCarritoChanged(_carritoLocal);

    // Mostrar snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${articulo.descripcion} agregado al carrito'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  int _getCantidadEnCarrito(int articuloId) {
    final item = _carritoLocal.where((item) => item.articulo.id == articuloId);
    return item.isEmpty ? 0 : item.first.cantidad;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Búsqueda de artículos
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar artículo por código o descripción',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
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

        // Grid de artículos
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
                  : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _articulos.length,
                    itemBuilder: (context, index) {
                      final articulo = _articulos[index];
                      return ArticuloGridItemWidget(
                        articulo: articulo,
                        onAddToCart: _agregarAlCarrito,
                        cantidadEnCarrito: _getCantidadEnCarrito(articulo.id),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
