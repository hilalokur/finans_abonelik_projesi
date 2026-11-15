import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();
  static const dashboardKeys = <String>[
    'monthly',
    'yearly',
    'active',
    'upcoming',
    'charts',
    'recent',
  ];
  static const dashboardLabels = <String, String>{
    'monthly': 'Aylık toplam harcama',
    'yearly': 'Yıllık toplam harcama',
    'active': 'Aktif abonelik sayısı',
    'upcoming': 'Yaklaşan ödemeler',
    'charts': 'Harcama grafikleri',
    'recent': 'Son eklenen abonelikler',
  };

  String _currency = 'TRY';
  bool _notificationsEnabled = true;
  bool _remindOneDay = false;
  bool _remindThreeDays = true;
  bool _remindSevenDays = false;
  bool _trialReminders = true;
  bool _priceAlerts = true;
  bool _muted = false;
  String _notificationTime = '09:00';
  int _reminderDays = 3;
  String _background = 'purpleGalaxy';
  String _accent = 'lavender';
  double _cornerRadius = 22;
  bool _compactCards = false;
  bool _animations = true;
  double? _monthlyBudget;
  List<String> _dashboardOrder = List.of(dashboardKeys);
  Map<String, bool> _dashboardVisible = {
    for (final key in dashboardKeys) key: true,
  };
  String _userKey = 'guest';
  bool _loaded = false;

  String get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get remindOneDay => _remindOneDay;
  bool get remindThreeDays => _remindThreeDays;
  bool get remindSevenDays => _remindSevenDays;
  bool get trialReminders => _trialReminders;
  bool get priceAlerts => _priceAlerts;
  bool get muted => _muted;
  String get notificationTime => _notificationTime;
  int get reminderDays => _reminderDays;
  String get background => _background;
  String get accent => _accent;
  double get cornerRadius => _cornerRadius;
  bool get compactCards => _compactCards;
  bool get animations => _animations;
  double? get monthlyBudget => _monthlyBudget;
  List<String> get dashboardOrder => List.unmodifiable(_dashboardOrder);
  bool dashboardIsVisible(String key) => _dashboardVisible[key] ?? true;
  bool get loaded => _loaded;
  String get userKey => _userKey;

  Future<void> initializeForUser(String identifier) async {
    _userKey = identifier.trim().toLowerCase().isEmpty
        ? 'guest'
        : identifier.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _resetValues();
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _currency = _string(map, 'currency', 'TRY');
        _notificationsEnabled = map['notificationsEnabled'] as bool? ?? true;
        _remindOneDay = map['remindOneDay'] as bool? ?? false;
        _remindThreeDays = map['remindThreeDays'] as bool? ?? true;
        _remindSevenDays = map['remindSevenDays'] as bool? ?? false;
        _trialReminders = map['trialReminders'] as bool? ?? true;
        _priceAlerts = map['priceAlerts'] as bool? ?? true;
        _muted = map['muted'] as bool? ?? false;
        _notificationTime = _string(map, 'notificationTime', '09:00');
        _reminderDays = map['reminderDays'] as int? ?? 3;
        _background = _string(map, 'background', 'purpleGalaxy');
        _accent = _string(map, 'accent', 'lavender');
        _cornerRadius = (map['cornerRadius'] as num?)?.toDouble() ?? 22;
        _compactCards = map['compactCards'] as bool? ?? false;
        _animations = map['animations'] as bool? ?? true;
        _monthlyBudget = (map['monthlyBudget'] as num?)?.toDouble();
        final order = (map['dashboardOrder'] as List?)
            ?.whereType<String>()
            .toList();
        if (order != null) _dashboardOrder = _normalizeOrder(order);
        final visible = map['dashboardVisible'];
        if (visible is Map) {
          _dashboardVisible = {
            for (final key in dashboardKeys) key: visible[key] as bool? ?? true,
          };
        }
      } catch (_) {
        _resetValues();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  String get _storageKey => 'subtrack.preferences.$_userKey';
  String _string(Map<String, dynamic> map, String key, String fallback) =>
      map[key] is String ? map[key] as String : fallback;

  void _resetValues() {
    _currency = 'TRY';
    _notificationsEnabled = true;
    _remindOneDay = false;
    _remindThreeDays = true;
    _remindSevenDays = false;
    _trialReminders = true;
    _priceAlerts = true;
    _muted = false;
    _notificationTime = '09:00';
    _reminderDays = 3;
    _background = 'purpleGalaxy';
    _accent = 'lavender';
    _cornerRadius = 22;
    _compactCards = false;
    _animations = true;
    _monthlyBudget = null;
    _dashboardOrder = List.of(dashboardKeys);
    _dashboardVisible = {for (final key in dashboardKeys) key: true};
  }

  List<String> _normalizeOrder(List<String> order) => [
    ...order.where(dashboardKeys.contains).toSet(),
    ...dashboardKeys.where((key) => !order.contains(key)),
  ];

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'currency': _currency,
        'notificationsEnabled': _notificationsEnabled,
        'remindOneDay': _remindOneDay,
        'remindThreeDays': _remindThreeDays,
        'remindSevenDays': _remindSevenDays,
        'trialReminders': _trialReminders,
        'priceAlerts': _priceAlerts,
        'muted': _muted,
        'notificationTime': _notificationTime,
        'reminderDays': _reminderDays,
        'background': _background,
        'accent': _accent,
        'cornerRadius': _cornerRadius,
        'compactCards': _compactCards,
        'animations': _animations,
        'monthlyBudget': _monthlyBudget,
        'dashboardOrder': _dashboardOrder,
        'dashboardVisible': _dashboardVisible,
      }),
    );
  }

  void setCurrency(String value) {
    _currency = value;
    _changed();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _changed();
  }

  void setReminderDays(int value) {
    _reminderDays = value;
    _changed();
  }

  void setReminderBefore(int days, bool value) {
    if (days == 1) _remindOneDay = value;
    if (days == 3) _remindThreeDays = value;
    if (days == 7) _remindSevenDays = value;
    _changed();
  }

  bool reminderBefore(int days) => switch (days) {
    1 => _remindOneDay,
    3 => _remindThreeDays,
    7 => _remindSevenDays,
    _ => false,
  };
  void setTrialReminders(bool value) {
    _trialReminders = value;
    _changed();
  }

  void setPriceAlerts(bool value) {
    _priceAlerts = value;
    _changed();
  }

  void setMuted(bool value) {
    _muted = value;
    _changed();
  }

  void setNotificationTime(String value) {
    _notificationTime = value;
    _changed();
  }

  void setBackground(String value) {
    _background = value;
    _changed();
  }

  void setAccent(String value) {
    _accent = value;
    _changed();
  }

  void setCornerRadius(double value) {
    _cornerRadius = value;
    _changed();
  }

  void setCompactCards(bool value) {
    _compactCards = value;
    _changed();
  }

  void setAnimations(bool value) {
    _animations = value;
    _changed();
  }

  void setMonthlyBudget(double? value) {
    _monthlyBudget = value;
    _changed();
  }

  void setDashboardVisible(String key, bool value) {
    if (!dashboardKeys.contains(key)) return;
    _dashboardVisible[key] = value;
    _changed();
  }

  void reorderDashboard(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _dashboardOrder.removeAt(oldIndex);
    _dashboardOrder.insert(newIndex, item);
    _changed();
  }

  void resetDashboard() {
    _dashboardOrder = List.of(dashboardKeys);
    _dashboardVisible = {for (final key in dashboardKeys) key: true};
    _changed();
  }

  void resetAppearance() {
    _background = 'purpleGalaxy';
    _accent = 'lavender';
    _cornerRadius = 22;
    _compactCards = false;
    _animations = true;
    _changed();
  }
}
