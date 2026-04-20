String formatRupiah(int value) {
  final digits = value.toString();
  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();

  for (var i = 0; i < reversed.length; i++) {
    buffer.write(reversed[i]);
    if (i != reversed.length - 1 && (i + 1) % 3 == 0) {
      buffer.write('.');
    }
  }

  return buffer.toString().split('').reversed.join();
}

String formatRupiahCompact(int value) {
  if (value >= 1000 && value % 1000 == 0) {
    return '${value ~/ 1000}K';
  }

  return formatRupiah(value);
}