import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:koonol/screens/detalle_venta_dialog.dart';
import 'package:koonol/widgets/cancelar_venta_dialog.dart';
import '../data/venta.dart';
import '../data/database_manager.dart';
import '../models/venta_mdl.dart';

class ConsultaVentasScreen extends StatefulWidget {
  const ConsultaVentasScreen({super.key});

  @override
  State<ConsultaVentasScreen> createState() => _ConsultaVentasScreenState();
}

class _ConsultaVentasScreenState extends State<ConsultaVentasScreen> {
  late Venta _ventaRepository;

  List<VentaMdl> _ventas = [];
  bool _isLoading = true;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();
  String _filtroEstado = 'TODAS'; // 'TODAS', 'ACTIVA', 'CANCELADA'

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _inicializarRepositorio();
  }

  Future<void> _inicializarRepositorio() async {
    final dbManager = DatabaseManager();
    final database = await dbManager.database;
    _ventaRepository = Venta(database);
    await _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);

    try {
      final ventas = await _ventaRepository.getVentasPorRango(
        _fechaInicio,
        _fechaFin,
        estado: _filtroEstado == 'TODAS' ? null : _filtroEstado,
      );

      if (mounted) {
        setState(() {
          _ventas = ventas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar ventas: $e');
      }
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      //locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
          // Si la fecha inicio es mayor que la final, ajustar
          if (_fechaInicio.isAfter(_fechaFin)) {
            _fechaFin = _fechaInicio;
          }
        } else {
          _fechaFin = fechaSeleccionada;
          // Si la fecha final es menor que la inicial, ajustar
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaInicio = _fechaFin;
          }
        }
      });
      await _cargarVentas();
    }
  }

  void _cambiarFiltroEstado(String nuevoEstado) {
    setState(() {
      _filtroEstado = nuevoEstado;
    });
    _cargarVentas();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildFiltros(),
                _buildEstadisticas(),
                Expanded(child: _buildListaVentas()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Icons.receipt_long, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Consulta de Ventas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Filtro de fechas
          Row(
            children: [
              Expanded(
                child: _buildFechaButton(
                  'Desde: ${_dateFormat.format(_fechaInicio)}',
                  () => _seleccionarFecha(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFechaButton(
                  'Hasta: ${_dateFormat.format(_fechaFin)}',
                  () => _seleccionarFecha(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filtro de estado
          Row(
            children: [
              const Text('Estado: '),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'TODAS',
                      label: Text('Todas', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 'ACTIVA',
                      label: Text('Activas', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 'CANCELADA',
                      label: Text('Canceladas', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_filtroEstado},
                  onSelectionChanged: (Set<String> selection) {
                    _cambiarFiltroEstado(selection.first);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFechaButton(String texto, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    final ventasActivas = _ventas.where((v) => v.cEstado == 'ACTIVA').length;
    final ventasCanceladas = _ventas
        .where((v) => v.cEstado == 'CANCELADA')
        .length;
    final totalVentas = _ventas
        .where((v) => v.cEstado == 'ACTIVA')
        .fold<double>(0, (sum, v) => sum + v.total);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEstadisticaItem(
              'Total',
              '\$${totalVentas.toStringAsFixed(2)}',
              Colors.green,
              Icons.attach_money,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildEstadisticaItem(
              'Activas',
              '$ventasActivas',
              Colors.blue,
              Icons.check_circle,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: _buildEstadisticaItem(
              'Canceladas',
              '$ventasCanceladas',
              Colors.red,
              Icons.cancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem(
    String label,
    String valor,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildListaVentas() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No se encontraron ventas',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _ventas.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final venta = _ventas[index];
          return _buildVentaItem(venta);
        },
      ),
    );
  }

  Widget _buildVentaItem(VentaMdl venta) {
    final esActiva = venta.cEstado == 'ACTIVA';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: esActiva ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          esActiva ? Icons.check_circle : Icons.cancel,
          color: esActiva ? Colors.green : Colors.red,
          size: 28,
        ),
      ),
      title: Row(
        children: [
          Text(
            'Venta #${venta.idVenta}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: esActiva ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              venta.cEstado,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Fecha: ${_dateFormat.format(venta.dtFecha)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Total: \$${venta.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: esActiva ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            onPressed: () => _verDetalleVenta(venta),
            tooltip: 'Ver detalle',
          ),
          if (esActiva)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () => _confirmarCancelacion(venta),
              tooltip: 'Cancelar venta',
            ),
        ],
      ),
      onTap: () => _verDetalleVenta(venta),
    );
  }

  Future<void> _verDetalleVenta(VentaMdl venta) async {
    await showDialog(
      context: context,
      builder: (context) => DetalleVentaDialog(venta: venta),
    );
  }

  Future<void> _confirmarCancelacion(VentaMdl venta) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelarVentaDialog(venta: venta),
    );

    if (resultado == true) {
      // Recargar la lista de ventas
      await _cargarVentas();
    }
  }
}
