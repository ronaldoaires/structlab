/// Parses a number typed by the user (accepts comma or dot).
double? parseNumber(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));