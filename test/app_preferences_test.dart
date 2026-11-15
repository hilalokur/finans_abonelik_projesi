import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_abonelik_projesi/services/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final preferences = AppPreferences.instance;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('dashboard options persist per user and reset to defaults', () async {
    await preferences.initializeForUser('user-a@example.com');
    preferences.setDashboardVisible('charts', false);
    preferences.reorderDashboard(0, 2);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    await preferences.initializeForUser('user-b@example.com');
    expect(preferences.dashboardIsVisible('charts'), isTrue);
    await preferences.initializeForUser('user-a@example.com');
    expect(preferences.dashboardIsVisible('charts'), isFalse);
    expect(preferences.dashboardOrder.first, 'yearly');
    preferences.resetDashboard();
    expect(preferences.dashboardOrder.first, 'monthly');
  });

  test('appearance settings can be restored', () async {
    await preferences.initializeForUser('appearance@example.com');
    preferences.setBackground('blueGalaxy');
    preferences.setCornerRadius(30);
    preferences.setCompactCards(true);
    preferences.resetAppearance();
    expect(preferences.background, 'purpleGalaxy');
    expect(preferences.cornerRadius, 22);
    expect(preferences.compactCards, isFalse);
  });
}
