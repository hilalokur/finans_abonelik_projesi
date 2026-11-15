import 'package:flutter/foundation.dart';

enum AppNotificationType {
  renewal,
  subscriptionAdded,
  paymentCompleted,
  trial,
  priceChange,
  budget,
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.subscriptionId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final DateTime createdAt;
  final String? subscriptionId;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    createdAt: createdAt,
    subscriptionId: subscriptionId,
    isRead: isRead ?? this.isRead,
  );
}
