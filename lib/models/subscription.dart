import 'package:flutter/material.dart';

enum SubscriptionCategory {
  entertainment,
  music,
  cloud,
  productivity,
  fitness,
  gaming,
  education,
  shopping,
  other,
}

extension SubscriptionCategoryLabel on SubscriptionCategory {
  String get label => switch (this) {
    SubscriptionCategory.entertainment => 'Video',
    SubscriptionCategory.music => 'Müzik',
    SubscriptionCategory.cloud => 'Bulut Depolama',
    SubscriptionCategory.productivity => 'Üretkenlik',
    SubscriptionCategory.fitness => 'Sağlık',
    SubscriptionCategory.gaming => 'Oyun',
    SubscriptionCategory.education => 'Eğitim',
    SubscriptionCategory.shopping => 'Alışveriş',
    SubscriptionCategory.other => 'Diğer',
  };
}

class SubscriptionPriceChange {
  const SubscriptionPriceChange({
    required this.oldAmount,
    required this.newAmount,
    required this.currency,
    required this.changedAt,
  });
  final double oldAmount;
  final double newAmount;
  final String currency;
  final DateTime changedAt;
  double get difference => newAmount - oldAmount;
  Map<String, dynamic> toMap() => {
    'oldAmount': oldAmount,
    'newAmount': newAmount,
    'currency': currency,
    'changedAt': changedAt.toIso8601String(),
  };
  factory SubscriptionPriceChange.fromMap(Map<String, dynamic> map) =>
      SubscriptionPriceChange(
        oldAmount: (map['oldAmount'] as num).toDouble(),
        newAmount: (map['newAmount'] as num).toDouble(),
        currency: map['currency'] as String,
        changedAt: DateTime.parse(map['changedAt'] as String),
      );
}

class SubscriptionModel {
  final String id, name, service, currency, billingCycle, logoText, description;
  final SubscriptionCategory category;
  final String? customCategory;
  final double amount;
  final DateTime nextBillingDate;
  final Color accentColor;
  final bool isActive;
  final DateTime? startDate, trialStartDate, trialEndDate;
  final List<SubscriptionPriceChange> priceChanges;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.service,
    required this.category,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.logoText,
    required this.accentColor,
    this.isActive = true,
    this.startDate,
    this.description = '',
    this.customCategory,
    this.trialStartDate,
    this.trialEndDate,
    this.priceChanges = const [],
  });

  String get categoryName => customCategory?.trim().isNotEmpty == true
      ? customCategory!.trim()
      : category.label;

  SubscriptionModel copyWith({
    String? name,
    String? service,
    SubscriptionCategory? category,
    double? amount,
    String? currency,
    String? billingCycle,
    DateTime? nextBillingDate,
    String? logoText,
    bool? isActive,
    DateTime? startDate,
    String? description,
    String? customCategory,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    List<SubscriptionPriceChange>? priceChanges,
  }) => SubscriptionModel(
    id: id,
    name: name ?? this.name,
    service: service ?? this.service,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    billingCycle: billingCycle ?? this.billingCycle,
    nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    logoText: logoText ?? this.logoText,
    accentColor: accentColor,
    isActive: isActive ?? this.isActive,
    startDate: startDate ?? this.startDate,
    description: description ?? this.description,
    customCategory: customCategory ?? this.customCategory,
    trialStartDate: trialStartDate ?? this.trialStartDate,
    trialEndDate: trialEndDate ?? this.trialEndDate,
    priceChanges: priceChanges ?? this.priceChanges,
  );

  factory SubscriptionModel.fromMap(
    Map<String, dynamic> map,
  ) => SubscriptionModel(
    id: map['id'] as String,
    name: map['name'] as String,
    service: map['service'] as String,
    category: SubscriptionCategory.values.firstWhere(
      (item) => item.name == map['category'],
      orElse: () => SubscriptionCategory.other,
    ),
    amount: (map['amount'] as num).toDouble(),
    currency: map['currency'] as String? ?? 'TRY',
    billingCycle: map['billingCycle'] as String? ?? 'Aylık',
    nextBillingDate: DateTime.parse(map['nextBillingDate'] as String),
    logoText: map['logoText'] as String? ?? 'S',
    accentColor: Color(
      int.tryParse(map['accentColor'] as String? ?? 'ff8b5cf6', radix: 16) ??
          0xff8b5cf6,
    ),
    isActive: map['isActive'] as bool? ?? true,
    startDate: map['startDate'] == null
        ? null
        : DateTime.parse(map['startDate'] as String),
    description: map['description'] as String? ?? '',
    customCategory: map['customCategory'] as String?,
    trialStartDate: map['trialStartDate'] == null
        ? null
        : DateTime.parse(map['trialStartDate'] as String),
    trialEndDate: map['trialEndDate'] == null
        ? null
        : DateTime.parse(map['trialEndDate'] as String),
    priceChanges: ((map['priceChanges'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              SubscriptionPriceChange.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'service': service,
    'category': category.name,
    'amount': amount,
    'currency': currency,
    'billingCycle': billingCycle,
    'nextBillingDate': nextBillingDate.toIso8601String(),
    'logoText': logoText,
    'accentColor': accentColor.toARGB32().toRadixString(16).padLeft(8, '0'),
    'isActive': isActive,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    'description': description,
    if (customCategory != null) 'customCategory': customCategory,
    if (trialStartDate != null)
      'trialStartDate': trialStartDate!.toIso8601String(),
    if (trialEndDate != null) 'trialEndDate': trialEndDate!.toIso8601String(),
    'priceChanges': priceChanges.map((change) => change.toMap()).toList(),
  };
}
