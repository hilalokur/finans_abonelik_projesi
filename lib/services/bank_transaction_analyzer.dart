// ignore_for_file: curly_braces_in_flow_control_structures
import 'subscription_service.dart';

class RecurringPaymentCandidate {
  const RecurringPaymentCandidate({
    required this.merchant,
    required this.averageAmount,
    required this.currency,
    required this.occurrences,
    required this.lastDate,
  });
  final String merchant, currency;
  final double averageAmount;
  final int occurrences;
  final DateTime lastDate;
}

class BankTransactionAnalyzer {
  const BankTransactionAnalyzer();

  List<RecurringPaymentCandidate> analyzeCsv(
    String csv, {
    String currency = 'TRY',
  }) {
    final rows = csv
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final groups = <String, List<(DateTime, double, String, String)>>{};
    for (final line in rows.skip(1)) {
      final fields = _parseCsvLine(line);
      if (fields.length < 3) continue;
      DateTime? date;
      var dateIndex = -1;
      var amountIndex = -1;
      double? amount;
      for (var i = 0; i < fields.length; i++) {
        final parsedDate = DateTime.tryParse(fields[i].trim());
        if (date == null && parsedDate != null) {
          date = parsedDate;
          dateIndex = i;
        }
      }
      for (var i = 0; i < fields.length; i++) {
        if (i == dateIndex) continue;
        if (amount == null) {
          final candidate = double.tryParse(
            fields[i]
                .replaceAll(' ', '')
                .replaceAll(',', '.')
                .replaceAll(RegExp(r'[^0-9.-]'), ''),
          );
          if (candidate != null && candidate.abs() >= .01) {
            amount = candidate.abs();
            amountIndex = i;
          }
        }
      }
      if (date == null || amount == null) continue;
      final rowCurrency = fields
          .map((field) => field.trim().toUpperCase())
          .firstWhere(
            (field) => const ['TRY', 'TL', 'USD', 'EUR', 'GBP'].contains(field),
            orElse: () => currency,
          );
      final normalizedCurrency = rowCurrency == 'TL' ? 'TRY' : rowCurrency;
      final merchant = fields
          .asMap()
          .entries
          .where((entry) => entry.key != amountIndex)
          .map((entry) => entry.value.trim())
          .firstWhere(
            (value) =>
                value.isNotEmpty &&
                DateTime.tryParse(value) == null &&
                !const [
                  'TRY',
                  'TL',
                  'USD',
                  'EUR',
                  'GBP',
                ].contains(value.toUpperCase()) &&
                value.length > 2,
            orElse: () => '',
          );
      if (merchant.isEmpty ||
          merchant.toLowerCase().contains('merchant') ||
          merchant.toLowerCase().contains('description'))
        continue;
      final key = merchant.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      groups.putIfAbsent(key, () => []).add((
        date,
        amount,
        merchant,
        normalizedCurrency,
      ));
    }

    final existing = SubscriptionService.instance.subscriptions
        .map((item) => item.name.toLowerCase())
        .toList();
    final result = <RecurringPaymentCandidate>[];
    for (final transactions in groups.values) {
      if (transactions.length < 2) continue;
      transactions.sort((a, b) => a.$1.compareTo(b.$1));
      final last = transactions.last;
      if (existing.any(
        (name) =>
            last.$3.toLowerCase().contains(name) ||
            name.contains(last.$3.toLowerCase()),
      ))
        continue;
      final gaps = [
        for (var i = 1; i < transactions.length; i++)
          transactions[i].$1.difference(transactions[i - 1].$1).inDays,
      ];
      final monthlyGaps = gaps.where((gap) => gap >= 20 && gap <= 40).length;
      final amounts = transactions.map((row) => row.$2).toList();
      final average = amounts.reduce((a, b) => a + b) / amounts.length;
      final consistent = amounts.every(
        (amount) => (amount - average).abs() / average <= .3,
      );
      if (monthlyGaps == 0 || !consistent) continue;
      result.add(
        RecurringPaymentCandidate(
          merchant: last.$3,
          averageAmount: average,
          currency: last.$4,
          occurrences: transactions.length,
          lastDate: last.$1,
        ),
      );
    }
    result.sort((a, b) => b.lastDate.compareTo(a.lastDate));
    return result;
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }
}
