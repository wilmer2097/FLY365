import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '/models/carousel_image_model.dart';
import '/screens/form_screen.dart';

class CarouselImages extends StatefulWidget {
  @override
  _CarouselImagesState createState() => _CarouselImagesState();
}

class _CarouselImagesState extends State<CarouselImages> {
  List<CarouselImageFromView> images = [];
  int currentIndex = 0;
  late PageController _pageController;
  Timer? _timer;
  final double imageHeight = 300;

  // Variable local para Img_cambio y lista de nombres de archivo predeterminados
  String _localImgCambio = "0";
  final List<String> defaultFilenames = [
    'destino1.jpg',
    'destino2.jpg',
    'destino3.jpg',
    'destino4.jpg',
    'destino5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);

    // Primero, leemos el valor local de Img_cambio y luego verificamos si hay cambios.
    _readLocalImgCambio().then((localVal) {
      _localImgCambio = localVal ?? "0";
      _checkAndUpdateVariable();
    });

    // Timer para auto-avanzar el carrusel
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients && images.isNotEmpty) {
        currentIndex = (currentIndex + 1) % images.length;
        _pageController.animateToPage(
          currentIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<String?> _readLocalImgCambio() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/variables.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return data["Img_cambio"]?.toString();
      }
    } catch (e) {
      print("Error leyendo variable local Img_cambio: $e");
    }
    return null;
  }

  Future<void> _writeLocalImgCambio(String value) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/variables.json');
      Map<String, dynamic> data = {"Img_cambio": value};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error escribiendo variable local Img_cambio: $e");
    }
  }

  Future<void> _checkAndUpdateVariable() async {
    try {
      final response = await http.get(Uri.parse("https://fly2w.biblioteca1.info/getVariable.php?var_nombre=Img_cambio"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteData = jsonDecode(response.body);
        String remoteValueStr = remoteData['var_valor'].toString();
        int? remoteValue = int.tryParse(remoteValueStr);
        int? localValue = int.tryParse(_localImgCambio);
        if (remoteValue != null && localValue != null && remoteValue > localValue) {
          // Si hay cambio, evictamos la cache de cada imagen usando la lista predeterminada.
          for (String fname in defaultFilenames) {
            String url = "https://fly2w.biblioteca1.info/images/$fname";
            await CachedNetworkImage.evictFromCache(url);
            print("Cache evicted for $fname");
          }
          setState(() {
            _localImgCambio = remoteValueStr;
          });
          await _writeLocalImgCambio(remoteValueStr);
        }
      } else {
        print("Error consultando Img_cambio: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción consultando Img_cambio: $e");
    } finally {
      // Luego de verificar (y evictar si es necesario) se cargan las imágenes.
      _fetchVectorImages();
    }
  }

  Future<void> _fetchVectorImages() async {
    try {
      final response = await http.get(Uri.parse("https://fly2w.biblioteca1.info/getVectorImg.php"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          images = data.map((json) => CarouselImageFromView.fromJson(json)).toList();
        });
      } else {
        print("Error al obtener imágenes: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción al obtener imágenes: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final imageData = images[index];
              // Asumimos que las imágenes se llaman "destino{id}.jpg"
              final imageUrl = "https://fly2w.biblioteca1.info/images/destino${imageData.id}.jpg";
              return GestureDetector(
                onTap: () {
                  // Al pulsar la imagen, se navega al formulario y se pasa el código de promoción (si existe)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormScreen(promoCode: imageData.promo),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: imageHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Container(
                        height: imageHeight,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: imageHeight,
                        child: Center(child: Text('Error al cargar la imagen')),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == index ? azulVibrante : amarilloCalido,
              ),
            );
          }),
        ),
      ],
    );
  }
}
