import 'package:flutter_test/flutter_test.dart';
import 'package:finans_abonelik_projesi/main.dart';

void main() {
  testWidgets('Splash ekranı yükleniyor', (tester) async {
    await tester.pumpWidget(const SubtrackApp());

    expect(find.text('Abonelik ve Finans Takip Sistemi'), findsOneWidget);
    expect(find.byType(SubtrackApp), findsOneWidget);
  });
}
