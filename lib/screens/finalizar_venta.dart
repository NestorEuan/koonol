import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/carrito_item.dart';
import '../models/cliente.dart';
import '../models/tipo_pago_mdl.dart';
import '../data/tipo_pago.dart';
import '../services/venta_service.dart';
import '../services/corte_caja_service.dart';
import '../widgets/cliente_vista_reducida_widget.dart';
import '../widgets/articulo_listado_reducido_widget.dart';

class FinalizarVentaScreen extends StatefulWidget {
  final List<CarritoItem> carrito;
  final Cliente cliente;
  final Function() onVentaFinalizada;

  const FinalizarVentaScreen({
    super.key,
    required this.carrito,
    required this.cliente,
    required this.onVentaFinalizada,
  });

  @override
  State<FinalizarVentaScreen> createState() => _FinalizarVentaScreenState();
}

class _FinalizarVentaScreenState extends State<FinalizarVentaScreen> {
  TipoPago? _tipoPagoRepository;
  VentaService? _ventaService;
  CorteCajaService? _corteCajaService;

  List<TipoPagoMdl> _tiposPago = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, double> _montosPago = {};
  bool _isProcessing = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Inicializar servicios
      _tipoPagoRepository = await TipoPago.getInstance();
      _ventaService = await VentaService.getInstance();
      _corteCajaService = await CorteCajaService.getInstance();

      // Verificar estado del corte
      final estadoCorte = await _corteCajaService!.verificarEstadoCorte();
      if (!estadoCorte['existe'] || estadoCorte['estado'] == 'CERRADO') {
        setState(() {
          _errorMessage = estadoCorte['mensaje'];
          _isLoading = false;
        });
        return;
      }

