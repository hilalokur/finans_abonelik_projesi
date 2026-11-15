// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cached Frankfurter reference rates, normalized as quote units per TRY.
class CurrencyService extends ChangeNotifier {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();
  static const supportedCurrencies = ['TRY', 'USD', 'EUR', 'GBP'];
  static const _cacheKey = 'subtrack.frankfurter.rates.v2';

  final Map<String, double> _rates = {'TRY': 1};
  DateTime? _rateDate;
  DateTime? _fetchedAt;
  bool _stale = true;
  bool _loading = false;

  Map<String, double> get rates => Map.unmodifiable(_rates);
  DateTime? get rateDate => _rateDate;
  DateTime? get fetchedAt => _fetchedAt;
  bool get isStale => _stale;
  bool get isLoading => _loading;

  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final rates = (map['rates'] as Map).map<String, double>(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
      if (!_validRateMap(rates)) return;
      _rates
        ..clear()
        ..addAll(rates);
      _rateDate = DateTime.tryParse(map['rateDate'] as String? ?? '');
      _fetchedAt = DateTime.tryParse(map['fetchedAt'] as String? ?? '');
      _stale = true;
      notifyListeners();
    } catch (_) {
      // A corrupt cache is ignored; no guessed fallback conversions are used.
    }
  }

  Future<void> refreshRates({http.Client? client}) async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    final requestClient = client ?? http.Client();
    try {
      final uri = Uri.https('api.frankfurter.dev', '/v2/rates', {
        'base': 'TRY',
        'quotes': 'USD,EUR,GBP',
      });
      final response = await requestClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200)
        throw const FormatException('Rate API error');
      final rows = jsonDecode(response.body);
      if (rows is! List) throw const FormatException('Invalid rate response');
      final next = <String, double>{'TRY': 1};
      DateTime? latestDate;
      for (final row in rows.whereType<Map>()) {
        final quote = normalizeCurrency(row['quote']?.toString() ?? '');
        final rate = double.tryParse(row['rate']?.toString() ?? '');
        final date = DateTime.tryParse(row['date']?.toString() ?? '');
        if (supportedCurrencies.contains(quote) &&
            quote != 'TRY' &&
            rate != null &&
            rate > 0) {
          next[quote] = rate;
          if (date != null && (latestDate == null || date.isAfter(latestDate)))
            latestDate = date;
        }
      }
      if (!_validRateMap(next))
        throw const FormatException('Missing supported currencies');
      _rates
        ..clear()
        ..addAll(next);
      _rateDate = latestDate;
      _fetchedAt = DateTime.now();
      _stale = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'rates': _rates,
          'rateDate': _rateDate?.toIso8601String(),
          'fetchedAt': _fetchedAt?.toIso8601String(),
        }),
      );
    } catch (_) {
      // Keep last successful cache; callers can clearly identify it as stale.
      _stale = true;
    } finally {
      if (client == null) requestClient.close();
      _loading = false;
      notifyListeners();
    }
  }

  bool _validRateMap(Map<String, double> map) =>
      supportedCurrencies.every((code) => map[code] != null && map[code]! > 0);

  static String normalizeCurrency(String value) {
    final normalized = value.trim().toUpperCase();
    return normalized == 'TL' ? 'TRY' : normalized;
  }

  /// Converts through TRY using fixed-point integer arithmetic (1e-8 rates).
  /// Returns null if either reference rate is unavailable.
  static double? convertAmount(
    double amount, {
    required String from,
    required String to,
    Map<String, double>? rates,
  }) {
    if (!amount.isFinite) return null;
    final source = normalizeCurrency(from);
    final target = normalizeCurrency(to);
    if (source == target) return amount;
    final active = rates ?? instance.rates;
    final fromRate = active[source];
    final toRate = active[target];
    if (fromRate == null || toRate == null || fromRate <= 0 || toRate <= 0)
      return null;
    final amountMicros = _scaledInteger(amount, 1000000);
    final fromRateScaled = _scaledInteger(fromRate, 100000000);
    final toRateScaled = _scaledInteger(toRate, 100000000);
    if (amountMicros == null || fromRateScaled == null || toRateScaled == null)
      return null;
    final numerator = BigInt.from(amountMicros) * BigInt.from(toRateScaled);
    final denominator = BigInt.from(fromRateScaled);
    final result = _roundDivide(numerator, denominator);
    return result.toDouble() / 1000000;
  }

  static int? _scaledInteger(double value, int scale) {
    final text = value.toStringAsFixed(8);
    final negative = text.startsWith('-');
    final parts = text.replaceFirst('-', '').split('.');
    final whole = BigInt.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = (parts.length > 1 ? parts[1] : '')
        .padRight(8, '0')
        .substring(0, 8);
    final scaled = whole * BigInt.from(100000000) + BigInt.parse(fraction);
    final adjusted = scale == 1000000
        ? _roundDivide(scaled, BigInt.from(100))
        : scaled;
    final signed = negative ? -adjusted : adjusted;
    if (signed < BigInt.from(-9007199254740991) ||
        signed > BigInt.from(9007199254740991))
      return null;
    return signed.toInt();
  }

  static BigInt _roundDivide(BigInt numerator, BigInt denominator) {
    final sign = numerator.isNegative ? -BigInt.one : BigInt.one;
    final abs = numerator.abs();
    return sign * ((abs + denominator ~/ BigInt.two) ~/ denominator);
  }

  double? convert(double amount, {required String from, required String to}) =>
      convertAmount(amount, from: from, to: to, rates: _rates);

  String format(double amount, String currency) {
    final value = convert(amount, from: 'TRY', to: currency);
    return value == null
        ? '— ${normalizeCurrency(currency)}'
        : '${value.toStringAsFixed(2)} ${normalizeCurrency(currency)}';
  }
}
