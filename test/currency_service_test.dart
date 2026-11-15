import 'package:flutter_test/flutter_test.dart';
import 'package:finans_abonelik_projesi/services/currency_service.dart';

void main() {
  group('CurrencyService', () {
    const rates = {'TRY': 1.0, 'USD': 0.032, 'EUR': 0.028, 'GBP': 0.024};

    test('converts reference rates with fixed-point precision', () {
      expect(
        CurrencyService.convertAmount(
          100,
          from: 'TRY',
          to: 'USD',
          rates: rates,
        ),
        closeTo(3.2, 0.000001),
      );
      expect(
        CurrencyService.convertAmount(
          100,
          from: 'USD',
          to: 'TRY',
          rates: rates,
        ),
        closeTo(3125, 0.000001),
      );
      expect(
        CurrencyService.convertAmount(
          50.12,
          from: 'EUR',
          to: 'GBP',
          rates: rates,
        ),
        closeTo(42.96, 0.01),
      );
      expect(
        CurrencyService.convertAmount(
          3.45,
          from: 'TL',
          to: 'TRY',
          rates: rates,
        ),
        3.45,
      );
    });

    test('does not invent a converted amount when a rate is missing', () {
      expect(
        CurrencyService.convertAmount(
          100,
          from: 'TRY',
          to: 'EUR',
          rates: {'TRY': 1, 'USD': .03},
        ),
        isNull,
      );
      expect(
        CurrencyService.convertAmount(
          100,
          from: 'XYZ',
          to: 'TRY',
          rates: rates,
        ),
        isNull,
      );
    });
  });
}
