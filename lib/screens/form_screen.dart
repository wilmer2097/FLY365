import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fly2w_365/resources/funciones.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:path_provider/path_provider.dart';
import 'custom_alert_widget.dart';
import 'multi_select_search.dart'; // Para MultiSelectServiciosDropdown
import 'package:intl/intl.dart';
// Paleta de colores
const Color blanco = Color(0xFFFFFFFF);
const Color amarilloCrema = Color(0xFFFFE3B3);
const Color amarilloCalido = Color(0xFFFFC973);
const Color azulClaro = Color(0xFF30A0E0);
const Color azulVibrante = Color(0xFF006BB9);
const Color fondoFormulario = Color(0xFFF7F7F7);

class FormScreen extends StatefulWidget {
  final String? promoCode;

  const FormScreen({super.key, this.promoCode});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController codigoPromoController = TextEditingController();
  final TextEditingController origenController = TextEditingController();
  final TextEditingController destinoController = TextEditingController();
  final TextEditingController condicionesController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();

  // Número de teléfono
  String completePhoneNumber = '';
  String _formatDate(DateTime? dt) {
    if (dt == null) return 'No seleccionada';
    // Por ejemplo: 2025-06-21
    return DateFormat('yyyy-MM-dd').format(dt.toLocal());
  }
  // Variables para fechas
  DateTime? fechaPartida;
  DateTime? fechaRetorno;
  bool fechasFijas = false;
  bool soloPartida = false;

  // Código del país, por defecto 'PE'
  String _initialCountryCode = 'PE';

  // Dropdown: Número de pasajeros (1 a 10 y "Más de 10")
  int _selectedPasajeros = 1;

  // Lista de ubicaciones (destinos) que se usarán en el Autocomplete
  List<String> locations = [];

  // Variable local para la versión de destinos (destino_cambio)
  String _localDestinoVersion = "0";

