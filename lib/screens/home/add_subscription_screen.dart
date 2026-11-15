// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';

import '../../models/subscription.dart';
import '../../services/notification_service.dart';
import '../../services/category_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';
import '../../widgets/subscription_service_picker.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({
    super.key,
    this.initialServiceName,
    this.initialAmount,
    this.initialCurrency,
    this.initialRenewalDate,
    this.initialDescription,
  });

  final String? initialServiceName;
  final double? initialAmount;
  final String? initialCurrency;
  final DateTime? initialRenewalDate;
  final String? initialDescription;

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _serviceController = TextEditingController();
  final _descriptionController = TextEditingController();
  SubscriptionCategory _category = SubscriptionCategory.entertainment;
  String _currency = 'TRY';
  String _billingCycle = 'Aylık';
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 15));
  DateTime? _trialEndDate;
  List<String> _userCategories = const [
    'Video',
    'Müzik',
    'Oyun',
    'Eğitim',
    'Alışveriş',
    'Bulut Depolama',
    'Diğer',
  ];
  String _categoryName = 'Video';

  @override
  void initState() {
    super.initState();
    CategoryService.instance.load().then((_) {
      if (mounted) {
        setState(() => _userCategories = CategoryService.instance.names);
      }
    });
    final serviceName = widget.initialServiceName?.trim();
    if (serviceName != null && serviceName.isNotEmpty) {
      _serviceController.text = serviceName;
      _nameController.text = serviceName;
      final normalized = serviceName.toLowerCase();
      if (normalized.contains('spotify') || normalized.contains('music')) {
        _category = SubscriptionCategory.music;
      } else if (normalized.contains('xbox') ||
          normalized.contains('playstation')) {
        _category = SubscriptionCategory.gaming;
      } else if (normalized.contains('netflix') ||
          normalized.contains('youtube') ||
          normalized.contains('disney') ||
          normalized.contains('video') ||
          normalized.contains('exxen') ||
          normalized.contains('blutv') ||
          normalized.contains('gain')) {
        _category = SubscriptionCategory.entertainment;
      } else {
        _category = SubscriptionCategory.other;
      }
    }
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    _currency = widget.initialCurrency ?? 'TRY';
    _nextBillingDate = widget.initialRenewalDate ?? _nextBillingDate;
    _descriptionController.text = widget.initialDescription ?? '';
    _categoryName = _category.label;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _serviceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickRenewalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _nextBillingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Yenilenme tarihini seç',
    );
    if (picked != null && mounted) {
      setState(() => _nextBillingDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_serviceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir abonelik servisi seç.')),
      );
      return;
    }
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) return;

    final item = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      service: _serviceController.text.trim().isEmpty
          ? _nameController.text.trim()
          : _serviceController.text.trim(),
      category: _category,
      customCategory:
          _userCategories.contains(_categoryName) &&
              _categoryName != _category.label
          ? _categoryName
          : null,
      amount: amount,
      currency: _currency,
      billingCycle: _billingCycle,
      nextBillingDate: _nextBillingDate,
      startDate: DateTime.now(),
      description: _descriptionController.text.trim(),
      trialStartDate: _trialEndDate == null ? null : DateTime.now(),
      trialEndDate: _trialEndDate,
      logoText: _nameController.text.trim().length > 1
          ? _nameController.text.trim().substring(0, 2).toUpperCase()
          : _nameController.text.trim().toUpperCase(),
      accentColor: const Color(0xFF8B5CF6),
    );

    SubscriptionService.instance.addSubscription(item);
    NotificationService.instance.subscriptionAdded(item);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} aboneliği eklendi.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Abonelik'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: AppBackground(
        imagePath: 'assets/images/4.jpg',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    'Servis',
                    style: TextStyle(
                      color: Color(0xFFB8B2CC),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SubscriptionServicePicker(
                    selectedName: _serviceController.text.isEmpty
                        ? null
                        : _serviceController.text,
                    onSelected: (selection) {
                      setState(() {
                        _serviceController.text = selection.name;
                        _nameController.text = selection.name;
                        _category = switch (selection.category) {
                          ServiceCatalogCategory.all =>
                            SubscriptionCategory.entertainment,
                          ServiceCatalogCategory.video =>
                            SubscriptionCategory.entertainment,
                          ServiceCatalogCategory.music =>
                            SubscriptionCategory.music,
                          ServiceCatalogCategory.games =>
                            SubscriptionCategory.gaming,
                          ServiceCatalogCategory.shopping =>
                            SubscriptionCategory.other,
                          ServiceCatalogCategory.other =>
                            SubscriptionCategory.other,
                        };
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Abonelik adı',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ad gerekli'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Abonelik ücreti',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ücret gerekli'
                        : (double.tryParse(value.trim().replaceAll(',', '.')) ==
                                  null ||
                              double.parse(value.trim().replaceAll(',', '.')) <=
                                  0)
                        ? 'Geçerli bir tutar gir'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _userCategories.contains(_categoryName)
                        ? _categoryName
                        : (_userCategories.isEmpty
                              ? null
                              : _userCategories.first),
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: _userCategories
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _categoryName = value ?? 'Diğer';
                      _category = _categoryForName(_categoryName);
                    }),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _pickRenewalDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Yenilenme tarihi',
                        suffixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      child: Text(
                        '${_twoDigits(_nextBillingDate.day)}.${_twoDigits(_nextBillingDate.month)}.${_nextBillingDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(labelText: 'Para birimi'),
                    items: ['TRY', 'USD', 'EUR', 'GBP']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _currency = value ?? 'TRY'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _trialEndDate != null,
                    title: const Text('Ücretsiz deneme var'),
                    subtitle: Text(
                      _trialEndDate == null
                          ? 'Deneme bitiş tarihini ekle'
                          : 'Bitiş: ${_twoDigits(_trialEndDate!.day)}.${_twoDigits(_trialEndDate!.month)}.${_trialEndDate!.year}',
                    ),
                    onChanged: (enabled) async {
                      if (!enabled) {
                        setState(() => _trialEndDate = null);
                        return;
                      }
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && mounted) {
                        setState(() => _trialEndDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _billingCycle,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme dönemi',
                    ),
                    items: ['Aylık', 'Yıllık', 'Haftalık']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _billingCycle = value ?? 'Aylık'),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (isteğe bağlı)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppGradientButton(
                    onPressed: _save,
                    child: const Text(
                      'Aboneliği Ekle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  SubscriptionCategory _categoryForName(String name) => switch (name) {
    'Video' => SubscriptionCategory.entertainment,
    'Müzik' => SubscriptionCategory.music,
    'Oyun' => SubscriptionCategory.gaming,
    'Eğitim' => SubscriptionCategory.education,
    'Alışveriş' => SubscriptionCategory.shopping,
    'Bulut Depolama' => SubscriptionCategory.cloud,
    _ => SubscriptionCategory.other,
  };
}
