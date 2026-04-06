extension DecimalFormatter on String? {
  String formatDecimal({int fractionDigits = 6, String defaultValue = '-'}) {
    if (this == null || this!.trim().isEmpty) return defaultValue;

    final value = double.tryParse(this!);
    if (value == null) return defaultValue;

    return value.toStringAsFixed(fractionDigits);
  }
}
