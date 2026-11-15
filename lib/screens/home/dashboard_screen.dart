import 'package:flutter/material.dart';

import '../../models/subscription.dart';
import '../../models/user_profile.dart';
import '../../services/app_preferences.dart';
import '../../services/currency_service.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/service_brand_icon.dart';
import 'notifications_screen.dart';
import 'ocr_screen.dart';
import 'subscription_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.onAddSubscription,
    required this.onShowSubscriptions,
  });
  final UserProfile user;
  final VoidCallback onAddSubscription;
  final VoidCallback onShowSubscriptions;

  @override
  Widget build(BuildContext context) {
    final service = SubscriptionService.instance;
    final prefs = AppPreferences.instance;
    final notifications = NotificationService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([
        service,
        prefs,
        notifications,
        CurrencyService.instance,
      ]),
      builder: (context, _) {
        final currency = prefs.currency;
        final monthly = service.monthlyTotalInCurrency(currency);
        final missingRates = service.hasMissingRatesFor(currency);
        final active = service.subscriptions.where((s) => s.isActive).toList()
          ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
        final categories = service.categoryBreakdownInCurrency(currency);
        final categoryTotal = categories.values.fold<double>(
          0,
          (a, b) => a + b,
        );
        final order = prefs.dashboardOrder
            .where(prefs.dashboardIsVisible)
            .toList();
        final blocks = <String, Widget>{
          'monthly': _MonthlySummary(
            monthly: monthly,
            currency: currency,
            ratesMissing: missingRates,
          ),
          'yearly': _Metric(
            label: 'Yıllık toplam harcama',
            value: missingRates ? '—' : _money(monthly * 12, currency),
            icon: Icons.calendar_month_rounded,
          ),
          'active': _Metric(
            label: 'Aktif abonelik',
            value: '${service.activeCount}',
            icon: Icons.subscriptions_rounded,
          ),
          'upcoming': _Upcoming(
            items: active.take(4).toList(),
            onTap: (item) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionDetailScreen(subscription: item),
              ),
            ),
            onShowAll: onShowSubscriptions,
          ),
          'charts': _Charts(
            categories: categories,
            total: categoryTotal,
            forecast: List.generate(
              6,
              (i) => service.projectedTotalInMonth(
                DateTime(DateTime.now().year, DateTime.now().month + i),
                currency,
              ),
            ),
            currency: currency,
          ),
          'recent': _Recent(
            items: service.subscriptions.take(4).toList(),
            onTap: (item) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionDetailScreen(subscription: item),
              ),
            ),
          ),
        };
        return AppBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SUBTRACK',
                              style: TextStyle(
                                color: AppColors.lavender,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Merhaba, ${user.fullName.split(' ').first}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  if (CurrencyService.instance.rateDate != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Referans kur • ${_date(CurrencyService.instance.rateDate!)}${CurrencyService.instance.isStale ? ' • çevrimdışı önbellek' : ''}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (missingRates)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Kur bulunamadı; dönüştürülmüş toplam eksik olabilir.',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 18),
                  for (final key in order) ...[
                    blocks[key]!,
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 6),
                  AppGradientButton(
                    onPressed: onAddSubscription,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded),
                        SizedBox(width: 8),
                        Text(
                          'Abonelik Ekle',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    height: 48,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OcrScreen()),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Belge Tara / OCR'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _money(double n, String c) => '${n.toStringAsFixed(2)} $c';
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({
    required this.monthly,
    required this.currency,
    required this.ratesMissing,
  });
  final double monthly;
  final String currency;
  final bool ratesMissing;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
      ),
      borderRadius: BorderRadius.circular(AppPreferences.instance.cornerRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .3),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aylık toplam harcama',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          ratesMissing
              ? '— $currency'
              : '${monthly.toStringAsFixed(2)} $currency',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Tahmini karşılık • referans kuruyla',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(icon, color: AppColors.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ],
    ),
  );
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({
    required this.items,
    required this.onTap,
    required this.onShowAll,
  });
  final List<SubscriptionModel> items;
  final ValueChanged<SubscriptionModel> onTap;
  final VoidCallback onShowAll;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSectionHeader(
        title: 'Yaklaşan ödemeler',
        actionLabel: 'Tümünü gör',
        onAction: onShowAll,
      ),
      if (items.isEmpty)
        const AppCard(
          child: Text(
            'Yaklaşan ödeme yok.',
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else
        ...items.map((item) {
          final days = item.nextBillingDate.difference(DateTime.now()).inDays;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => onTap(item),
              leading: ServiceBrandIcon(serviceName: item.name, size: 42),
              title: Text(item.name),
              subtitle: Text(
                '${days <= 0 ? 'Bugün' : '$days gün kaldı'} · ${item.currency} ${item.amount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              trailing: Text(
                '${item.amount.toStringAsFixed(2)} ${item.currency}',
                style: const TextStyle(
                  color: AppColors.lavender,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
    ],
  );
}

class _Charts extends StatelessWidget {
  const _Charts({
    required this.categories,
    required this.total,
    required this.forecast,
    required this.currency,
  });
  final Map<String, double> categories;
  final double total;
  final List<double> forecast;
  final String currency;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSectionHeader(title: 'Kategori bazlı harcama'),
      AppCard(
        child: categories.isEmpty
            ? const Text(
                'Harcama verisi eklendikçe burada görünür.',
                style: TextStyle(color: AppColors.muted),
              )
            : Column(
                children: [
                  for (final entry in categories.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(2)} $currency',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: total <= 0 ? 0 : entry.value / total,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceAlt,
                            color: AppColors.primaryLight,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      const SizedBox(height: 14),
      const AppSectionHeader(title: 'Yaklaşan 6 ayın gideri'),
      AppCard(
        child: SizedBox(
          height: 115,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < forecast.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          forecast[i].round().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: forecast.reduce((a, b) => a > b ? a : b) == 0
                              ? 3
                              : 65 *
                                    forecast[i] /
                                    forecast.reduce((a, b) => a > b ? a : b),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _month(DateTime.now().month + i),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
  String _month(int month) => const [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ][(month - 1) % 12];
}

class _Recent extends StatelessWidget {
  const _Recent({required this.items, required this.onTap});
  final List<SubscriptionModel> items;
  final ValueChanged<SubscriptionModel> onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSectionHeader(title: 'Son eklenen abonelikler'),
      if (items.isEmpty)
        const AppCard(child: Text('Henüz abonelik eklenmedi.'))
      else
        ...items.map(
          (item) => AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => onTap(item),
              leading: ServiceBrandIcon(serviceName: item.name, size: 40),
              title: Text(item.name),
              subtitle: Text(
                '${item.amount.toStringAsFixed(2)} ${item.currency} · ${item.billingCycle}',
              ),
            ),
          ),
        ),
    ],
  );
}
