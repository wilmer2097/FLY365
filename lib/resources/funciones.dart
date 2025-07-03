import 'dart:ui';

import 'package:fl_country_code_picker/fl_country_code_picker.dart';

Map<String, dynamic> datosPaisActual() {
  Locale locale = PlatformDispatcher.instance.locale;

  String? countryCode = locale.countryCode;
  String? contryNumber = CountryCode.fromCode(countryCode)?.dialCode;

  final data = <String, dynamic>{};
  data["codigoPais"] = countryCode;
  data["numeroPais"] = contryNumber;
  return data;
}