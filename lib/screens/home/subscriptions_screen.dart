import 'package:flutter/material.dart';

import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/service_brand_icon.dart';
import 'subscription_detail_screen.dart';

enum _SubscriptionFilter { all, active, upcoming, cancelled }

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final service = SubscriptionService.instance;
  final _searchController = TextEditingController();
  String _query = '';
  _SubscriptionFilter _filter = _SubscriptionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editAmount(SubscriptionModel item) async {
    final controller = TextEditingController(
      text: item.amount.toStringAsFixed(2),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${item.name} ücretini düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Tutar (${item.currency})'),
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
                controller.text.trim().replaceAll(',', '.'),
              );
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null) {
      service.updateSubscription(item.copyWith(amount: amount));
    }
  }

  Future<void> _delete(SubscriptionModel item) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Aboneliği sil?',
      message: '${item.name} listeden kaldırılacak.',
      confirmLabel: 'Sil',
    );
    if (confirmed == true) {
      service.removeSubscription(item.id);
    }
  }

  List<SubscriptionModel> _filtered(List<SubscriptionModel> source) {
    final now = DateTime.now();
    final query = _query.trim().toLowerCase();
    return source.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.service.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        _SubscriptionFilter.all => true,
        _SubscriptionFilter.active => item.isActive,
        _SubscriptionFilter.upcoming =>
          item.isActive &&
              !item.nextBillingDate.isBefore(now) &&
              item.nextBillingDate.difference(now).inDays <= 30,
        _SubscriptionFilter.cancelled => !item.isActive,
      };
      return matchesQuery && matchesFilter;
    }).toList()..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  @override
  Widget build(BuildContext context) => AppBackground(
    child: SafeArea(
      child: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final items = _filtered(service.subscriptions);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'Aboneliklerim',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Bütün yenilemelerini tek yerden yönet.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: AppTextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  hintText: 'Abonelik ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _SubscriptionFilter.values.map((filter) {
                    final selected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterLabel(filter)),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppColors.primaryLight.withValues(
                          alpha: .3,
                        ),
                        backgroundColor: AppColors.surfaceSolid,
                        side: BorderSide(
                          color: AppColors.primaryLight.withValues(
                            alpha: selected ? .8 : .35,
                          ),
                        ),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.lavender
                              : AppColors.muted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: AppEmptyState(
                            title: service.subscriptions.isEmpty
                                ? 'Henüz abonelik eklenmemiş.'
                                : 'Bu filtrede abonelik bulunamadı.',
                            icon: Icons.subscriptions_outlined,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _subscriptionCard(items[index]),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _subscriptionCard(SubscriptionModel item) => AppCard(
    margin: const EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionDetailScreen(subscription: item),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ServiceBrandIcon(serviceName: item.name, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category.label} · ${item.billingCycle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${item.nextBillingDate.day.toString().padLeft(2, '0')}.${item.nextBillingDate.month.toString().padLeft(2, '0')}.${item.nextBillingDate.year} · ${item.isActive ? 'Aktif' : 'İptal'}',
                    style: TextStyle(
                      color: item.isActive
                          ? AppColors.primaryLight
                          : AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.amount.toStringAsFixed(2)} ${item.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _editAmount(item),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                      tooltip: 'Ücreti düzenle',
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _delete(item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.lavender,
                        size: 20,
                      ),
                      tooltip: 'Sil',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  String _filterLabel(_SubscriptionFilter filter) => switch (filter) {
    _SubscriptionFilter.all => 'Tümü',
    _SubscriptionFilter.active => 'Aktif',
    _SubscriptionFilter.upcoming => 'Yakında',
    _SubscriptionFilter.cancelled => 'İptal',
  };
}
