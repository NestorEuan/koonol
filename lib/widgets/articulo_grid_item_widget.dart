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
      _mostrarMensaje('Artículo agregado al carrito');
    }
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
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del artículo (más pequeña para grid)
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
                // Información del artículo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.articulo.descripcion,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.cantidadEnCarrito > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'En carrito: ${widget.cantidadEnCarrito}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${widget.articulo.codigo}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Existencia: ${widget.articulo.existencia}',
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
                          if (sinExistencia) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 14,
                            ),
                          ] else if (existenciaBaja) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Controles de precio y cantidad (adaptados para grid)
            Column(
              children: [
                // Primera fila: Precio y Cantidad
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
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextFormField(
                            controller: _precioController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              prefixText: '\$ ',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            onChanged: _onPrecioChanged,
                            enabled: !sinExistencia,
                          ),
                        ],
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
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: InkWell(
                                  onTap:
                                      sinExistencia
                                          ? null
                                          : _decrementarCantidad,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.remove,
                                      size: 14,
                                      color:
                                          sinExistencia
                                              ? Colors.grey
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _cantidadController,
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
                                  onChanged: _onCantidadChanged,
                                  enabled: !sinExistencia,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: InkWell(
                                  onTap:
                                      sinExistencia
                                          ? null
                                          : _incrementarCantidad,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color:
                                          sinExistencia
                                              ? Colors.grey
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Segunda fila: Botón agregar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: sinExistencia ? null : _agregarAlCarrito,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Agregar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          sinExistencia ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (sinExistencia)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
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
              ),
          ],
        ),
      ),
    );
  }
}
