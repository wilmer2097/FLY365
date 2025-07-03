import 'package:flutter/material.dart';

class CustomAlertWidget extends StatelessWidget {
  final String mensaje;
  final bool esExito;
  final String botonTexto;

  const CustomAlertWidget({
    Key? key,
    required this.mensaje,
    required this.esExito,
    this.botonTexto = 'Aceptar',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Estilo del diálogo (ventana flotante)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono: check para éxito y exclamación para error
            Icon(
              esExito ? Icons.check_circle : Icons.warning,
              size: 60,
              color: esExito ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            // Mensaje de la alerta
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Botón para aceptar y cerrar el diálogo
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                botonTexto,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