  // IDs seleccionados de servicios
  List<int> _selectedServiceIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.promoCode != null) {
      codigoPromoController.text = widget.promoCode!;
    }
    _loadLocalDestinoVersion().then((localVer) {
      _localDestinoVersion = localVer ?? "0";
      _loadLocationsFromAPI();
    });
    _obtenerCodigoPais();
  }

  /// Carga la versión local de destino_cambio
  Future<String?> _loadLocalDestinoVersion() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/destino_variable.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return data["destino_cambio"]?.toString();
      }
    } catch (e) {
      print("Error leyendo la versión local de destinos: \$e");
    }
    return null;
  }

  /// Guarda la versión local de destino_cambio
  Future<void> _writeLocalDestinoVersion(String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/destino_variable.json');
      await file.writeAsString(jsonEncode({'destino_cambio': value}));
    } catch (e) {
      print("Error escribiendo la versión local de destinos: \$e");
    }
  }

  /// Consulta la API para destinos
  Future<void> _loadLocationsFromAPI() async {
    const apiUrl = "https://fly2w.biblioteca1.info/getDestinos.php";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final remoteVersionStr = data["destino_cambio"].toString();
        final remoteVersion = int.tryParse(remoteVersionStr);
        final localVersion = int.tryParse(_localDestinoVersion);

        final destinos = data["destinos"] as List<dynamic>;
        setState(() {
          locations = destinos.map((d) => d["agrupado"] as String).toList();
        });

        if (remoteVersion != null && localVersion != null && remoteVersion > localVersion) {
          await _writeLocalDestinoVersion(remoteVersionStr);
          print("Destinos actualizados. Versión: \$remoteVersionStr");
        }
      } else {
        print("Error al consultar destinos: \${response.statusCode}");
      }
    } catch (e) {
      print("Excepción al cargar destinos: \$e");
    }
  }

  Future<void> _obtenerCodigoPais() async {
    setState(() {
      _initialCountryCode = datosPaisActual()["codigoPais"];
    });
  }

  Future<void> _selectFechaPartida(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaPartida ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != fechaPartida) {
      setState(() => fechaPartida = picked);
    }
  }

  Future<void> _selectFechaRetorno(BuildContext context) async {
    if (soloPartida) return;
    final initial = fechaPartida != null
        ? fechaPartida!.add(Duration(days: 1))
        : DateTime.now().add(Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaRetorno ?? initial,
      firstDate: fechaPartida ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != fechaRetorno) {
      setState(() => fechaRetorno = picked);
    }
  }

  @override
  void dispose() {
    codigoPromoController.dispose();
    origenController.dispose();
    destinoController.dispose();
    condicionesController.dispose();
    nombreController.dispose();
    correoController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: azulVibrante),
      filled: true,
      fillColor: blanco,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: azulClaro, width: 2),
      ),
    );
  }

  Widget _buildDateSelector(
      String label,
      DateTime? selectedDate,
      bool enabled,
      VoidCallback onTap,
      ) {
    final display = enabled
        ? _formatDate(selectedDate)
        : 'No aplica';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: azulVibrante),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: azulVibrante,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                display,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? (selectedDate != null ? azulVibrante : Colors.grey)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPassengerDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedPasajeros,
      decoration: _buildInputDecoration("Número de Pasajeros"),
      items: List.generate(11, (i) => i + 1).map((val) {
        return DropdownMenuItem<int>(
          value: val,
          child: Text(val == 11 ? "Más de 10" : val.toString()),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedPasajeros = val);
      },
      validator: (v) => v == null ? "Seleccione el número de pasajeros" : null,
    );
  }

  Future<void> _sendReserva() async {
    const apiUrl = "https://fly2w.biblioteca1.info/insertReserva.php";
    final requestData = {
      "codigoPromo": codigoPromoController.text,
      "origen": origenController.text,
      "destino": destinoController.text,
      "fechaPartida": fechaPartida != null ? fechaPartida!.toIso8601String().split("T").first : "",
      "fechaRetorno": soloPartida
          ? ""
          : (fechaRetorno != null ? fechaRetorno!.toIso8601String().split("T").first : ""),
      "solo_partida": soloPartida,
      "fechasFijas": fechasFijas,
      "condiciones": condicionesController.text,
      "nombre": nombreController.text,
      "telefono": completePhoneNumber,
      "correo": correoController.text,
      "pasajeros": _selectedPasajeros,
      "servicios_reservas": _selectedServiceIds.join(',')
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        await showDialog(
          context: context,
          builder: (_) => CustomAlertWidget(
            mensaje: responseData["mensaje"] ?? "Reserva exitosa",
            esExito: true,
          ),
        );
        Navigator.pop(context);
      } else {
        final responseData = jsonDecode(response.body);
        await showDialog(
          context: context,
          builder: (_) => CustomAlertWidget(
            mensaje: responseData["error"] ?? "Error al insertar reserva",
            esExito: false,
          ),
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => CustomAlertWidget(
          mensaje: "Error: \$e",
          esExito: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        backgroundColor: blanco,
        elevation: 0,
        forceMaterialTransparency: true,
        iconTheme: IconThemeData(color: azulVibrante),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            SizedBox(width: 8),
            Text(
              "Formulario de Reserva",
              style: TextStyle(color: azulVibrante, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: fondoFormulario,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Código de Promoción
                    TextFormField(
                      controller: codigoPromoController,
                      decoration: _buildInputDecoration("Código de Promoción (Opcional)", hint: "Ej. A0123 o PE000"),
                    ),
                    SizedBox(height: 16),
                    // Origen
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                        return locations.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) => origenController.text = selection,
                      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
                        return TextFormField(
                          controller: fieldController,
                          focusNode: focusNode,
                          decoration: _buildInputDecoration("Lugar de partida"),
                          validator: (value) => (value == null || value.isEmpty) ? "Seleccione un origen" : null,
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    // Destino
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                        return locations.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) => destinoController.text = selection,
                      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
                        return TextFormField(
                          controller: fieldController,
                          focusNode: focusNode,
                          decoration: _buildInputDecoration("Lugar de destino"),
                          validator: (value) {
                            if (!soloPartida && (value == null || value.isEmpty)) return "Seleccione un destino";
                            return null;
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateSelector("Fecha de partida", fechaPartida, true, () => _selectFechaPartida(context))),
                        SizedBox(width: 16),
                        Expanded(child: _buildDateSelector("Fecha de retorno", fechaRetorno, !soloPartida, () => _selectFechaRetorno(context))),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(value: soloPartida, activeColor: azulClaro, onChanged: (v) { setState(() { soloPartida = v ?? false; if (soloPartida) fechaRetorno = null; }); }),
                        Text("Solo Partida (sin fecha de retorno)", style: TextStyle(color: azulVibrante)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(value: fechasFijas, activeColor: azulClaro, onChanged: (v) => setState(() => fechasFijas = v ?? false)),
                        Text("Fechas Fijas", style: TextStyle(color: azulVibrante)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text('Selecciona servicios:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    MultiSelectServiciosDropdown(
                      initialSelectedIds: _selectedServiceIds,
                      onSelectionChanged: (ids) => setState(() => _selectedServiceIds = ids),
                    ),
                    SizedBox(height: 16),
                    _buildPassengerDropdown(),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: nombreController,
                      decoration: _buildInputDecoration("Nombre y Apellido de Contacto"),
                      validator: (v) => (v == null || v.isEmpty) ? "Este campo es obligatorio" : null,
                    ),
                    SizedBox(height: 16),
                    IntlPhoneField(
                      decoration: _buildInputDecoration("Teléfono"),
                      initialCountryCode: _initialCountryCode,
                      searchText: "Buscar país",
                      onChanged: (phone) => completePhoneNumber = phone.completeNumber,
                      validator: (phone) => (phone == null || phone.number.isEmpty) ? "Ingrese su número de teléfono" : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: correoController,
                      decoration: _buildInputDecoration("Correo"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Este campo es obligatorio";
                        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        return regex.hasMatch(v) ? null : "Ingrese un correo válido";
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: condicionesController,
                      decoration: _buildInputDecoration("Condiciones especiales"),
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) await _sendReserva();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulVibrante,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("Solicitar cotización", style: TextStyle(color: blanco)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
