import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_components.dart';
import 'service_brand_icon.dart';

enum ServiceCatalogCategory { all, video, music, games, shopping, other }

extension ServiceCatalogCategoryLabel on ServiceCatalogCategory {
  String get label => switch (this) {
    ServiceCatalogCategory.all => 'Tümü',
    ServiceCatalogCategory.video => 'Video',
    ServiceCatalogCategory.music => 'Müzik',
    ServiceCatalogCategory.games => 'Oyun',
    ServiceCatalogCategory.shopping => 'Alışveriş',
    ServiceCatalogCategory.other => 'Diğer',
  };
}

class ServiceSelection {
  const ServiceSelection({required this.name, required this.category});

  final String name;
  final ServiceCatalogCategory category;
}

class SubscriptionServicePicker extends StatelessWidget {
  const SubscriptionServicePicker({
    super.key,
    required this.selectedName,
    required this.onSelected,
  });

  final String? selectedName;
  final ValueChanged<ServiceSelection> onSelected;

  static const _services = <ServiceSelection>[
    ServiceSelection(name: 'Netflix', category: ServiceCatalogCategory.video),
    ServiceSelection(
      name: 'YouTube Premium',
      category: ServiceCatalogCategory.video,
    ),
    ServiceSelection(name: 'Spotify', category: ServiceCatalogCategory.music),
    ServiceSelection(name: 'Disney+', category: ServiceCatalogCategory.video),
    ServiceSelection(
      name: 'Amazon Prime Video',
      category: ServiceCatalogCategory.video,
    ),
    ServiceSelection(
      name: 'Apple Music',
      category: ServiceCatalogCategory.music,
    ),
    ServiceSelection(
      name: 'Xbox Game Pass',
      category: ServiceCatalogCategory.games,
    ),
    ServiceSelection(
      name: 'PlayStation Plus',
      category: ServiceCatalogCategory.games,
    ),
    ServiceSelection(name: 'Exxen', category: ServiceCatalogCategory.video),
    ServiceSelection(name: 'BluTV', category: ServiceCatalogCategory.video),
    ServiceSelection(name: 'Gain', category: ServiceCatalogCategory.video),
  ];

  Future<void> _openPicker(BuildContext context) async {
    final selection = await showModalBottomSheet<ServiceSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ServicePickerSheet(services: _services, selectedName: selectedName),
    );
    if (selection != null) onSelected(selection);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedName != null && selectedName!.isNotEmpty;
    return Semantics(
      button: true,
      label: 'Abonelik Servisi Seç',
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primary.withValues(alpha: .55)),
          ),
          child: Row(
            children: [
              if (hasSelection) ...[
                ServiceBrandIcon(serviceName: selectedName!, size: 42),
                const SizedBox(width: 12),
              ] else ...[
                Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelection ? selectedName! : 'Abonelik Servisi Seç',
                      style: TextStyle(
                        color: hasSelection ? AppColors.text : AppColors.muted,
                        fontWeight: hasSelection
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (hasSelection)
                      const Text(
                        'Servisi değiştirmek için dokun',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicePickerSheet extends StatefulWidget {
  const _ServicePickerSheet({
    required this.services,
    required this.selectedName,
  });

  final List<ServiceSelection> services;
  final String? selectedName;

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  final _searchController = TextEditingController();
  final _customNameController = TextEditingController();
  ServiceCatalogCategory _category = ServiceCatalogCategory.all;
  bool _addingCustom = false;

  @override
  void initState() {
    super.initState();
    final selected = widget.services.where(
      (service) => service.name == widget.selectedName,
    );
    if (selected.isNotEmpty) {
      _category = selected.first.category;
    } else if (widget.selectedName != null) {
      _category = ServiceCatalogCategory.other;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final matches = widget.services
        .where((service) {
          if (_category == ServiceCatalogCategory.all) return true;
          if (_category == ServiceCatalogCategory.shopping) {
            return service.name.toLowerCase().contains('amazon');
          }
          return service.category == _category;
        })
        .where((service) => service.name.toLowerCase().contains(query))
        .toList();

    return Container(
      height: MediaQuery.sizeOf(context).height * .86,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.primary, width: .8),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Abonelik Servisi Seç',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppTextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              hintText: 'Servis ara',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ServiceCatalogCategory.values.map((category) {
                final selected = category == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _category = category;
                      _addingCustom = false;
                    }),
                    selectedColor: AppColors.primaryLight.withValues(
                      alpha: .32,
                    ),
                    backgroundColor: AppColors.surfaceSolid,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.lavender : AppColors.muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: AppColors.primaryLight.withValues(
                        alpha: selected ? .85 : .35,
                      ),
                    ),
                    shape: const StadiumBorder(),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (_category == ServiceCatalogCategory.other)
            Expanded(child: _buildCustomEntry(context))
          else if (matches.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Bu aramayla eşleşen servis yok.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                itemCount: matches.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final service = matches[index];
                  final selected = service.name == widget.selectedName;
                  return _ServiceTile(
                    service: service,
                    selected: selected,
                    onTap: () => Navigator.pop(context, service),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_addingCustom) ...[
            _ServiceTile(
              service: const ServiceSelection(
                name: 'Özel servis',
                category: ServiceCatalogCategory.other,
              ),
              selected: false,
              onTap: () => setState(() => _addingCustom = true),
            ),
            const SizedBox(height: 10),
            const Text(
              'Listede olmayan bir abonelik servisini ekle.',
              style: TextStyle(color: AppColors.muted),
            ),
          ] else ...[
            const Text(
              'Servis adı',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customNameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Örn. dijital servis',
              ),
            ),
            const SizedBox(height: 16),
            AppGradientButton(
              onPressed: _customNameController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      context,
                      ServiceSelection(
                        name: _customNameController.text.trim(),
                        category: ServiceCatalogCategory.other,
                      ),
                    ),
              child: const Text('Servisi Seç'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ServiceSelection service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.surfaceAlt,
            width: selected ? 1.7 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .20),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            ServiceBrandIcon(serviceName: service.name, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryLight,
                size: 18,
              ),
          ],
        ),
      ),
    ),
  );
}
