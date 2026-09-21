/// Converts a weight string such as "3-6.7 kg" or "70-100 g" to kilograms.
///
/// Uses the number directly before the unit (the high end of a range). Returns 0 when the
/// value is missing or has no recognisable unit, so unknown weights sort last.
double parseWeightKg(String? weightStr) {
  if (weightStr == null) return 0;
  final kgMatch = RegExp(r'(\d+(\.\d+)?)\s*kg').firstMatch(weightStr);
  if (kgMatch != null) {
    return double.tryParse(kgMatch.group(1) ?? '0') ?? 0;
  }
  final gMatch = RegExp(r'(\d+(\.\d+)?)\s*g').firstMatch(weightStr);
  if (gMatch != null) {
    return (double.tryParse(gMatch.group(1) ?? '0') ?? 0) / 1000.0;
  }
  return 0;
}
