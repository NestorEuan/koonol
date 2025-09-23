import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/articulo.dart';

class ArticuloGridItemWidget extends StatefulWidget {
  final Articulo articulo;
  final Function(Articulo articulo, int cantidad, double precio) onAddToCart;
  final int cantidadEnCarrito;

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
  late TextEditingController _precioController;
  late TextEditingController _cantidadController;
  int _cantidad = 1;
  late double _precio;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _precio = widget.articulo.precio;
    _precioController = TextEditingController(text: _precio.toStringAsFixed(2));
    _cantidadController = TextEditingController(text: _cantidad.toString());
  }

  @override
  void dispose() {
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _incrementarCantidad() {
    if (_cantidad < widget.articulo.existencia) {
      setState(() {
        _cantidad++;
        _cantidadController.text = _cantidad.toString();
      });
    } else {
      _mostrarMensaje('No hay suficiente existencia');
    }
  }

  void _decrementarCantidad() {
    if (_cantidad > 1) {
      setState(() {
        _cantidad--;
        _cantidadController.text = _cantidad.toString();
      });
    }
  }

  void _onCantidadChanged(String value) {
    final int? nuevaCantidad = int.tryParse(value);
    if (nuevaCantidad != null && nuevaCantidad > 0) {
      if (nuevaCantidad <= widget.articulo.existencia) {
        setState(() {
          _cantidad = nuevaCantidad;
        });
      } else {
        _cantidadController.text = widget.articulo.existencia.toString();
        setState(() {
          _cantidad = widget.articulo.existencia;
        });
        _mostrarMensaje('Cantidad ajustada a existencia disponible');
      }
    }
  }

  void _onPrecioChanged(String value) {
    final double? nuevoPrecio = double.tryParse(value);
    if (nuevoPrecio != null && nuevoPrecio > 0) {
      setState(() {
        _precio = nuevoPrecio;
      });
    }
  }

  void _agregarAlCarrito() {
    if (_cantidad > 0 && _precio > 0) {
      widget.onAddToCart(widget.articulo, _cantidad, _precio);
      setState(() {
        _showControls = false;
      });
    }
  }

  void _agregarRapido() {
    widget.onAddToCart(widget.articulo, 1, widget.articulo.precio);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool sinExistencia = widget.articulo.existencia == 0;
    final bool existenciaBaja =
        widget.articulo.existencia <= 5 && widget.articulo.existencia > 0;

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del artículo
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  // Badge de cantidad en carrito
                  if (widget.cantidadEnCarrito > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.cantidadEnCarrito}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Badge de sin existencia
                  if (sinExistencia)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Sin Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Información del artículo
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  Text(
                    widget.articulo.descripcion,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Código
                  Text(
                    'Código: ${widget.articulo.codigo}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),

                  // Precio
                  Text(
                    '\$${widget.articulo.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Existencia
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 14,
                        color:
                            sinExistencia
                                ? Colors.red
                                : existenciaBaja
                                ? Colors.orange
                                : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.articulo.existencia}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              sinExistencia
                                  ? Colors.red
                                  : existenciaBaja
                                  ? Colors.orange
                                  : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Controles o botones
                  if (!_showControls) ...[
                    // Botones de acción rápida
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: sinExistencia ? null : _agregarRapido,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text(
                              'Agregar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed:
                              sinExistencia
                                  ? null
                                  : () {
                                    setState(() {
                                      _showControls = true;
                                    });
                                  },
                          icon: const Icon(Icons.settings),
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Controles detallados
                    Column(
                      children: [
                        // Precio
                        TextFormField(
                          controller: _precioController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Precio',
                            prefixText: '\$ ',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          style: const TextStyle(fontSize: 12),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: _onPrecioChanged,
                        ),
                        const SizedBox(height: 8),

                        // Cantidad
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrementarCantidad,
                              icon: const Icon(Icons.remove),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _cantidadController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: _onCantidadChanged,
                              ),
                            ),
                            IconButton(
                              onPressed: _incrementarCantidad,
                              icon: const Icon(Icons.add),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _agregarAlCarrito,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 28),
                                ),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showControls = false;
                                  // Resetear valores
                                  _precio = widget.articulo.precio;
                                  _cantidad = 1;
                                  _precioController.text = _precio
                                      .toStringAsFixed(2);
                                  _cantidadController.text =
                                      _cantidad.toString();
                                });
                              },
                              icon: const Icon(Icons.close),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
