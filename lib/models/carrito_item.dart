import 'articulo.dart';

class CarritoItem {
  final Articulo articulo;
  int cantidad;
  double precioVenta;

  CarritoItem({
    required this.articulo,
    required this.cantidad,
    required this.precioVenta,
  });

  double get subtotal => cantidad * precioVenta;

  CarritoItem copyWith({
    Articulo? articulo,
    int? cantidad,
    double? precioVenta,
  }) {
    return CarritoItem(
      articulo: articulo ?? this.articulo,
      cantidad: cantidad ?? this.cantidad,
      precioVenta: precioVenta ?? this.precioVenta,
    );
  }
}
