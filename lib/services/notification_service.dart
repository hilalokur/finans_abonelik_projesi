import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/subscription.dart';
import 'app_preferences.dart';
import 'subscription_service.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._() {
    SubscriptionService.instance.addListener(_refresh);
    AppPreferences.instance.addListener(_refresh);
  }

  static final NotificationService instance = NotificationService._();

  final List<AppNotification> _events = [];
  final Set<String> _readRenewalIds = {};

  void _refresh() => notifyListeners();

  List<AppNotification> get notifications {
    final preferences = AppPreferences.instance;
    if (!preferences.notificationsEnabled || preferences.muted) return const [];
    final renewals = SubscriptionService.instance.subscriptions
        .where((item) => item.isActive)
        .where((item) {
          final days = item.nextBillingDate.difference(DateTime.now()).inDays;
          return days >= 0 &&
              [
                1,
                3,
                7,
              ].any((lead) => days <= lead && preferences.reminderBefore(lead));
        })
        .map((item) {
          final days = item.nextBillingDate.difference(DateTime.now()).inDays;
          final id =
              'renewal-${item.id}-${item.nextBillingDate.toIso8601String()}';
          return AppNotification(
            id: id,
            title: 'Yaklaşan ödeme: ${item.name}',
            message: days == 0
                ? 'Ödeme bugün yenileniyor · ${item.amount.toStringAsFixed(2)} ${item.currency}'
                : '$days gün içinde yenileniyor · ${item.amount.toStringAsFixed(2)} ${item.currency}',
            type: AppNotificationType.renewal,
            createdAt: item.nextBillingDate,
            subscriptionId: item.id,
            isRead: _readRenewalIds.contains(id),
          );
        });
    final subscriptions = SubscriptionService.instance.subscriptions;
    final trials = preferences.trialReminders
        ? subscriptions
              .where((item) => item.trialEndDate != null)
              .where((item) {
                final days = item.trialEndDate!
                    .difference(DateTime.now())
                    .inDays;
                return days >= 0 && days <= 7;
              })
              .map((item) {
                final days = item.trialEndDate!
                    .difference(DateTime.now())
                    .inDays;
                return AppNotification(
                  id: 'trial-${item.id}-${item.trialEndDate!.toIso8601String()}',
                  title: 'Ücretsiz deneme sona eriyor: ${item.name}',
                  message: days == 0
                      ? 'Deneme bugün bitiyor.'
                      : '$days gün sonra bitiyor.',
                  type: AppNotificationType.trial,
                  createdAt: item.trialEndDate!,
                  subscriptionId: item.id,
                );
              })
        : <AppNotification>[];
    final priceAlerts = preferences.priceAlerts
        ? subscriptions.where((item) => item.priceChanges.isNotEmpty).map((
            item,
          ) {
            final change = item.priceChanges.last;
            return AppNotification(
              id: 'price-${item.id}-${change.changedAt.toIso8601String()}',
              title: 'Fiyat değişikliği: ${item.name}',
              message:
                  '${change.oldAmount.toStringAsFixed(2)} → ${change.newAmount.toStringAsFixed(2)} ${change.currency}',
              type: AppNotificationType.priceChange,
              createdAt: change.changedAt,
              subscriptionId: item.id,
            );
          })
        : <AppNotification>[];
    final budget = preferences.monthlyBudget;
    final spent = SubscriptionService.instance.monthlyTotalInCurrency(
      preferences.currency,
    );
    final budgetAlerts = budget != null && budget > 0 && spent >= budget * .8
        ? [
            AppNotification(
              id: 'budget-${DateTime.now().year}-${DateTime.now().month}',
              title: 'Aylık bütçe uyarısı',
              message:
                  'Harcama ${spent.toStringAsFixed(2)} ${preferences.currency}; bütçenin ${(spent / budget * 100).round()}% seviyesinde.',
              type: AppNotificationType.budget,
              createdAt: DateTime.now(),
            ),
          ]
        : <AppNotification>[];
    final all =
        [..._events, ...renewals, ...trials, ...priceAlerts, ...budgetAlerts]
          ..sort((a, b) {
            if (a.type == AppNotificationType.renewal &&
                b.type == AppNotificationType.renewal) {
              return a.createdAt.compareTo(b.createdAt);
            }
            return b.createdAt.compareTo(a.createdAt);
          });
    return List.unmodifiable(all);
  }

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  void subscriptionAdded(SubscriptionModel item) => _add(
    AppNotification(
      id: 'added-${item.id}',
      title: 'Abonelik eklendi',
      message: '${item.name} aboneliği listene eklendi.',
      type: AppNotificationType.subscriptionAdded,
      createdAt: DateTime.now(),
      subscriptionId: item.id,
    ),
  );

  void paymentCompleted(SubscriptionModel item) => _add(
    AppNotification(
      id: 'paid-${item.id}-${DateTime.now().microsecondsSinceEpoch}',
      title: 'Ödeme tamamlandı',
      message:
          '${item.name} için ${item.amount.toStringAsFixed(2)} ${item.currency} ödendi olarak işaretlendi.',
      type: AppNotificationType.paymentCompleted,
      createdAt: DateTime.now(),
      subscriptionId: item.id,
    ),
  );

  void _add(AppNotification notification) {
    _events.insert(0, notification);
    notifyListeners();
  }

  void markRead(AppNotification notification) {
    if (notification.type == AppNotificationType.renewal) {
      _readRenewalIds.add(notification.id);
    } else {
      final index = _events.indexWhere((item) => item.id == notification.id);
      if (index >= 0) _events[index] = _events[index].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void markAllRead() {
    for (final notification in notifications) {
      if (notification.type == AppNotificationType.renewal) {
        _readRenewalIds.add(notification.id);
      } else {
        final index = _events.indexWhere((item) => item.id == notification.id);
        if (index >= 0) _events[index] = _events[index].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }
}
