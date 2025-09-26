import 'dart:math';
import 'package:flutter/material.dart';
import 'package:koonol/data/config.dart';
import '../models/articulo_mdl.dart';
import '../models/carrito_item.dart';
import '../data/articulo.dart';
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
  List<ArticuloMdl> _articulos = [];
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

  void _cargarArticulos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final articuloRepo = await Articulo.getInstance();
      final articulosData = await articuloRepo.getArticulos();

      setState(() {
        // Convertir Map a ArticuloMdl usando el constructor correcto
        _articulos = articulosData
            .map(
              (data) => ArticuloMdl(
                idArticulo: data['id'],
                idClasificacion: 1, // Valor por defecto, ajusta según tu lógica
                cCodigo: data['codigo'],
                cDescripcion: data['descripcion'],
                nPrecio: data['precio'].toDouble(),
                nCosto: 0.0,
                existencia: 0.0, // Valor por defecto si no está en el query
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Mostrar error si es necesario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar artículos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchArticulo(String query) async {
    if (query.isEmpty) {
      _cargarArticulos();
      return;
    }

    try {
      final articuloRepo = await Articulo.getInstance();
      final articulosData = await articuloRepo.buscarArticulos(query);

      setState(() {
        // Convertir Map a ArticuloMdl usando el constructor correcto
        _articulos = articulosData
            .map(
              (data) => ArticuloMdl(
                idArticulo: data['id'],
                idClasificacion: 1, // Valor por defecto, ajusta según tu lógica
                cCodigo: data['codigo'],
                cDescripcion: data['descripcion'],
                nPrecio: data['precio'].toDouble(),
                nCosto: 0.0,
                existencia: AppConfig.validarExistencia
                    ? data['existencia'].toDouble()
                    : 999.0,
              ),
            )
            .toList();
      });
    } catch (e) {
      // Manejar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la búsqueda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _agregarAlCarrito(ArticuloMdl articulo, double cantidad, double precio) {
    setState(() {
      final int index = _carritoLocal.indexWhere(
        (item) => item.articulo.idArticulo == articulo.idArticulo,
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
        content: Text('${articulo.cDescripcion} agregado al carrito'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _getCantidadEnCarrito(int? articuloId) {
    if (articuloId == null) return 0;
    final item = _carritoLocal.where(
      (item) => item.articulo.idArticulo == articuloId,
    );
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
            cantidadEnCarrito: _getCantidadEnCarrito(articulo.idArticulo),
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
            cantidadEnCarrito: _getCantidadEnCarrito(articulo.idArticulo),
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

        // Lista/Grid de artículos - Ahora responsivo
        Expanded(child: _buildArticulosList()),
      ],
    );
  }
}
