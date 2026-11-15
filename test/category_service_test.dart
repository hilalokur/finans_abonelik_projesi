import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_abonelik_projesi/services/app_preferences.dart';
import 'package:finans_abonelik_projesi/services/category_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'custom categories can be added, renamed, recolored, and removed',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.instance.initializeForUser('category-test');
      final service = CategoryService.instance;
      await service.load();
      await service.add('Okuma', const Color(0xFFC4B5FD));
      expect(service.names, contains('Okuma'));
      await service.rename('Okuma', 'Kitap');
      await service.setColor('Kitap', const Color(0xFF8B5CF6));
      expect(
        service.categories.singleWhere((item) => item.name == 'Kitap').color,
        const Color(0xFF8B5CF6),
      );
      await service.remove('Kitap');
      expect(service.names, isNot(contains('Kitap')));
    },
  );
}
