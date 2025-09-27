import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koonol/controllers/articulo_controller.dart';
import 'package:koonol/services/ui_service.dart';
import '../models/articulo_mdl.dart';

class ArticuloGridItemWidget extends StatefulWidget {
  final ArticuloMdl articulo;
  final Function(ArticuloMdl articulo, double cantidad, double precio)
  onAddToCart;
  final double cantidadEnCarrito;

  const ArticuloGridItemWidget({
    super.key,
    required this.articulo,
    required this.onAddToCart,
    this.cantidadEnCarrito = 0,
  });

  @override
  State<ArticuloGridItemWidget> createState() => _ArticuloGridItemWidgetState();
}

class _ArticuloGridItemWidgetState extends State<ArticuloGridItemWidget> {
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
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Información del artículo
            _buildArticleInfo(),
            const SizedBox(height: 12),
            // Controles
            _buildControls(),
            // Mensaje de sin existencia
            if (_controller.hasNoStock()) _buildNoStockMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Icon(Icons.image, size: 30, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        // Información
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.articulo.cDescripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.cantidadEnCarrito > 0)
                    UIService.createBadge(
                      text: 'En carrito: ${widget.cantidadEnCarrito}',
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Código: ${widget.articulo.cCodigo}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Existencia: ${widget.articulo.existencia}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _controller.getStockColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_controller.getStockWarningIcon() != null) ...[
                    const SizedBox(width: 4),
                    _controller.getStockWarningIcon()!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            // Precio
            Expanded(
              child: UIService.createStyledTextField(
                controller: _controller.precioController,
                label: 'Precio',
                prefixText: '\$ ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: _controller.onPrecioChanged,
                enabled: !_controller.hasNoStock(),
                fontSize: 12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Cantidad
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cantidad',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      UIService.createQuantityButton(
                        icon: Icons.remove,
                        onTap: _controller.decrementarCantidad,
                        enabled: !_controller.hasNoStock(),
                        size: 14,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _controller.cantidadController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 6,
                            ),
                          ),
                          style: const TextStyle(fontSize: 12),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: _controller.onCantidadChanged,
                          enabled: !_controller.hasNoStock(),
                        ),
                      ),
                      UIService.createQuantityButton(
                        icon: Icons.add,
                        onTap: _controller.incrementarCantidad,
                        enabled: !_controller.hasNoStock(),
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Botón agregar
        SizedBox(
          width: double.infinity,
          child: UIService.createStyledButton(
            onPressed: _controller.canAddToCart() ? _agregarAlCarrito : null,
            text: 'Agregar',
            icon: Icons.add_shopping_cart,
            backgroundColor: _controller.hasNoStock()
                ? Colors.grey
                : Colors.blue,
            fontSize: 12,
            iconSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildNoStockMessage() {
    return UIService.createInfoContainer(
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 14),
          SizedBox(width: 6),
          Text(
            'Producto sin existencia',
            style: TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
