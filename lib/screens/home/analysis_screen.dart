import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/subscription.dart';
import '../../services/app_preferences.dart';
import '../../services/currency_service.dart';
import '../../services/payment_record_service.dart';
import '../../services/report_export_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';

enum _AnalysisPeriod { monthly, yearly, all }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  _AnalysisPeriod _period = _AnalysisPeriod.monthly;
  final _service = SubscriptionService.instance;
  final _preferences = AppPreferences.instance;
  final _paymentRecords = PaymentRecordService.instance;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_service, _preferences, _paymentRecords]),
    builder: (context, _) {
      final currency = _preferences.currency;
      final ratesMissing = _service.hasMissingRatesFor(currency);
      final items = _service.subscriptions
          .where((item) => item.isActive)
          .toList();
      final monthly = _service.monthlyTotalInCurrency(currency);
      final yearly = monthly * 12;
      final now = DateTime.now();
      final previousPeriod = switch (_period) {
        _AnalysisPeriod.monthly => _paymentRecords.totalForPeriod(
          DateTime(now.year, now.month - 1),
          DateTime(now.year, now.month),
          currency,
        ),
        _AnalysisPeriod.yearly => _paymentRecords.totalForPeriod(
          DateTime(now.year - 1),
          DateTime(now.year),
          currency,
        ),
        _AnalysisPeriod.all => null,
      };
      final currentEstimate = _period == _AnalysisPeriod.yearly
          ? yearly
          : monthly;
      final allTime = _totalPaidEstimate(_service.subscriptions, currency);
      final total = switch (_period) {
        _AnalysisPeriod.monthly => monthly,
        _AnalysisPeriod.yearly => yearly,
        _AnalysisPeriod.all => allTime,
      };
      final categories = _period == _AnalysisPeriod.all
          ? _allTimeCategories(currency)
          : _service
                .categoryBreakdownInCurrency(currency)
                .map(
                  (key, value) => MapEntry(
                    key,
                    _period == _AnalysisPeriod.yearly ? value * 12 : value,
                  ),
                );
      final categoryTotal = categories.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      final expensive = items.isEmpty
          ? null
          : items.reduce(
              (a, b) => _monthlyCost(a, currency) >= _monthlyCost(b, currency)
                  ? a
                  : b,
            );
      final forecasts = List<double>.generate(
        6,
        (index) => _projectedSpend(index, currency),
      );
      final highestForecast = forecasts.fold<double>(0, math.max);

      return AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Analiz',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Raporu dışa aktar',
                    onSelected: (format) => _export(format, currency),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'csv',
                        child: Text('CSV dışa aktar'),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text('PDF dışa aktar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Abonelik harcamalarının özeti',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: _AnalysisPeriod.values.map((period) {
                  final selected = _period == period;
                  return ChoiceChip(
                    label: Text(_periodLabel(period)),
                    selected: selected,
                    onSelected: (_) => setState(() => _period = period),
                    selectedColor: AppColors.primary.withValues(alpha: .32),
                    backgroundColor: AppColors.surfaceSolid,
                    side: BorderSide(
                      color: AppColors.primary.withValues(
                        alpha: selected ? .8 : .35,
                      ),
                    ),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.lavender : AppColors.muted,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _period == _AnalysisPeriod.all
                          ? 'Tahmini toplam ödeme'
                          : 'Toplam harcama',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ratesMissing
                          ? '— $currency'
                          : '${total.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.lavender,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'Aylık ortalama',
                            value: ratesMissing
                                ? '—'
                                : '${monthly.toStringAsFixed(2)} $currency',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Metric(
                            label: 'Yıllık tahmin',
                            value: ratesMissing
                                ? '—'
                                : '${yearly.toStringAsFixed(2)} $currency',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (previousPeriod != null) ...[
                const SizedBox(height: 10),
                AppCard(
                  child: Text(
                    'Önceki dönemde kaydedilen ödeme: ${previousPeriod.toStringAsFixed(2)} $currency · mevcut tahmine göre ${previousPeriod == 0 ? 'karşılaştırma yok' : '${((currentEstimate - previousPeriod) / previousPeriod * 100).toStringAsFixed(1)}% fark'}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expensive == null
                            ? 'Henüz abonelik yok'
                            : 'En yüksek aylık gider · ${expensive.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (expensive != null)
                      Text(
                        '${_monthlyCost(expensive, currency).toStringAsFixed(2)} $currency',
                        style: const TextStyle(
                          color: AppColors.lavender,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              if (_service.cancelledMonthlySavingsEstimateInCurrency(currency) >
                  0) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'İptal edilen aboneliklerden tahmini tasarruf',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_service.cancelledMonthlySavingsEstimateInCurrency(currency).toStringAsFixed(2)} $currency / ay',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${(_service.cancelledMonthlySavingsEstimateInCurrency(currency) * 12).toStringAsFixed(2)} $currency / yıl',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const AppSectionHeader(title: 'Kategori dağılımı'),
              const SizedBox(height: 10),
              AppCard(
                child: items.isEmpty
                    ? const Text(
                        'Analiz oluşturmak için önce abonelik ekle.',
                        style: TextStyle(color: AppColors.muted),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            width: 138,
                            height: 138,
                            child: CustomPaint(
                              painter: _DonutPainter(
                                values: categories.values.toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categories.entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color:
                                                  _chartColors[categories.keys
                                                          .toList()
                                                          .indexOf(entry.key) %
                                                      _chartColors.length],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${categoryTotal == 0 ? 0 : (entry.value / categoryTotal * 100).round()}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              const AppSectionHeader(title: 'Aylık gider projeksiyonu'),
              const SizedBox(height: 5),
              const Text(
                'Aktif aboneliklerin bugünkü periyotlarına göre tahmin.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: items.isEmpty
                    ? const Text(
                        'Gösterilecek gider yok.',
                        style: TextStyle(color: AppColors.muted),
                      )
                    : SizedBox(
                        height: 175,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(6, (index) {
                            final amount = forecasts[index];
                            final height = highestForecast <= 0
                                ? 2.0
                                : 110 *
                                      (amount / highestForecast).clamp(
                                        .08,
                                        1.0,
                                      );
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      amount.round().toString(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      height: height,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(9),
                                            ),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryLight.withValues(
                                              alpha: .65,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _monthLabel(DateTime.now().month + index),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Abonelik harcamaları',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const AppCard(
                  child: Text(
                    'Abonelik listesi boş.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...items.map(
                  (item) => AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${_periodAmount(item, currency).toStringAsFixed(2)} $currency',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  double _monthlyCost(SubscriptionModel item, String currency) =>
      CurrencyService.convertAmount(
        _service.monthlyEquivalent(item),
        from: item.currency,
        to: currency,
        rates: CurrencyService.instance.rates,
      ) ??
      0;

  Future<void> _export(String format, String currency) async {
    final subscriptions = _service.subscriptions;
    final saved = format == 'csv'
        ? await ReportExportService.instance.exportCsv(
            currency: currency,
            subscriptions: subscriptions,
          )
        : await ReportExportService.instance.exportPdf(
            currency: currency,
            subscriptions: subscriptions,
            monthlyTotal: _service.monthlyTotalInCurrency(currency),
          );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Rapor kaydedildi.' : 'Dışa aktarma iptal edildi.',
        ),
      ),
    );
  }

  double _periodAmount(SubscriptionModel item, String currency) {
    final monthly = _monthlyCost(item, currency);
    return switch (_period) {
      _AnalysisPeriod.monthly => monthly,
      _AnalysisPeriod.yearly => monthly * 12,
      _AnalysisPeriod.all =>
        monthly * _monthsSince(item.startDate ?? item.nextBillingDate),
    };
  }

  double _totalPaidEstimate(List<SubscriptionModel> items, String currency) =>
      items.fold<double>(
        0,
        (sum, item) =>
            sum +
            _monthlyCost(item, currency) *
                _monthsSince(item.startDate ?? item.nextBillingDate),
      );

  Map<String, double> _allTimeCategories(String currency) {
    final result = <String, double>{};
    for (final item in _service.subscriptions) {
      final estimate =
          _monthlyCost(item, currency) *
          _monthsSince(item.startDate ?? item.nextBillingDate);
      result[item.category.label] =
          (result[item.category.label] ?? 0) + estimate;
    }
    return result;
  }

  int _monthsSince(DateTime start) =>
      ((DateTime.now().year - start.year) * 12 +
              DateTime.now().month -
              start.month +
              1)
          .clamp(1, 1200);

  double _projectedSpend(int monthOffset, String currency) =>
      _service.projectedTotalInMonth(
        DateTime(DateTime.now().year, DateTime.now().month + monthOffset),
        currency,
      );

  String _periodLabel(_AnalysisPeriod period) => switch (period) {
    _AnalysisPeriod.monthly => 'Aylık',
    _AnalysisPeriod.yearly => 'Yıllık',
    _AnalysisPeriod.all => 'Tümü',
  };

  String _monthLabel(int month) => const [
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

const _chartColors = [
  AppColors.primary,
  AppColors.primaryLight,
  AppColors.lavender,
];

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(
      center: center,
      radius: math.min(size.width, size.height) / 2 - 8,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      paint.color = _chartColors[i % _chartColors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + .025;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}
