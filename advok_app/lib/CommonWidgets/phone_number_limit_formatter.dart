import 'package:flutter/services.dart';

import '../Utils/CountryData/country_catalog.dart';

/// Blocks typing more digits than the selected country's phone length
/// (e.g. 10 for India/US). Separators like spaces, dashes and brackets
/// don't count toward the limit.
class PhoneNumberLimitFormatter extends TextInputFormatter {
  PhoneNumberLimitFormatter([int? maxDigits])
      : maxDigits = maxDigits ?? CountryCatalog.selected.maxDigits;

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '').length;
    return digits > maxDigits ? oldValue : newValue;
  }
}
