import 'package:koonol/models/articulo.dart';
import 'package:koonol/models/cliente.dart';
import 'package:koonol/models/clasificacion.dart';

class DataProvider {
  static final List<Map<String, dynamic>> _clasificacionesData = [
    {
      'id': 1,
      'descripcion': 'Huevo',
      'idfoto': null,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 2,
      'descripcion': 'Ropa',
      'idfoto': null,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 3,
      'descripcion': 'Hogar',
      'idfoto': null,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
  ];

  static final List<Map<String, dynamic>> _articulosData = [
    {
      'id': 1,
      'codigo': 'Caja de huevo',
      'descripcion': 'Caja de huevos',
      'precio': 120,
      'existencia': 15,
      'idClasificacion': 1,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 2,
      'codigo': 'Cartón de huevo',
      'descripcion': 'Cartón de huevos',
      'precio': 120,
      'existencia': 8,
      'idClasificacion': 1,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 3,
      'codigo': 'Kilo de huevo',
      'descripcion': 'Kilo de huevos',
      'precio': 80,
      'existencia': 25,
      'idClasificacion': 1,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 4,
      'codigo': 'JEAN001',
      'descripcion': 'Pantalón Mezclilla Levi\'s',
      'precio': 1299.99,
      'existencia': 18,
      'idClasificacion': 2,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 5,
      'codigo': 'LAMP001',
      'descripcion': 'Lámpara LED de Mesa',
      'precio': 299.99,
      'existencia': 30,
      'idClasificacion': 3,
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
  ];

  static final List<Map<String, dynamic>> _clientesData = [
    {
      'idcliente': 1,
      'tipo': 'publico',
      'nombre': 'Público General',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 2,
      'tipo': 'mayorista',
      'nombre': 'Mayorista',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 3,
      'tipo': 'publico',
      'nombre': 'Canek',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-11-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 4,
      'tipo': 'publico',
      'nombre': 'Ositos',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-02T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 5,
      'tipo': 'mayorista',
      'nombre': 'Molino',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 6,
      'tipo': 'mayorista',
      'nombre': 'Panadero',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 7,
      'tipo': 'mayorista',
      'nombre': 'Cocina CIO',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 8,
      'tipo': 'mayorista',
      'nombre': 'Taquería',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 9,
      'tipo': 'mayorista',
      'nombre': 'Viejitos',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 10,
      'tipo': 'mayorista',
      'nombre': 'Ceviche',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 11,
      'tipo': 'mayorista',
      'nombre': 'Perlita',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 12,
      'tipo': 'mayorista',
      'nombre': 'Molino Roma',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 13,
      'tipo': 'mayorista',
      'nombre': 'Mexicanita',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 14,
      'tipo': 'mayorista',
      'nombre': 'Plaza Americas',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 15,
      'tipo': 'mayorista',
      'nombre': 'Viejo Molino',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 16,
      'tipo': 'mayorista',
      'nombre': 'Plaza dorada',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 17,
      'tipo': 'mayorista',
      'nombre': 'Dario',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 18,
      'tipo': 'mayorista',
      'nombre': 'Panuchito',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 20,
      'tipo': 'mayorista',
      'nombre': 'Jeny (Panuchitos)',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 21,
      'tipo': 'mayorista',
      'nombre': 'Tio Bady ???',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 22,
      'tipo': 'mayorista',
      'nombre': 'Claudia',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 23,
      'tipo': 'mayorista',
      'nombre': 'Libano',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 24,
      'tipo': 'mayorista',
      'nombre': 'Castillo',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 25,
      'tipo': 'mayorista',
      'nombre': 'Humberto',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-10-00T00:00:00.000Z',
      'fecha_baja': null,
    },
  ];

  static final List<Map<String, dynamic>> _tiposPagoData = [
    {'idTipoPago': 1, 'descripcion': 'Efectivo'},
    {'idTipoPago': 2, 'descripcion': 'Transferencia'},
    {'idTipoPago': 3, 'descripcion': 'Tarjeta de Crédito/Débito'},
  ];

  // Métodos para obtener datos
  static List<Clasificacion> getClasificaciones() {
    return _clasificacionesData
        .map((json) => Clasificacion.fromJson(json))
        .toList();
  }

  static List<Articulo> getArticulos() {
    return _articulosData.map((json) => Articulo.fromJson(json)).toList();
  }

  static List<Cliente> getClientes() {
    return _clientesData.map((json) => Cliente.fromJson(json)).toList();
  }

  // Métodos de búsqueda
  static List<Articulo> buscarArticulos(String query) {
    final articulos = getArticulos();
    if (query.isEmpty) return articulos;

    return articulos
        .where(
          (articulo) =>
              articulo.descripcion.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              articulo.codigo.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  static List<Cliente> buscarClientes(String query) {
    final clientes = getClientes();
    if (query.isEmpty) return clientes;

    return clientes
        .where(
          (cliente) =>
              cliente.nombre.toLowerCase().contains(query.toLowerCase()) ||
              cliente.idCliente.toString().contains(query),
        )
        .toList();
  }

  static Cliente? getClienteById(int id) {
    final clientes = getClientes();
    try {
      return clientes.firstWhere((cliente) => cliente.idCliente == id);
    } catch (e) {
      return null;
    }
  }
}
