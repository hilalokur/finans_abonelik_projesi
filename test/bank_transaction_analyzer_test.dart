import 'package:flutter_test/flutter_test.dart';
import 'package:finans_abonelik_projesi/services/bank_transaction_analyzer.dart';

void main() {
  test('suggests recurring monthly merchants without saving records', () {
    const csv = '''date,description,amount,currency
2026-01-03,Mystream Plus,-12.99,USD
2026-02-03,Mystream Plus,-12.99,USD
2026-03-04,Mystream Plus,-13.49,USD
2026-03-04,Grocery Store,-55.00,USD''';

    final candidates = const BankTransactionAnalyzer().analyzeCsv(csv);
    expect(candidates, hasLength(1));
    expect(candidates.single.merchant, 'Mystream Plus');
    expect(candidates.single.occurrences, 3);
  });
}
