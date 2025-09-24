import 'dart:math';
import 'package:flutter/material.dart';
import '../models/articulo.dart';
import '../models/carrito_item.dart';
import '../data/data_provider.dart';
import '../widgets/articulo_item_widget.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarArticulos() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _articulos = DataProvider.getArticulos();
        _isLoading = false;
      });
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

    widget.onCarritoChanged(_carritoLocal);

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

  // Método para determinar si usar grid o lista
  bool _shouldUseGrid(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final Orientation orientation = MediaQuery.of(context).orientation;

    // Convertir tamaño de pantalla a pulgadas aproximadas
    final double diagonal = _getScreenDiagonalInches(screenSize);

    // Usar grid si:
    // 1. La pantalla es de 6.7 pulgadas o más
    // 2. O si está en orientación horizontal (panorámica)
    return diagonal >= 6.7 || orientation == Orientation.landscape;
  }

  // Método para calcular las pulgadas diagonales de la pantalla
  double _getScreenDiagonalInches(Size screenSize) {
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final double width = screenSize.width * pixelRatio;
    final double height = screenSize.height * pixelRatio;

    // Asumir densidad típica de píxeles (esto es una aproximación)
    const double typicalDPI = 400.0;

    final double diagonalSquared =
        (width * width + height * height) / (typicalDPI * typicalDPI);
    return sqrt(diagonalSquared);
  }

  // Método para determinar el número de columnas del grid
  int _getGridColumns(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final Orientation orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      // En modo horizontal, más columnas
      if (screenSize.width > 1000) {
        return 4; // Tablets grandes
      } else if (screenSize.width > 800) {
        return 3; // Tablets medianas
      } else {
        return 2; // Teléfonos en horizontal
      }
    } else {
      // En modo vertical
      if (screenSize.width > 600) {
        return 3; // Tablets
      } else {
        return 2; // Teléfonos grandes
      }
    }
  }

  // Widget para mostrar la lista de artículos
  Widget _buildArticulosList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_articulos.isEmpty) {
      return const Center(
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
      );
    }

    if (_shouldUseGrid(context)) {
      // Usar GridView para pantallas grandes o modo horizontal
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridColumns(context),
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio:
              0.8, // Ajusta según el diseño del ArticuloGridItemWidget
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
      );
    } else {
      // Usar ListView para pantallas pequeñas
      return ListView.builder(
        itemCount: _articulos.length,
        itemBuilder: (context, index) {
          final articulo = _articulos[index];
          return ArticuloItemWidget(
            articulo: articulo,
            onAddToCart: _agregarAlCarrito,
            cantidadEnCarrito: _getCantidadEnCarrito(articulo.id),
          );
        },
      );
    }
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
              suffixIcon: _searchController.text.isNotEmpty
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
        // Lista/Grid de artículos - Ahora responsivo
        Expanded(child: _buildArticulosList()),
      ],
    );
  }
}
