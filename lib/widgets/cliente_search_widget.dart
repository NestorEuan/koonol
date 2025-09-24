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
    return // En el método build(), reemplazar todo el contenido del Card por:
    Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reducido de 16 a 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solo mostrar el header si no hay cliente seleccionado
            if (widget.clienteSeleccionado == null) ...[
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
              const SizedBox(height: 8), // Reducido de 12 a 8
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'ID Cliente / Nombre',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSelection,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ), // Reducido padding
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
            ],

            // Cliente seleccionado
            if (widget.clienteSeleccionado != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10), // Reducido de 12 a 10
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, // Reducido de 8 a 6
                                  vertical: 3, // Reducido de 4 a 3
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
                                  horizontal: 6, // Reducido de 8 a 6
                                  vertical: 3, // Reducido de 4 a 3
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
                          const SizedBox(height: 6), // Reducido de 8 a 6
                          Text(
                            widget.clienteSeleccionado!.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget
                              .clienteSeleccionado!
                              .telefono
                              .isNotEmpty) ...[
                            const SizedBox(height: 3), // Reducido de 4 a 3
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey,
                                ),
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
                    // Icono de borrado
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: _clearSelection,
                        tooltip: 'Limpiar selección',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Lista de sugerencias (solo si no hay cliente seleccionado)
            if (_showSuggestions &&
                widget.clienteSeleccionado == null &&
                _clientesEncontrados.isNotEmpty) ...[
              const SizedBox(height: 6), // Reducido de 8 a 6
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ), // Reducido padding
                      leading: CircleAvatar(
                        backgroundColor: _getTipoColor(cliente.tipo),
                        radius: 18, // Reducido de 20 a 18
                        child: Text(
                          cliente.idCliente.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reducido tamaño
                          ),
                        ),
                      ),
                      title: Text(
                        cliente.nombre,
                        style: const TextStyle(fontSize: 14), // Reducido tamaño
                      ),
                      subtitle: Text(
                        cliente.tipo,
                        style: const TextStyle(fontSize: 12), // Reducido tamaño
                      ),
                      onTap: () => _selectCliente(cliente),
                    );
                  },
                ),
              ),
            ],
            if (_showSuggestions &&
                widget.clienteSeleccionado == null &&
                _clientesEncontrados.isEmpty) ...[
              const SizedBox(height: 6), // Reducido de 8 a 6
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12), // Reducido de 16 a 12
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