      // Cargar tipos de pago
      await _cargarTiposPago();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarTiposPago() async {
    try {
      _tiposPago = await _tipoPagoRepository!.getTiposPago();

      // Inicializar controladores para cada tipo de pago
      _controllers.clear();
      _montosPago.clear();

      for (var tipoPago in _tiposPago) {
        final id = tipoPago.idTipoPago ?? 0;
        _controllers[id] = TextEditingController();
        _montosPago[id] = 0.0;
      }
    } catch (e) {
      _mostrarError('Error al cargar tipos de pago: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _calcularTotal() {
    return widget.carrito.fold(0.0, (total, item) => total + item.subtotal);
  }

  double _calcularTotalArticulos() {
    return widget.carrito.fold(0, (total, item) => total + item.cantidad);
  }

  double _calcularTotalPagos() {
    return _montosPago.values.fold(0.0, (total, monto) => total + monto);
  }

  double _getMontoEfectivo() {
    try {
      // Buscar el ID del tipo de pago "Efectivo"
      final efectivo = _tiposPago.firstWhere(
        (tipo) => tipo.cTipoPago.toLowerCase() == 'efectivo',
      );
      return _montosPago[efectivo.idTipoPago] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _calcularCambio() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();
    final montoEfectivo = _getMontoEfectivo();

    // Solo hay cambio si:
    // 1. Hay efectivo
    // 2. El total de pagos es mayor al total de la venta
    if (montoEfectivo > 0 && totalPagos > total) {
      final exceso = totalPagos - total;
      // El cambio es el menor entre el exceso y el efectivo disponible
      return exceso <= montoEfectivo ? exceso : montoEfectivo;
    }
    return 0.0;
  }

  void _onMontoChanged(int idTipoPago, String valor) {
    final double monto = double.tryParse(valor) ?? 0.0;
    setState(() {
      _montosPago[idTipoPago] = monto;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _procesarVenta() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Filtrar solo los tipos de pago con monto > 0
      final Map<int, double> tiposPagoFiltrados = {};
      _montosPago.forEach((id, monto) {
        if (monto > 0) {
          tiposPagoFiltrados[id] = monto;
        }
      });

      // Calcular valores que necesita el servicio
      final double totalPagado = _calcularTotalPagos();
      final double cambio = _calcularCambio();

      // Procesar la venta - El servicio ya no valida pagos, solo guarda
      final resultado = await _ventaService!.procesarVenta(
        cliente: widget.cliente,
        carrito: widget.carrito,
        tiposPago: tiposPagoFiltrados,
        totalPagado: totalPagado,
        cambio: cambio,
        descuento: 0.0, // Por ahora sin descuentos
        iva: 0.0, // Por ahora sin IVA
      );

      if (resultado['success']) {
        _mostrarExito('Venta procesada exitosamente');
        _mostrarResumenVenta(resultado);
      } else {
        _mostrarError('Error al procesar la venta');
      }
    } catch (e) {
      _mostrarError('Error al procesar la venta: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _mostrarResumenVenta(Map<String, dynamic> resultado) {
    final cambio = resultado['cambio'] ?? 0.0;
    final total = resultado['total'] ?? 0.0;
    final totalPagado = resultado['totalPagado'] ?? 0.0;
    final idVenta = resultado['idVenta'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Venta Completada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Venta ID: $idVenta'),
              Text('Cliente: ${widget.cliente.nombre}'),
              const Divider(),
              const Text(
                'Métodos de pago:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._tiposPago
                  .where((tipo) => (_montosPago[tipo.idTipoPago] ?? 0) > 0)
                  .map(
                    (tipo) => Text(
                      '${tipo.cTipoPago}: \$${(_montosPago[tipo.idTipoPago] ?? 0).toStringAsFixed(2)}',
                    ),
                  ),
              const Divider(),
              Text('Total: \$${total.toStringAsFixed(2)}'),
              Text('Pagado: \$${totalPagado.toStringAsFixed(2)}'),
              if (cambio > 0)
                Text(
                  'Cambio: \$${cambio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text('Artículos: ${_calcularTotalArticulos()}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onVentaFinalizada();
                Navigator.of(context).pop();
              },
              child: const Text('Nueva Venta'),
            ),
          ],
        );
      },
    );
  }

  Color _getEstadoPagoColor() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();

    if (totalPagos == 0) return Colors.grey;
    if (totalPagos < total) return Colors.red;
    if (totalPagos == total) return Colors.green;
    return Colors.blue; // Exceso (cambio)
  }

  String _getEstadoPagoTexto() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();

    if (totalPagos == 0) return 'Sin pagos';
    if (totalPagos < total) return 'Insuficiente';
    if (totalPagos == total) return 'Exacto';
    return 'Exceso (Cambio)';
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Finalizar Venta'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando sistema de ventas...'),
            ],
          ),
        ),
      );
    }

    // Pantalla de error
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'No se puede procesar la venta',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regresar'),
              ),
            ],
          ),
        ),
      );
    }

    // Pantalla principal
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();
    final cambio = _calcularCambio();
    final diferencia = totalPagos - total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Venta'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente
            ClienteVistaReducidaWidget(cliente: widget.cliente),

            const SizedBox(height: 8),
            // Total de la venta
            _buildTotalVenta(total),

            const SizedBox(height: 8),
            // Métodos de pago con montos
            _buildMetodosPago(),

            const SizedBox(height: 8),
            // Estado del pago
            _buildEstadoPago(totalPagos, diferencia),

            const SizedBox(height: 8),
            // Información del cambio
            if (cambio > 0) _buildCambio(cambio),

            if (cambio > 0) const SizedBox(height: 8),
            // Listado de artículos
            ArticuloListadoReducidoWidget(
              items: widget.carrito,
              editable: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotonesAccion(),
    );
  }

  Widget _buildTotalVenta(double total) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total de la Venta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoPagoItem(TipoPagoMdl tipoPago) {
    final id = tipoPago.idTipoPago ?? 0;
    return Row(
      children: [
        _getTipoPagoIcon(tipoPago.cTipoPago),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(
            tipoPago.cTipoPago,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _controllers[id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (valor) => _onMontoChanged(id, valor),
          ),
        ),
      ],
    );
  }

  Widget _buildMetodosPago() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Método de Pago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Crear grid de 2 columnas
            ...List.generate((_tiposPago.length / 2).ceil(), (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2 > _tiposPago.length)
                  ? _tiposPago.length
                  : startIndex + 2;
              final rowItems = _tiposPago.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Primera columna
                    Expanded(child: _buildTipoPagoItem(rowItems[0])),
                    const SizedBox(width: 8),
                    // Segunda columna (puede estar vacía en la última fila)
                    Expanded(
                      child: rowItems.length > 1
                          ? _buildTipoPagoItem(rowItems[1])
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Icon _getTipoPagoIcon(String descripcion) {
    final desc = descripcion.toLowerCase();
    if (desc.contains('efectivo')) {
      return const Icon(Icons.attach_money, color: Colors.green);
    } else if (desc.contains('tarjeta') ||
        desc.contains('crédito') ||
        desc.contains('débito')) {
      return const Icon(Icons.credit_card, color: Colors.blue);
    } else if (desc.contains('transferencia')) {
      return const Icon(Icons.account_balance, color: Colors.purple);
    } else if (desc.contains('cheque')) {
      return const Icon(Icons.receipt_long, color: Colors.orange);
    } else {
      return const Icon(Icons.payment, color: Colors.grey);
    }
  }

  Widget _buildEstadoPago(double totalPagos, double diferencia) {
    final color = _getEstadoPagoColor();
    final estado = _getEstadoPagoTexto();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pagos:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalPagos.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  estado,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (diferencia != 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    diferencia > 0 ? 'Exceso:' : 'Faltante:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  Text(
                    '\$${diferencia.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: diferencia > 0 ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCambio(double cambio) {
    final montoEfectivo = _getMontoEfectivo();
    final totalPagos = _calcularTotalPagos();
    final total = _calcularTotal();
    final exceso = totalPagos - total;

    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.change_circle, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Cambio a Entregar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cambio:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  '\$${cambio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            // Advertencia si el exceso es mayor al efectivo
            if (exceso > montoEfectivo && montoEfectivo > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cambio limitado al efectivo recibido: \$${montoEfectivo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();
    final puedeConfirmar =
        totalPagos >= total && (totalPagos == total || _getMontoEfectivo() > 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regresar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isProcessing || !puedeConfirmar
                    ? null
                    : _procesarVenta,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isProcessing ? 'Procesando...' : 'Confirmar Venta',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: puedeConfirmar ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
