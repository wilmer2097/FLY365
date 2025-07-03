import 'package:flutter/material.dart';

class GifDisplay extends StatelessWidget {
  final List<String> gifUrls = [
    "https://www.icegif.com/wp-content/uploads/2022/01/icegif-498.gif",
    "https://www.icegif.com/wp-content/uploads/2024/10/pikachu-icegif-2.gif",
    // Agrega más URLs aquí
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: gifUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          gifUrls[index],
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text("Error al cargar GIF"));
          },
        );
      },
    );
  }
}
