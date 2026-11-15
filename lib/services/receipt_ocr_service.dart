import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcrResult {
  const ReceiptOcrResult({
    required this.text,
    this.serviceName,
    this.amount,
    this.currency = 'TRY',
    this.transactionDate,
  });

  final String text;
  final String? serviceName;
  final double? amount;
  final String currency;
  final DateTime? transactionDate;
}

class ReceiptOcrService {
  ReceiptOcrService._();

  static final ReceiptOcrService instance = ReceiptOcrService._();

  static const _serviceNames = [
    'Amazon Prime Video',
    'YouTube Premium',
    'Apple Music',
    'PlayStation Plus',
    'Xbox Game Pass',
    'Netflix',
    'Spotify',
    'Disney+',
    'Exxen',
    'BluTV',
    'Gain',
  ];

  Future<ReceiptOcrResult> scanImage(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      final text = result.text;
      return ReceiptOcrResult(
        text: text,
        serviceName: _findService(text),
        amount: _findAmount(text),
        currency: _findCurrency(text),
        transactionDate: _findDate(text),
      );
    } finally {
      await recognizer.close();
    }
  }

  String? _findService(String text) {
    final normalized = text.toLowerCase();
    for (final service in _serviceNames) {
      if (normalized.contains(service.toLowerCase())) return service;
    }
    return null;
  }

  double? _findAmount(String text) {
    final currencyAmount = RegExp(
      r'(?:₺|\b(?:TRY|TL|USD|EUR)\b)\s*([0-9][0-9.,]*)|([0-9][0-9.,]*)\s*(?:₺|\b(?:TRY|TL|USD|EUR)\b)',
      caseSensitive: false,
    );
    final matches = currencyAmount.allMatches(text).toList();
    if (matches.isNotEmpty) {
      final match = matches.last;
      final raw = match.group(1) ?? match.group(2);
      final parsed = _parseNumber(raw);
      if (parsed != null && parsed > 0) return parsed;
    }

    final generalAmounts = RegExp(
      r'\b\d{1,6}[.,]\d{2}\b',
    ).allMatches(text).toList();
    if (generalAmounts.isEmpty) return null;
    return _parseNumber(generalAmounts.last.group(0));
  }

  double? _parseNumber(String? raw) {
    if (raw == null) return null;
    var value = raw.replaceAll(' ', '');
    if (value.contains(',') && value.contains('.')) {
      if (value.lastIndexOf(',') > value.lastIndexOf('.')) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (value.contains(',')) {
      value = value.replaceAll(',', '.');
    }
    return double.tryParse(value);
  }

  String _findCurrency(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('USD') || text.contains(r'$')) return 'USD';
    if (upper.contains('EUR') || text.contains('€')) return 'EUR';
    return 'TRY';
  }

  DateTime? _findDate(String text) {
    final match = RegExp(
      r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b',
    ).firstMatch(text);
    if (match == null) return null;
    final first = int.tryParse(match.group(1)!);
    final second = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (first == null || second == null || year == null) return null;
    if (year < 100) year += year < 70 ? 2000 : 1900;
    final date = DateTime(year, second, first);
    if (date.year != year || date.month != second || date.day != first) {
      return null;
    }
    return date;
  }
}
