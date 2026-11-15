import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';
import 'app_preferences.dart';
import 'currency_service.dart';

/// Historical payment snapshots are append-only and never revalued.
@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.subscriptionId,
    required this.serviceName,
    required this.originalAmount,
    required this.originalCurrency,
    required this.paidAt,
    this.displayCurrency,
    this.convertedAmount,
    this.exchangeRateUsed,
    this.referenceRateDate,
  });
  final String id, subscriptionId, serviceName, originalCurrency;
  final double originalAmount;
  final DateTime paidAt;
  final String? displayCurrency;
  final double? convertedAmount, exchangeRateUsed;
  final DateTime? referenceRateDate;
  Map<String, dynamic> toMap() => {
    'id': id,
    'subscriptionId': subscriptionId,
    'serviceName': serviceName,
    'originalAmount': originalAmount,
    'originalCurrency': originalCurrency,
    'paidAt': paidAt.toIso8601String(),
    'displayCurrency': displayCurrency,
    'convertedAmount': convertedAmount,
    'exchangeRateUsed': exchangeRateUsed,
    'referenceRateDate': referenceRateDate?.toIso8601String(),
  };
  factory PaymentRecord.fromMap(Map<String, dynamic> map) => PaymentRecord(
    id: map['id'] as String,
    subscriptionId: map['subscriptionId'] as String,
    serviceName: map['serviceName'] as String,
    originalAmount: (map['originalAmount'] as num).toDouble(),
    originalCurrency: map['originalCurrency'] as String,
    paidAt: DateTime.parse(map['paidAt'] as String),
    displayCurrency: map['displayCurrency'] as String?,
    convertedAmount: (map['convertedAmount'] as num?)?.toDouble(),
    exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
    referenceRateDate: map['referenceRateDate'] == null
        ? null
        : DateTime.parse(map['referenceRateDate'] as String),
  );
}

class PaymentRecordService extends ChangeNotifier {
  PaymentRecordService._();
  static final instance = PaymentRecordService._();
  final List<PaymentRecord> _records = [];
  bool _loadedForUser = false;
  String? _loadedUser;
  List<PaymentRecord> get records => List.unmodifiable(_records);

  Future<void> load() async {
    final user = AppPreferences.instance.userKey;
    if (_loadedForUser && _loadedUser == user) return;
    _loadedUser = user;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subtrack.payments.$user');
    _records
      ..clear()
      ..addAll(
        raw == null
            ? []
            : (jsonDecode(raw) as List).whereType<Map>().map(
                (item) =>
                    PaymentRecord.fromMap(Map<String, dynamic>.from(item)),
              ),
      );
    _loadedForUser = true;
    notifyListeners();
  }

  Future<PaymentRecord> record(SubscriptionModel subscription) async {
    await load();
    final target = AppPreferences.instance.currency;
    final converted = CurrencyService.instance.convert(
      subscription.amount,
      from: subscription.currency,
      to: target,
    );
    final sourceRate = CurrencyService
        .instance
        .rates[CurrencyService.normalizeCurrency(subscription.currency)];
    final targetRate = CurrencyService
        .instance
        .rates[CurrencyService.normalizeCurrency(target)];
    final record = PaymentRecord(
      id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
      subscriptionId: subscription.id,
      serviceName: subscription.name,
      originalAmount: subscription.amount,
      originalCurrency: CurrencyService.normalizeCurrency(
        subscription.currency,
      ),
      paidAt: DateTime.now(),
      displayCurrency: converted == null ? null : target,
      convertedAmount: converted,
      exchangeRateUsed:
          sourceRate == null || targetRate == null || sourceRate == 0
          ? null
          : targetRate / sourceRate,
      referenceRateDate: converted == null
          ? null
          : CurrencyService.instance.rateDate,
    );
    _records.insert(0, record);
    await _save();
    notifyListeners();
    return record;
  }

  List<PaymentRecord> forSubscription(String id) =>
      _records.where((item) => item.subscriptionId == id).toList();

  double? totalForPeriod(DateTime start, DateTime end, String currency) {
    final matching = _records.where(
      (item) => !item.paidAt.isBefore(start) && item.paidAt.isBefore(end),
    );
    var total = 0.0;
    for (final item in matching) {
      if (item.displayCurrency == currency && item.convertedAmount != null) {
        total += item.convertedAmount!;
      } else if (CurrencyService.normalizeCurrency(item.originalCurrency) ==
          currency) {
        total += item.originalAmount;
      } else {
        return null;
      }
    }
    return matching.isEmpty ? null : total;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'subtrack.payments.${AppPreferences.instance.userKey}',
      jsonEncode(_records.map((item) => item.toMap()).toList()),
    );
  }
}
