import 'articulo_mdl.dart';

class CarritoItem {
  final ArticuloMdl articulo;
  double cantidad;
  double precioVenta;

  CarritoItem({
    required this.articulo,
    required this.cantidad,
    required this.precioVenta,
  });

  double get subtotal => cantidad * precioVenta;

  CarritoItem copyWith({
    ArticuloMdl? articulo,
    double? cantidad,
    double? precioVenta,
  }) {
    return CarritoItem(
      articulo: articulo ?? this.articulo,
      cantidad: cantidad ?? this.cantidad,
      precioVenta: precioVenta ?? this.precioVenta,
    );
  }
}
