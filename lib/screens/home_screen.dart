import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '/screens/form_screen.dart';
import '/widgets/carousel_images.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _logoLink = "";
  String _localLogoVersion = "0"; // Valor local (guardado en 'logo_variable.json')

  @override
  void initState() {
    super.initState();
    _loadLocalLogoVariable().then((localVer) {
      _localLogoVersion = localVer ?? "0";
      _checkAndUpdateLogo();
    });
  }

  Future<String?> _loadLocalLogoVariable() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/logo_variable.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return data["url_logo_version"]?.toString();
      }
    } catch (e) {
      print("Error leyendo variable local del logo: $e");
    }
    return null;
  }

  Future<void> _writeLocalLogoVariable(String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/logo_variable.json');
      Map<String, dynamic> data = {"url_logo_version": value};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error escribiendo variable local del logo: $e");
    }
  }

  Future<void> _checkAndUpdateLogo() async {
    try {
      final response = await http.get(Uri.parse(
          "https://fly2w.biblioteca1.info/getVariable.php?var_nombre=url_logo"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(response.body);
        String remoteValueStr = remoteData['var_valor'].toString();
        String remoteUrl      = remoteData['var_descripcion'].toString();
        print("Valor remoto de url_logo: $remoteValueStr, URL: $remoteUrl");
        int? remoteValue = int.tryParse(remoteValueStr);
        int? localValue  = int.tryParse(_localLogoVersion);

        if (remoteValue != null && localValue != null && remoteValue > localValue) {
          setState(() {
            _logoLink = remoteUrl;
            _localLogoVersion = remoteValueStr;
          });
          await _writeLocalLogoVariable(remoteValueStr);
          print("Logo actualizado. Nueva versión local: $_localLogoVersion");
        } else {
          // Si no había link aún, al menos asignamos la URL para que aparezca
          if (_logoLink.isEmpty) {
            setState(() {
              _logoLink = remoteUrl;
            });
          }
          print("Logo está actualizado (versión local: $_localLogoVersion, remoto: $remoteValueStr)");
        }
      } else {
        print("Error consultando url_logo: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción consultando url_logo: $e");
    }
  }

  Future<void> _launchLogoUrl() async {
    if (_logoLink.isNotEmpty) {
      final Uri url = Uri.parse(_logoLink);
      print("Intentando lanzar URL: $_logoLink");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
        print("URL lanzada correctamente.");
      } else {
        print("No se pudo abrir la URL: $_logoLink");
      }
    } else {
      print("El valor de _logoLink está vacío.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // SECCIÓN SUPERIOR: Logo y título
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _launchLogoUrl,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Vuelos privados al mundo",
                    style: TextStyle(
                      color: Color(0xFF006BB9),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // SECCIÓN MEDIA: Carrusel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CarouselImages(),
              ),
            ),

            // SECCIÓN INFERIOR: Botón "Solicitar cotización"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006BB9),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 32.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Solicitar cotización',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
