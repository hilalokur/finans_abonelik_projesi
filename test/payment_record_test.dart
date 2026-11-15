import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_abonelik_projesi/models/subscription.dart';
import 'package:finans_abonelik_projesi/services/app_preferences.dart';
import 'package:finans_abonelik_projesi/services/payment_record_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'payment snapshots keep original transaction amount after edits',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.instance.initializeForUser('payments@example.com');
      final ledger = PaymentRecordService.instance;
      await ledger.load();
      final subscription = SubscriptionModel(
        id: 'snapshot-test',
        name: 'Service',
        service: 'Service',
        category: SubscriptionCategory.other,
        amount: 12.50,
        currency: 'USD',
        billingCycle: 'Monthly',
        nextBillingDate: DateTime(2026, 11, 1),
        logoText: 'S',
        accentColor: Color(0xFF8B5CF6),
      );
      final snapshot = await ledger.record(subscription);
      final edited = subscription.copyWith(amount: 18.00);
      expect(edited.amount, 18.00);
      expect(snapshot.originalAmount, 12.50);
      expect(ledger.records.first.originalAmount, 12.50);
    },
  );
}
