import 'package:flutter/material.dart';

import '../models/subscription.dart';
import 'currency_service.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService instance = SubscriptionService._();

  SubscriptionService._();

  final List<SubscriptionModel> _subscriptions = [
    SubscriptionModel(
      id: 'netflix',
      name: 'Netflix',
      service: 'Streaming',
      category: SubscriptionCategory.entertainment,
      amount: 149.99,
      currency: 'TL',
      billingCycle: 'Aylık',
      nextBillingDate: DateTime.now().add(const Duration(days: 7)),
      logoText: 'N',
      accentColor: const Color(0xFFEF4444),
    ),
    SubscriptionModel(
      id: 'spotify',
      name: 'Spotify',
      service: 'Müzik',
      category: SubscriptionCategory.music,
      amount: 89.0,
      currency: 'TL',
      billingCycle: 'Aylık',
      nextBillingDate: DateTime.now().add(const Duration(days: 12)),
      logoText: 'S',
      accentColor: const Color(0xFF22C55E),
    ),
    SubscriptionModel(
      id: 'youtube',
      name: 'YouTube Premium',
      service: 'Video',
      category: SubscriptionCategory.entertainment,
      amount: 119.0,
      currency: 'TL',
      billingCycle: 'Aylık',
      nextBillingDate: DateTime.now().add(const Duration(days: 18)),
      logoText: 'YT',
      accentColor: const Color(0xFFFF0000),
    ),
    SubscriptionModel(
      id: 'notion',
      name: 'Notion Pro',
      service: 'Productivity',
      category: SubscriptionCategory.productivity,
      amount: 64.0,
      currency: 'TL',
      billingCycle: 'Aylık',
      nextBillingDate: DateTime.now().add(const Duration(days: 24)),
      logoText: 'N',
      accentColor: const Color(0xFF8B5CF6),
    ),
    SubscriptionModel(
      id: 'drive',
      name: 'Google One',
      service: 'Bulut',
      category: SubscriptionCategory.cloud,
      amount: 39.99,
      currency: 'TL',
      billingCycle: 'Aylık',
      nextBillingDate: DateTime.now().add(const Duration(days: 30)),
      logoText: 'G',
      accentColor: const Color(0xFF22D3EE),
    ),
  ];

  List<SubscriptionModel> get subscriptions =>
      List.unmodifiable(_subscriptions);

  double monthlyTotalInCurrency(String currency) {
    final normalizedCurrency = CurrencyService.normalizeCurrency(currency);
    return _subscriptions.where((item) => item.isActive).fold<double>(0, (
      sum,
      item,
    ) {
      final sourceCurrency = CurrencyService.normalizeCurrency(item.currency);
      final converted = CurrencyService.convertAmount(
        monthlyEquivalent(item),
        from: sourceCurrency,
        to: normalizedCurrency,
        rates: CurrencyService.instance.rates,
      );
      return sum + (converted ?? 0);
    });
  }

  bool hasMissingRatesFor(String currency) => _subscriptions
      .where((item) => item.isActive)
      .any(
        (item) =>
            CurrencyService.convertAmount(
              item.amount,
              from: item.currency,
              to: currency,
              rates: CurrencyService.instance.rates,
            ) ==
            null,
      );

  double monthlyEquivalent(SubscriptionModel item) {
    final cycle = item.billingCycle.toLowerCase();
    if (cycle.contains('yıl') || cycle.contains('year')) {
      return item.amount / 12;
    }
    if (cycle.contains('hafta') || cycle.contains('week')) {
      return item.amount * 4.345;
    }
    if (cycle.contains('gün') || cycle.contains('day')) {
      return item.amount * 30.437;
    }
    return item.amount;
  }

  double projectedTotalInMonth(DateTime month, String currency) {
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1);
    var total = 0.0;
    for (final item in _subscriptions.where((item) => item.isActive)) {
      var dueDate = DateTime(
        item.nextBillingDate.year,
        item.nextBillingDate.month,
        item.nextBillingDate.day,
      );
      for (
        var guard = 0;
        guard < 600 && dueDate.isBefore(monthStart);
        guard++
      ) {
        dueDate = _advanceDate(dueDate, item.billingCycle);
      }
      for (var guard = 0; guard < 12 && dueDate.isBefore(monthEnd); guard++) {
        total +=
            CurrencyService.convertAmount(
              item.amount,
              from: item.currency,
              to: currency,
              rates: CurrencyService.instance.rates,
            ) ??
            0;
        dueDate = _advanceDate(dueDate, item.billingCycle);
      }
    }
    return total;
  }

  DateTime _advanceDate(DateTime date, String cycle) {
    final normalized = cycle.toLowerCase();
    if (normalized.contains('hafta') || normalized.contains('week')) {
      return date.add(const Duration(days: 7));
    }
    if (normalized.contains('gün') || normalized.contains('day')) {
      return date.add(const Duration(days: 1));
    }
    final annual = normalized.contains('yıl') || normalized.contains('year');
    final nextMonth = DateTime(date.year, date.month + (annual ? 12 : 1), 1);
    final day = date.day
        .clamp(1, DateUtils.getDaysInMonth(nextMonth.year, nextMonth.month))
        .toInt();
    return DateTime(nextMonth.year, nextMonth.month, day);
  }

  double get monthlyTotal => monthlyTotalInCurrency('TRY');

  Map<String, double> categoryBreakdownInCurrency(String currency) {
    final normalizedCurrency = CurrencyService.normalizeCurrency(currency);
    final breakdown = <String, double>{};
    for (final item in _subscriptions) {
      if (!item.isActive) continue;
      final key = item.categoryName;
      final converted = CurrencyService.convertAmount(
        monthlyEquivalent(item),
        from: CurrencyService.normalizeCurrency(item.currency),
        to: normalizedCurrency,
        rates: CurrencyService.instance.rates,
      );
      if (converted != null) {
        breakdown[key] = (breakdown[key] ?? 0) + converted;
      }
    }
    return breakdown;
  }

  Map<String, double> get categoryBreakdown =>
      categoryBreakdownInCurrency('TRY');

  int get activeCount => _subscriptions.where((item) => item.isActive).length;

  double cancelledMonthlySavingsEstimateInCurrency(String currency) =>
      _subscriptions
          .where((item) => !item.isActive)
          .fold<double>(
            0,
            (sum, item) =>
                sum +
                (CurrencyService.convertAmount(
                      monthlyEquivalent(item),
                      from: item.currency,
                      to: currency,
                      rates: CurrencyService.instance.rates,
                    ) ??
                    0),
          );

  List<SubscriptionModel> get upcomingPayments {
    final sorted = _subscriptions.where((item) => item.isActive).toList()
      ..sort(
        (first, second) =>
            first.nextBillingDate.compareTo(second.nextBillingDate),
      );
    return sorted.take(3).toList();
  }

  void addSubscription(SubscriptionModel item) {
    _subscriptions.insert(0, item);
    notifyListeners();
  }

  void updateSubscription(SubscriptionModel item) {
    final index = _subscriptions.indexWhere((current) => current.id == item.id);
    if (index >= 0) {
      final previous = _subscriptions[index];
      final changes = [...item.priceChanges];
      if (previous.amount != item.amount ||
          previous.currency != item.currency) {
        changes.add(
          SubscriptionPriceChange(
            oldAmount: previous.amount,
            newAmount: item.amount,
            currency: item.currency,
            changedAt: DateTime.now(),
          ),
        );
      }
      _subscriptions[index] = item.copyWith(priceChanges: changes);
    }
    notifyListeners();
  }

  void removeSubscription(String id) {
    _subscriptions.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
