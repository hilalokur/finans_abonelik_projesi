// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';

import '../../models/subscription.dart';
import '../../services/notification_service.dart';
import '../../services/app_preferences.dart';
import '../../services/currency_service.dart';
import '../../services/payment_record_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/service_brand_icon.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  const SubscriptionDetailScreen({super.key, required this.subscription});

  final SubscriptionModel subscription;

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  late SubscriptionModel _item = widget.subscription;
  List<PaymentRecord> _payments = const [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    await PaymentRecordService.instance.load();
    if (mounted)
      setState(
        () =>
            _payments = PaymentRecordService.instance.forSubscription(_item.id),
      );
  }

  Future<void> _edit() async {
    final nameController = TextEditingController(text: _item.name);
    final amountController = TextEditingController(
      text: _item.amount.toStringAsFixed(2),
    );
    final result = await showDialog<(String, double)?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aboneliği düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Abonelik adı'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Tutar (${_item.currency})',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          AppGradientButton(
            width: 118,
            height: 42,
            onPressed: () {
              final value = double.tryParse(
                amountController.text.trim().replaceAll(',', '.'),
              );
              final name = nameController.text.trim();
              if (value != null && value > 0 && name.isNotEmpty) {
                Navigator.pop(dialogContext, (name, value));
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    nameController.dispose();
    amountController.dispose();
    if (result == null || !mounted) return;
    final updated = _item.copyWith(
      name: result.$1,
      service: result.$1,
      amount: result.$2,
      logoText: result.$1
          .substring(0, result.$1.length > 1 ? 2 : 1)
          .toUpperCase(),
    );
    SubscriptionService.instance.updateSubscription(updated);
    setState(() => _item = updated);
  }

  Future<void> _delete() async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Aboneliği sil?',
      message: '${_item.name} aboneliği kalıcı olarak listeden kaldırılacak.',
      confirmLabel: 'Sil',
    );
    if (confirmed != true || !mounted) return;
    SubscriptionService.instance.removeSubscription(_item.id);
    Navigator.pop(context);
  }

  void _toggleActive() {
    final updated = _item.copyWith(isActive: !_item.isActive);
    SubscriptionService.instance.updateSubscription(updated);
    setState(() => _item = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isActive
              ? 'Abonelik yeniden etkinleştirildi.'
              : 'Abonelik iptal edildi olarak işaretlendi.',
        ),
      ),
    );
  }

  Future<void> _markPaid() async {
    final paid = _item;
    final record = await PaymentRecordService.instance.record(paid);
    if (!mounted) return;
    final updated = _item.copyWith(
      nextBillingDate: _advanceDate(_item.nextBillingDate, _item.billingCycle),
    );
    SubscriptionService.instance.updateSubscription(updated);
    setState(() => _item = updated);
    NotificationService.instance.paymentCompleted(paid);
    if (mounted) setState(() => _payments = [..._payments, record]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ödeme tamamlandı bildirimi eklendi.')),
    );
  }

  DateTime _advanceDate(DateTime date, String cycle) {
    final normalized = cycle.toLowerCase();
    if (normalized.contains('hafta') || normalized.contains('week')) {
      return date.add(const Duration(days: 7));
    }
    if (normalized.contains('gün') || normalized.contains('day')) {
      return date.add(const Duration(days: 1));
    }
    final yearly = normalized.contains('yıl') || normalized.contains('year');
    final target = DateTime(date.year, date.month + (yearly ? 12 : 1), 1);
    final day = date.day
        .clamp(1, DateUtils.getDaysInMonth(target.year, target.month))
        .toInt();
    return DateTime(target.year, target.month, day);
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _item.startDate ?? _item.nextBillingDate;
    final months =
        ((DateTime.now().year - startDate.year) * 12 +
                DateTime.now().month -
                startDate.month +
                1)
            .clamp(1, 1200);
    final paidEstimate =
        SubscriptionService.instance.monthlyEquivalent(_item) * months;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelik Detayı'),
        actions: [
          IconButton(
            onPressed: _edit,
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _delete,
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              AppCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    ServiceBrandIcon(serviceName: _item.name, size: 84),
                    const SizedBox(height: 16),
                    Text(
                      _item.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _item.isActive ? 'Aktif abonelik' : 'İptal edildi',
                      style: TextStyle(
                        color: _item.isActive
                            ? AppColors.primaryLight
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${_item.amount.toStringAsFixed(2)} ${_item.currency}',
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lavender,
                      ),
                    ),
                    Text(
                      '/ ${_item.billingCycle}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (CurrencyService.normalizeCurrency(_item.currency) !=
                        AppPreferences.instance.currency) ...[
                      const SizedBox(height: 8),
                      Text(
                        CurrencyService.instance.convert(
                                  _item.amount,
                                  from: _item.currency,
                                  to: AppPreferences.instance.currency,
                                ) ==
                                null
                            ? 'Dönüştürülmüş tutar için kur bulunamadı.'
                            : 'Yaklaşık ${CurrencyService.instance.convert(_item.amount, from: _item.currency, to: AppPreferences.instance.currency)!.toStringAsFixed(2)} ${AppPreferences.instance.currency} · referans kuru',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (CurrencyService.instance.rateDate != null)
                        Text(
                          'Kur tarihi: ${_formatDate(CurrencyService.instance.rateDate!)}${CurrencyService.instance.isStale ? ' · eski önbellek' : ''}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Bir sonraki ödeme',
                      value: _formatDate(_item.nextBillingDate),
                    ),
                    _DetailRow(
                      label: 'Fatura periyodu',
                      value: _item.billingCycle,
                    ),
                    _DetailRow(label: 'Kategori', value: _item.categoryName),
                    _DetailRow(
                      label: 'Başlangıç tarihi',
                      value: _formatDate(startDate),
                    ),
                    _DetailRow(
                      label: 'Tahmini toplam ödeme',
                      value:
                          '${paidEstimate.toStringAsFixed(2)} ${_item.currency}',
                    ),
                    if (_item.trialEndDate != null)
                      _DetailRow(
                        label: 'Ücretsiz deneme bitişi',
                        value: _formatDate(_item.trialEndDate!),
                      ),
                    if (_item.priceChanges.isNotEmpty)
                      _DetailRow(
                        label: 'Son fiyat değişikliği',
                        value:
                            '${_item.priceChanges.last.oldAmount.toStringAsFixed(2)} → ${_item.priceChanges.last.newAmount.toStringAsFixed(2)} ${_item.priceChanges.last.currency}',
                      ),
                  ],
                ),
              ),
              if (_payments.isNotEmpty) ...[
                const SizedBox(height: 16),
                const AppSectionHeader(title: 'Geçmiş ödemeler'),
                AppCard(
                  child: Column(
                    children: [
                      for (final payment in _payments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${payment.originalAmount.toStringAsFixed(2)} ${payment.originalCurrency}',
                          ),
                          subtitle: Text(
                            '${_formatDate(payment.paidAt)}${payment.convertedAmount == null ? '' : ' · ${payment.convertedAmount!.toStringAsFixed(2)} ${payment.displayCurrency}'}',
                          ),
                          trailing: payment.exchangeRateUsed == null
                              ? null
                              : const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 17,
                                ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppGradientButton(
                onPressed: _markPaid,
                child: const Text('Ödemeyi tamamlandı olarak işaretle'),
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                onPressed: _toggleActive,
                child: Text(
                  _item.isActive
                      ? 'İptal edildi olarak işaretle'
                      : 'Yeniden etkinleştir',
                ),
              ),
              if (_item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                AppCard(
                  child: Text(
                    _item.description,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
