/// Daily base prices are whole pesos; percentage discounts retain centavos.
int discountedDailyCentavos(int basePesos, int discountPercent) =>
    basePesos * (100 - discountPercent);

String formatPesos(num pesos) =>
    '₱${pesos.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '')}';
