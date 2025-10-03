import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/venta.dart';
import '../data/database_manager.dart';

class GraficosVentasScreen extends StatefulWidget {
  const GraficosVentasScreen({super.key});

  @override
  State<GraficosVentasScreen> createState() => _GraficosVentasScreenState();
}

class _GraficosVentasScreenState extends State<GraficosVentasScreen> {
  late Venta _ventaRepository;

  bool _isLoading = true;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 6));
  DateTime _fechaFin = DateTime.now();
  Map<String, double> _ventasPorFecha = {};
  Map<String, dynamic> _estadisticas = {};

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _shortDateFormat = DateFormat('dd/MM');

  @override
  void initState() {
    super.initState();
    _inicializarSemanaActual();
    _inicializarRepositorio();
  }

  void _inicializarSemanaActual() {
    final ahora = DateTime.now();
    final inicioDeSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    _fechaInicio = DateTime(
      inicioDeSemana.year,
      inicioDeSemana.month,
      inicioDeSemana.day,
    );
    _fechaFin = _fechaInicio.add(const Duration(days: 6));
  }

  Future<void> _inicializarRepositorio() async {
    final dbManager = DatabaseManager();
    final database = await dbManager.database;
    _ventaRepository = Venta(database);
    await _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Cargar ventas agrupadas por fecha
      final ventas = await _ventaRepository.getVentasAgrupadasPorFecha(
        _fechaInicio,
        _fechaFin,
      );

      // Cargar estadísticas del período
      final stats = await _ventaRepository.getEstadisticasPorRango(
        _fechaInicio,
        _fechaFin,
      );

      if (mounted) {
        setState(() {
          _ventasPorFecha = ventas;
          _estadisticas = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar datos: $e');
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
          if (_fechaInicio.isAfter(_fechaFin)) {
            _fechaFin = _fechaInicio;
          }
        } else {
          _fechaFin = fechaSeleccionada;
          if (_fechaFin.isBefore(_fechaInicio)) {
            _fechaInicio = _fechaFin;
          }
        }
      });
      await _cargarDatos();
    }
  }

  void _cargarSemanaActual() {
    _inicializarSemanaActual();
    _cargarDatos();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
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
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              _buildFiltros(),
                              const SizedBox(height: 8),
                              _buildEstadisticasCard(),
                              const SizedBox(height: 8),
                              _buildGraficoBarras(),
                              const SizedBox(height: 8),
                              _buildResumenDiario(),
                            ],
                          ),
                        ),
                ),
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
          const Icon(Icons.bar_chart, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Gráficos de Ventas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
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
            'Período',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cargarSemanaActual,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Semana Actual'),
            ),
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

  Widget _buildEstadisticasCard() {
    final totalVentas = _estadisticas['montoTotal'] ?? 0.0;
    final ventasActivas = _estadisticas['ventasActivas'] ?? 0;
    final promedioVenta = _estadisticas['promedioVenta'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Resumen del Período',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaItem(
                  'Total Ventas',
                  '\$${totalVentas.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildEstadisticaItem(
                  'Cantidad',
                  '$ventasActivas',
                  Icons.shopping_cart,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildEstadisticaItem(
                  'Promedio',
                  '\$${promedioVenta.toStringAsFixed(2)}',
                  Icons.analytics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, String valor, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGraficoBarras() {
    if (_ventasPorFecha.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No hay datos para mostrar')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Ventas por Día',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final fecha = _ventasPorFecha.keys.elementAt(groupIndex);
                      final valor = rod.toY;
                      return BarTooltipItem(
                        '${_shortDateFormat.format(DateTime.parse(fecha))}\n\$${valor.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _ventasPorFecha.length) {
                          final fecha = _ventasPorFecha.keys.elementAt(
                            value.toInt(),
                          );
                          final date = DateTime.parse(fecha);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY() / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_ventasPorFecha.isEmpty) return 100;
    final maxValue = _ventasPorFecha.values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _getBarGroups() {
    return _ventasPorFecha.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final valor = entry.value.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: valor,
            color: Colors.blue.shade400,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade300],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildResumenDiario() {
    if (_ventasPorFecha.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Detalle por Día',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._ventasPorFecha.entries.map((entry) {
            final fecha = DateTime.parse(entry.key);
            final valor = entry.value;
            final esHoy =
                fecha.day == DateTime.now().day &&
                fecha.month == DateTime.now().month &&
                fecha.year == DateTime.now().year;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: esHoy ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: esHoy ? Colors.blue.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: esHoy ? Colors.blue : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateFormat.format(fecha),
                      style: TextStyle(
                        fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '\$${valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: valor > 0 ? Colors.green : Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
