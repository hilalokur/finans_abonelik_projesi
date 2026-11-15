// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_category.dart';
import 'app_preferences.dart';

class CategoryService extends ChangeNotifier {
  CategoryService._();
  static final instance = CategoryService._();
  static const _defaults = [
    'Video',
    'Müzik',
    'Oyun',
    'Eğitim',
    'Alışveriş',
    'Bulut Depolama',
    'Diğer',
  ];
  static const _palette = [
    Color(0xFFC4B5FD),
    Color(0xFF8B5CF6),
    Color(0xFFE9D5FF),
    Color(0xFF93C5FD),
    Color(0xFFA5B4FC),
    Color(0xFFD8B4FE),
    Color(0xFFB8B2CC),
  ];
  List<UserCategory> _categories = _defaults
      .map(
        (name) =>
            UserCategory(name: name, color: _palette[_defaults.indexOf(name)]),
      )
      .toList();
  String? _loadedUser;
  List<UserCategory> get categories => List.unmodifiable(_categories);
  static List<Color> get palette => _palette;
  List<String> get names =>
      _categories.map((category) => category.name).toList();

  Future<void> load() async {
    final user = AppPreferences.instance.userKey;
    if (_loadedUser == user) return;
    _loadedUser = user;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subtrack.categories.$user');
    _categories = raw == null
        ? _defaults
              .map(
                (name) => UserCategory(
                  name: name,
                  color: _palette[_defaults.indexOf(name)],
                ),
              )
              .toList()
        : (jsonDecode(raw) as List)
              .whereType<Map>()
              .map(
                (item) => UserCategory.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList();
    notifyListeners();
  }

  Future<void> add(String name, Color color) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        _categories.any(
          (item) => item.name.toLowerCase() == trimmed.toLowerCase(),
        ))
      return;
    _categories.add(UserCategory(name: trimmed, color: color));
    await _save();
  }

  Future<void> rename(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty ||
        _categories.any(
          (item) =>
              item.name.toLowerCase() == trimmed.toLowerCase() &&
              item.name != oldName,
        ))
      return;
    final index = _categories.indexWhere((item) => item.name == oldName);
    if (index < 0) return;
    _categories[index] = UserCategory(
      name: trimmed,
      color: _categories[index].color,
    );
    await _save();
  }

  Future<void> setColor(String name, Color color) async {
    final index = _categories.indexWhere((item) => item.name == name);
    if (index < 0) return;
    _categories[index] = UserCategory(name: name, color: color);
    await _save();
  }

  Future<void> remove(String name) async {
    _categories.removeWhere((item) => item.name == name);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'subtrack.categories.${AppPreferences.instance.userKey}',
      jsonEncode(_categories.map((item) => item.toMap()).toList()),
    );
    notifyListeners();
  }
}
