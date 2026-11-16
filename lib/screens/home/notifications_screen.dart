import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../models/subscription.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/service_brand_icon.dart';
import 'subscription_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          TextButton(
            onPressed: notifications.markAllRead,
            child: const Text('Tümünü oku'),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: notifications,
            builder: (context, _) {
              final items = notifications.notifications;
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: AppEmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'Şimdilik bildirim yok',
                      message:
                          'Yeni abonelik ve ödeme hatırlatmaları burada görünecek.',
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final model = item.subscriptionId == null
                      ? null
                      : _findSubscription(item.subscriptionId!);
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        notifications.markRead(item);
                        if (model != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SubscriptionDetailScreen(subscription: model),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            if (model != null)
                              ServiceBrandIcon(
                                serviceName: model.name,
                                size: 44,
                              )
                            else
                              _notificationIcon(item.type),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: item.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.message,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _dateTime(item.createdAt),
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!item.isRead)
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: AppColors.primaryLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  SubscriptionModel? _findSubscription(String id) {
    for (final item in SubscriptionService.instance.subscriptions) {
      if (item.id == id) return item;
    }
    return null;
  }

  Widget _notificationIcon(AppNotificationType type) {
    final icon = switch (type) {
      AppNotificationType.renewal => Icons.alarm_rounded,
      AppNotificationType.subscriptionAdded => Icons.add_circle_outline_rounded,
      AppNotificationType.paymentCompleted =>
        Icons.check_circle_outline_rounded,
      AppNotificationType.trial => Icons.hourglass_bottom_rounded,
      AppNotificationType.priceChange => Icons.price_change_rounded,
      AppNotificationType.budget => Icons.account_balance_wallet_outlined,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primaryLight),
    );
  }

  String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
