import 'package:flutter/material.dart';

import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/service_brand_icon.dart';
import 'subscription_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  final _service = SubscriptionService.instance;

  void _changeMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);
      final lastDay = DateUtils.getDaysInMonth(_month.year, _month.month);
      _selectedDate = DateTime(
        _month.year,
        _month.month,
        _selectedDate.day.clamp(1, lastDay),
      );
    });
  }

  List<SubscriptionModel> _paymentsFor(DateTime day) => _service.subscriptions
      .where((item) => item.isActive)
      .where((item) => _nextDateInMonth(item, _month)?.day == day.day)
      .toList();

  DateTime? _nextDateInMonth(SubscriptionModel item, DateTime month) {
    var date = DateUtils.dateOnly(item.nextBillingDate);
    final first = DateTime(month.year, month.month);
    final afterLast = DateTime(month.year, month.month + 1);
    for (var guard = 0; guard < 500 && date.isBefore(first); guard++) {
      date = _advance(date, item.billingCycle);
    }
    if (!date.isBefore(afterLast) || date.isBefore(first)) return null;
    return date;
  }

  DateTime _advance(DateTime date, String cycle) {
    final normalized = cycle.toLowerCase();
    if (normalized.contains('hafta') || normalized.contains('week')) {
      return date.add(const Duration(days: 7));
    }
    if (normalized.contains('gün') || normalized.contains('day')) {
      return date.add(const Duration(days: 1));
    }
    final annual = normalized.contains('yıl') || normalized.contains('year');
    final target = DateTime(date.year, date.month + (annual ? 12 : 1), 1);
    final day = date.day.clamp(
      1,
      DateUtils.getDaysInMonth(target.year, target.month),
    );
    return DateTime(target.year, target.month, day);
  }

  @override
  Widget build(BuildContext context) => AppBackground(
    child: SafeArea(
      child: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          final selectedPayments = _paymentsFor(_selectedDate);
          final upcoming =
              _service.subscriptions
                  .where(
                    (item) =>
                        item.isActive &&
                        !item.nextBillingDate.isBefore(DateTime.now()),
                  )
                  .toList()
                ..sort(
                  (a, b) => a.nextBillingDate.compareTo(b.nextBillingDate),
                );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              const Text(
                'Ödeme Takvimi',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Yenileme günlerini ay görünümünde takip et.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: 'Önceki ay',
                        ),
                        Expanded(
                          child: Text(
                            '${_monthName(_month.month)} ${_month.year}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: 'Sonraki ay',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children:
                          const [
                                'Pzt',
                                'Sal',
                                'Çar',
                                'Per',
                                'Cum',
                                'Cmt',
                                'Paz',
                              ]
                              .map(
                                (day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                    _monthGrid(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${_selectedDate.day} ${_monthName(_selectedDate.month)} ödemeleri',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (selectedPayments.isEmpty)
                const AppCard(
                  child: Text(
                    'Bu tarihte planlı ödeme yok.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...selectedPayments.map(
                  (item) =>
                      _paymentCard(item, date: _nextDateInMonth(item, _month)),
                ),
              const SizedBox(height: 18),
              const Text(
                'Yaklaşan ödemeler',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                const AppCard(
                  child: Text(
                    'Yaklaşan ödeme bulunmuyor.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...upcoming.take(5).map(_paymentCard),
            ],
          );
        },
      ),
    ),
  );

  Widget _monthGrid() {
    final firstDay = DateTime(_month.year, _month.month);
    final startOffset = firstDay.weekday - 1;
    final gridStart = firstDay.subtract(Duration(days: startOffset));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final date = gridStart.add(Duration(days: index));
        final isCurrentMonth = date.month == _month.month;
        final isSelected = DateUtils.isSameDay(date, _selectedDate);
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        final hasPayment = isCurrentMonth && _paymentsFor(date).isNotEmpty;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isCurrentMonth
              ? () => setState(() => _selectedDate = date)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: .38)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected || isToday
                    ? AppColors.primaryLight.withValues(alpha: .7)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isCurrentMonth
                        ? AppColors.text
                        : AppColors.muted.withValues(alpha: .4),
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: hasPayment
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: hasPayment
                        ? [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(
                                alpha: .6,
                              ),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _paymentCard(SubscriptionModel item, {DateTime? date}) => AppCard(
    margin: const EdgeInsets.only(bottom: 10),
    padding: EdgeInsets.zero,
    child: ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionDetailScreen(subscription: item),
        ),
      ),
      leading: ServiceBrandIcon(serviceName: item.name, size: 44),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${(date ?? item.nextBillingDate).day.toString().padLeft(2, '0')}.${(date ?? item.nextBillingDate).month.toString().padLeft(2, '0')}.${(date ?? item.nextBillingDate).year} · ${item.billingCycle}',
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: Text(
        '${item.amount.toStringAsFixed(2)} ${item.currency}',
        style: const TextStyle(
          color: AppColors.lavender,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  String _monthName(int month) => const [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ][month - 1];
}
