import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/articulo_mdl.dart';
import '../controllers/articulo_controller.dart';
import '../services/ui_service.dart';

class ArticuloKiloWidget extends StatefulWidget {
  final ArticuloMdl articulo;
  final Function(ArticuloMdl articulo, double cantidad, double precio)
  onAddToCart;
  final double cantidadEnCarrito;

  const ArticuloKiloWidget({
    super.key,
    required this.articulo,
    required this.onAddToCart,
    this.cantidadEnCarrito = 0,
  });

  @override
  State<ArticuloKiloWidget> createState() => _ArticuloKiloWidgetState();
}

class _ArticuloKiloWidgetState extends State<ArticuloKiloWidget> {
  late ArticuloController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArticuloController(
      articulo: widget.articulo,
      onStateChanged: () => setState(() {}),
      onShowMessage: (message) => UIService.showWarning(context, message),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _agregarAlCarrito() {
    if (_controller.canAddToCart()) {
      final data = _controller.getCartData();
      widget.onAddToCart(data['articulo'], data['cantidad'], data['precio']);
      UIService.showSuccess(context, 'Artículo agregado al carrito');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              widget.articulo.cDescripcion,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Código: ${widget.articulo.cCodigo}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

            if (widget.cantidadEnCarrito > 0) ...[
              const SizedBox(height: 8),
              UIService.createBadge(
                text: 'En carrito: ${widget.cantidadEnCarrito}',
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],

            const SizedBox(height: 16),

            // Campos de Precio y Cantidad
            Row(
              children: [
                // Precio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _controller.precioController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: _controller.onPrecioChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Cantidad
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _controller.cantidadController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: _controller.onCantidadChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botón Agregar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _controller.canAddToCart()
                    ? _agregarAlCarrito
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
