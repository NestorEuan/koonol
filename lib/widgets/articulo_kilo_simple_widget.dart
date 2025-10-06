import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/articulo_mdl.dart';
import '../controllers/articulo_controller.dart';
import '../services/ui_service.dart';

/// Widget simplificado del artículo kilo sin botón de agregar
/// Para usar en pantallas donde no se agrega a un carrito
class ArticuloKiloSimpleWidget extends StatefulWidget {
  final ArticuloMdl articulo;
  final Function(double cantidad, double precio) onCantidadPrecioChanged;

  const ArticuloKiloSimpleWidget({
    super.key,
    required this.articulo,
    required this.onCantidadPrecioChanged,
  });

  @override
  State<ArticuloKiloSimpleWidget> createState() =>
      _ArticuloKiloSimpleWidgetState();
}

class _ArticuloKiloSimpleWidgetState extends State<ArticuloKiloSimpleWidget> {
  late ArticuloController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ArticuloController(
      articulo: widget.articulo,
      onStateChanged: () {
        setState(() {});
        // Notificar cambios al padre
        widget.onCantidadPrecioChanged(
          _controller.cantidad,
          _controller.precio,
        );
      },
      onShowMessage: (message) => UIService.showWarning(context, message),
    );

    // Inicializar cantidad en 1 después de que el controller esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.cantidadController.text = '1';
      // Forzar actualización de la cantidad interna
      _controller.onCantidadChanged('1');
      // Notificar valores iniciales al padre
      widget.onCantidadPrecioChanged(_controller.cantidad, _controller.precio);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.articulo.cDescripcion,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Código: ${widget.articulo.cCodigo}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

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
                        onChanged: (value) {
                          _controller.onPrecioChanged(value);
                          // Asegurar notificación inmediata
                          final precio = double.tryParse(value) ?? 0.0;
                          if (precio > 0) {
                            widget.onCantidadPrecioChanged(
                              _controller.cantidad,
                              precio,
                            );
                          }
                        },
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
                        onChanged: (value) {
                          _controller.onCantidadChanged(value);
                          // Asegurar notificación inmediata
                          final cantidad = double.tryParse(value) ?? 0.0;
                          if (cantidad > 0) {
                            widget.onCantidadPrecioChanged(
                              cantidad,
                              _controller.precio,
                            );
                          }
                        },
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
}
