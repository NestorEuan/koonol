import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../data/data_provider.dart';

class ClienteSearchWidget extends StatefulWidget {
  final Function(Cliente?) onClienteSelected;
  final Cliente? clienteSeleccionado;

  const ClienteSearchWidget({
    super.key,
    required this.onClienteSelected,
    this.clienteSeleccionado,
  });

  @override
  State<ClienteSearchWidget> createState() => _ClienteSearchWidgetState();
}

class _ClienteSearchWidgetState extends State<ClienteSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> _clientesEncontrados = [];
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _clientesEncontrados = DataProvider.getClientes();

    // Si hay un cliente seleccionado, mostrarlo en el campo
    if (widget.clienteSeleccionado != null) {
      _searchController.text = widget.clienteSeleccionado!.nombre;
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _clientesEncontrados = DataProvider.getClientes();
        _showSuggestions = false;
      } else {
        _clientesEncontrados = DataProvider.buscarClientes(query);
        _showSuggestions = true;
      }
    });
  }

  void _selectCliente(Cliente cliente) {
    _searchController.text = cliente.nombre;
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onClienteSelected(cliente);
  }

  void _clearSelection() {
    _searchController.clear();
    setState(() {
      _clientesEncontrados = DataProvider.getClientes();
      _showSuggestions = false;
    });
    widget.onClienteSelected(null);
  }

  Future<void> _scanQRCode() async {
    // Simulación de escaneo QR - aquí se integraría un scanner real
    try {
      // Por ahora simulamos que escaneamos el ID "1"
      final Cliente? cliente = DataProvider.getClienteById(1);
      if (cliente != null) {
        _selectCliente(cliente);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente encontrado por QR'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente no encontrado'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al escanear QR'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Buscar Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'ID Cliente / Nombre',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSelection,
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onTap: () {
                      if (_searchController.text.isNotEmpty) {
                        setState(() {
                          _showSuggestions = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                    onPressed: _scanQRCode,
                    tooltip: 'Escanear QR',
                  ),
                ),
              ],
            ),
            // Cliente seleccionado
            if (widget.clienteSeleccionado != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ID: ${widget.clienteSeleccionado!.idCliente}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTipoColor(
                              widget.clienteSeleccionado!.tipo,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.clienteSeleccionado!.tipo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.clienteSeleccionado!.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.clienteSeleccionado!.telefono.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            widget.clienteSeleccionado!.telefono,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Lista de sugerencias
            if (_showSuggestions && _clientesEncontrados.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _clientesEncontrados.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientesEncontrados[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTipoColor(cliente.tipo),
                        child: Text(
                          cliente.idCliente.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(cliente.nombre),
                      subtitle: Text(cliente.tipo),
                      onTap: () => _selectCliente(cliente),
                    );
                  },
                ),
              ),
            ],
            if (_showSuggestions && _clientesEncontrados.isEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No se encontraron clientes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'genérico':
        return Colors.grey;
      case 'mayorista':
        return Colors.orange;
      case 'vip':
        return Colors.purple;
      case 'regular':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
