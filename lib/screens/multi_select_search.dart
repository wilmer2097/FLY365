import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


/// Modelo para un servicio
class Servicio {
  final int id;
  final String nombre;
  Servicio({required this.id, required this.nombre});

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
    id: int.tryParse(json['serv_id'].toString()) ?? 0,
    nombre: json['serv_nombre'] as String,
  );

  @override
  String toString() => nombre;
}

/// Widget de dropdown de selección múltiple para servicios de reserva
class MultiSelectServiciosDropdown extends StatefulWidget {
  /// Callback que devuelve la lista de IDs seleccionados
  final void Function(List<int>) onSelectionChanged;
  /// Lista inicial de IDs seleccionados
  final List<int> initialSelectedIds;

  const MultiSelectServiciosDropdown({
    Key? key,
    required this.onSelectionChanged,
    this.initialSelectedIds = const [],
  }) : super(key: key);

  @override
  _MultiSelectServiciosDropdownState createState() =>
      _MultiSelectServiciosDropdownState();
}

class _MultiSelectServiciosDropdownState
    extends State<MultiSelectServiciosDropdown> {
  List<Servicio> _allServicios = [];
  List<Servicio> _selectedServicios = [];
  String _localVersion = '0';

  @override
  void initState() {
    super.initState();
    _loadLocalVersion().then((ver) {
      _localVersion = ver ?? '0';
      _loadServiciosFromAPI();
    });
  }

  Future<String?> _loadLocalVersion() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/servicios_variable.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        return data['servicios_reserva_cambio']?.toString();
      }
    } catch (e) {
      print('Error leyendo versión local de servicios: \$e');
    }
    return null;
  }

  Future<void> _writeLocalVersion(String v) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/servicios_variable.json');
      await file.writeAsString(jsonEncode({
        'servicios_reserva_cambio': v,
      }));
    } catch (e) {
      print('Error escribiendo versión local de servicios: \$e');
    }
  }

  Future<void> _loadServiciosFromAPI() async {
    const url = 'https://fly2w.biblioteca1.info/getServiciosReservas.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final remoteVerStr = data['servicios_reserva_cambio'].toString();
        final remoteVer = int.tryParse(remoteVerStr) ?? 0;
        final localVer = int.tryParse(_localVersion) ?? 0;

        if (remoteVer > localVer) {
          await _writeLocalVersion(remoteVerStr);
        }

        final List<Servicio> list = (data['servicios'] as List)
            .map((j) => Servicio.fromJson(j))
            .toList();
        setState(() {
          _allServicios = list;
          _selectedServicios = _allServicios
              .where((s) => widget.initialSelectedIds.contains(s.id))
              .toList();
        });
        widget.onSelectionChanged(
            _selectedServicios.map((s) => s.id).toList());
      } else {
        print('Error API servicios: \${response.statusCode}');
      }
    } catch (e) {
      print('Excepción al cargar servicios: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Servicio>.multiSelection(
      items: (String filter, LoadProps? _) {
        return _allServicios
            .where((s) => s.nombre
            .toLowerCase()
            .contains(filter.toLowerCase()))
            .toList();
      },
      compareFn: (Servicio a, Servicio b) => a.id == b.id,
      popupProps: PopupPropsMultiSelection<Servicio>.dialog(
        showSearchBox: true,
        showSelectedItems: true,
      ),
      onChanged: (values) {
        setState(() {
          _selectedServicios = values;
        });
        widget.onSelectionChanged(
            _selectedServicios.map((s) => s.id).toList());
      },
      selectedItems: _selectedServicios,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'Servicios',
          labelStyle: const TextStyle(color: Color(0xFF006BB9)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF30A0E0),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
