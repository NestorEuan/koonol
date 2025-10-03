import 'package:flutter/material.dart';
import '../models/carrito_item.dart';

class ArticuloListadoReducidoWidget extends StatefulWidget {
  final List<CarritoItem> items;
  final bool editable;
  final Function(List<CarritoItem>)? onItemsChanged;

  const ArticuloListadoReducidoWidget({
    super.key,
    required this.items,
    this.editable = true,
    this.onItemsChanged,
  });

  @override
  State<ArticuloListadoReducidoWidget> createState() =>
      _ArticuloListadoReducidoWidgetState();
}

class _ArticuloListadoReducidoWidgetState
    extends State<ArticuloListadoReducidoWidget> {
  late List<CarritoItem> _itemsLocal;

  @override
  void initState() {
    super.initState();
    _itemsLocal = widget.items
        .map(
          (item) => CarritoItem(
            articulo: item.articulo,
            cantidad: item.cantidad,
            precioVenta: item.precioVenta,
          ),
        )
        .toList();
  }

  void _actualizarItems() {
    if (widget.onItemsChanged != null) {
      widget.onItemsChanged!(_itemsLocal);
    }
  }

  void _cambiarCantidad(int index, double nuevaCantidad) {
    if (nuevaCantidad > 0 &&
        nuevaCantidad <= _itemsLocal[index].articulo.existencia) {
      setState(() {
        _itemsLocal[index] = _itemsLocal[index].copyWith(
          cantidad: nuevaCantidad,
        );
      });
      _actualizarItems();
    }
  }

  void _cambiarPrecio(int index, double nuevoPrecio) {
    if (nuevoPrecio > 0) {
      setState(() {
        _itemsLocal[index] = _itemsLocal[index].copyWith(
          precioVenta: nuevoPrecio,
        );
      });
      _actualizarItems();
    }
  }

  void _eliminarItem(int index) {
    setState(() {
      _itemsLocal.removeAt(index);
    });
    _actualizarItems();
  }

  double _calcularTotal() {
    return _itemsLocal.fold(0.0, (total, item) => total + item.subtotal);
  }

  double _calcularTotalArticulos() {
    return _itemsLocal.fold(0, (total, item) => total + item.cantidad);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.green[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Artículos en la Venta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de artículos
          if (widget.editable)
            ..._buildItemsEditables()
          else
            ..._buildItemsSoloVista(),

          const Divider(height: 24),

          // Total de artículos y total general en la misma línea
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total de artículos: ${_calcularTotalArticulos()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!widget.editable)
                Text(
                  'Total: \$${_calcularTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemsEditables() {
    return _itemsLocal.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final subtotalValue = item.subtotal;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Información del artículo
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.articulo.cDescripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Código: ${item.articulo.cCodigo}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Cantidad (ahora primero)
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.cantidad.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final cantidad = double.tryParse(value);
                  if (cantidad != null) {
                    _cambiarCantidad(index, cantidad);
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            // Precio (ahora segundo)
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: item.precioVenta.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final precio = double.tryParse(value);
                  if (precio != null) {
                    _cambiarPrecio(index, precio);
                  }
                },
              ),
            ),

            const SizedBox(width: 8),

            // Subtotal
            Expanded(
              flex: 2,
              child: Text(
                '\$${subtotalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // Botón eliminar
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () => _eliminarItem(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildItemsSoloVista() {
    return _itemsLocal.map((item) {
      final subtotalValue = item.subtotal;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Información del artículo
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.articulo.cDescripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Código: ${item.articulo.cCodigo}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Cantidad (ahora primero)
            Expanded(
              flex: 1,
              child: Text(
                '${item.cantidad}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Precio unitario (ahora segundo)
            Expanded(
              flex: 2,
              child: Text(
                '\$${item.precioVenta.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.right,
              ),
            ),

            const SizedBox(width: 8),

            // Subtotal
            Expanded(
              flex: 2,
              child: Text(
                '\$${subtotalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
