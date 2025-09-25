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
      'fecha_alta': '2024-01-01T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 2,
      'descripcion': 'Ropa',
      'idfoto': null,
      'estatus': true,
      'fecha_alta': '2024-01-01T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'id': 3,
      'descripcion': 'Hogar',
      'idfoto': null,
      'estatus': true,
      'fecha_alta': '2024-01-01T00:00:00.000Z',
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
      'fecha_alta': '2024-01-01T00:00:00.000Z',
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
      'fecha_alta': '2024-01-01T00:00:00.000Z',
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
      'fecha_alta': '2024-01-01T00:00:00.000Z',
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
      'fecha_alta': '2024-01-01T00:00:00.000Z',
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
      'fecha_alta': '2024-01-01T00:00:00.000Z',
      'fecha_baja': null,
    },
  ];

  static final List<Map<String, dynamic>> _clientesData = [
    {
      'idcliente': 1,
      'tipo': 'Genérico',
      'nombre': 'Público General',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-01-01T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 2,
      'tipo': 'Mayorista',
      'nombre': 'Mayorista',
      'direccion': '',
      'telefono': '',
      'RFC': '',
      'mail': '',
      'estatus': true,
      'fecha_alta': '2024-01-01T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 3,
      'tipo': 'Regular',
      'nombre': 'Juan Pérez López',
      'direccion': 'Av. Reforma 123, Col. Centro',
      'telefono': '555-0123',
      'RFC': 'PELJ800101XXX',
      'mail': 'juan.perez@email.com',
      'estatus': true,
      'fecha_alta': '2024-01-15T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 4,
      'tipo': 'Regular',
      'nombre': 'María González Rodríguez',
      'direccion': 'Calle 5 de Mayo 456, Col. Juárez',
      'telefono': '555-0456',
      'RFC': 'GORM900215XXX',
      'mail': 'maria.gonzalez@email.com',
      'estatus': true,
      'fecha_alta': '2024-01-20T00:00:00.000Z',
      'fecha_baja': null,
    },
    {
      'idcliente': 5,
      'tipo': 'VIP',
      'nombre': 'Empresa ABC S.A. de C.V.',
      'direccion': 'Blvd. Tecnológico 789, Col. Industrial',
      'telefono': '555-0789',
      'RFC': 'ABC850310XXX',
      'mail': 'contacto@empresaabc.com',
      'estatus': true,
      'fecha_alta': '2024-02-01T00:00:00.000Z',
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
