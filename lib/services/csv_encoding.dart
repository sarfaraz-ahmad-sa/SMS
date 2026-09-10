/// Quote and neutralize every exported cell, including record identifiers.
String encodeCsvCell(String value) {
  final leading = value.trimLeft();
  final unsafe = RegExp(r'^[=+@-]').hasMatch(leading) ||
      value.startsWith('\t') ||
      value.startsWith('\r') ||
      value.startsWith('\n');
  final safe = unsafe ? "'$value" : value;
  final escaped = safe.replaceAll('"', '""');
  return '"$escaped"';
}
