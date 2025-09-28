import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/articulo_mdl.dart';
import '../controllers/articulo_controller.dart';
import '../services/ui_service.dart';

class ArticuloItemWidget extends StatefulWidget {
  final ArticuloMdl articulo;
  final Function(ArticuloMdl articulo, double cantidad, double precio)
  onAddToCart;
  final double cantidadEnCarrito;

  const ArticuloItemWidget({
    super.key,
    required this.articulo,
    required this.onAddToCart,
    this.cantidadEnCarrito = 0,
  });

  @override
  State<ArticuloItemWidget> createState() => _ArticuloItemWidgetState();
}

class _ArticuloItemWidgetState extends State<ArticuloItemWidget> {
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
          children: [
            _buildArticleInfo(),
            const SizedBox(height: 16),
            _buildControls(),
            if (_controller.hasNoStock()) _buildNoStockMessage(),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de información del artículo
  Widget _buildArticleInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del artículo (placeholder)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Icon(Icons.image, size: 40, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        // Información del artículo
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.cantidadEnCarrito > 0)
                    UIService.createBadge(
                      text: 'En carrito: ${widget.cantidadEnCarrito}',
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Código: ${widget.articulo.cCodigo}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Existencia: ${widget.articulo.existencia}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _controller.getStockColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_controller.getStockWarningIcon() != null) ...[
                    const SizedBox(width: 8),
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

  /// Construye la sección de controles de precio y cantidad
  Widget _buildControls() {
    return Row(
      children: [
        // Precio
        Expanded(
          flex: 2,
          child: UIService.createStyledTextField(
            controller: _controller.precioController,
            label: 'Precio',
            prefixText: '\$ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: _controller.onPrecioChanged,
            enabled: !_controller.hasNoStock(),
            fontSize: 12,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Cantidad
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cantidad',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  UIService.createQuantityButton(
                    icon: Icons.remove,
                    onTap: _controller.decrementarCantidad,
                    enabled: !_controller.hasNoStock(),
                    size: 16,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _controller.cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: _controller.onCantidadChanged,
                      enabled: !_controller.hasNoStock(),
                    ),
                  ),
                  UIService.createQuantityButton(
                    icon: Icons.add,
                    onTap: _controller.incrementarCantidad,
                    enabled: !_controller.hasNoStock(),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Botón agregar
        UIService.createStyledButton(
          onPressed: _controller.canAddToCart() ? _agregarAlCarrito : null,
          text: 'Agregar',
          icon: Icons.add_shopping_cart,
          backgroundColor: _controller.hasNoStock() ? Colors.grey : Colors.blue,
          fontSize: 14,
          iconSize: 20,
        ),
      ],
    );
  }

  /// Construye el mensaje de sin existencia
  Widget _buildNoStockMessage() {
    return UIService.createInfoContainer(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Text(
            'Producto sin existencia',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
