// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';

import '../../services/app_preferences.dart';
import '../../services/category_service.dart';
import '../../services/currency_service.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferences.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: AppBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([prefs, CurrencyService.instance]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                const _Heading('Para birimi ve bildirimler'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.currency_exchange_rounded),
                        title: const Text('Görüntüleme para birimi'),
                        subtitle: Text(_rateLabel()),
                        trailing: DropdownButton<String>(
                          value: prefs.currency,
                          dropdownColor: AppColors.surfaceSolid,
                          underline: const SizedBox.shrink(),
                          items: CurrencyService.supportedCurrencies
                              .map(
                                (code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) prefs.setCurrency(value);
                          },
                        ),
                      ),
                      TextButton.icon(
                        onPressed: CurrencyService.instance.refreshRates,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Referans kurunu güncelle'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        value: prefs.notificationsEnabled,
                        onChanged: prefs.setNotificationsEnabled,
                        title: const Text('Bildirimleri etkinleştir'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.reminderBefore(1),
                        onChanged: (value) => prefs.setReminderBefore(1, value),
                        title: const Text('Ödemeden 1 gün önce'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.reminderBefore(3),
                        onChanged: (value) => prefs.setReminderBefore(3, value),
                        title: const Text('Ödemeden 3 gün önce'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.reminderBefore(7),
                        onChanged: (value) => prefs.setReminderBefore(7, value),
                        title: const Text('Ödemeden 7 gün önce'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.trialReminders,
                        onChanged: prefs.setTrialReminders,
                        title: const Text('Ücretsiz deneme bitişi'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.priceAlerts,
                        onChanged: prefs.setPriceAlerts,
                        title: const Text('Fiyat değişikliği bildirimleri'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.muted,
                        onChanged: prefs.setMuted,
                        title: const Text('Bildirimleri sessize al'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Bildirim saati'),
                        trailing: TextButton(
                          onPressed: () async {
                            final initial = _parseTime(prefs.notificationTime);
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: initial,
                            );
                            if (selected != null) {
                              prefs.setNotificationTime(
                                '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
                              );
                            }
                          },
                          child: Text(prefs.notificationTime),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _Heading('Kişiselleştirme'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _NavTile(
                        icon: Icons.dashboard_customize_outlined,
                        title: 'Ana sayfayı düzenle',
                        subtitle: 'Kartları göster, gizle ve sırala',
                        page: const DashboardCustomizationScreen(),
                      ),
                      const Divider(height: 1),
                      _NavTile(
                        icon: Icons.palette_outlined,
                        title: 'Görünümü özelleştir',
                        subtitle: 'Arka plan, vurgu rengi ve kart biçimi',
                        page: const AppearanceCustomizationScreen(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        title: const Text('Aylık bütçe'),
                        subtitle: Text(
                          prefs.monthlyBudget == null
                              ? 'Belirlenmedi'
                              : '${prefs.monthlyBudget!.toStringAsFixed(2)} ${prefs.currency}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _editBudget(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: const Text('Kategorileri yönet'),
                        subtitle: const Text('Varsayılan kategoriler'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryManagementScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _Heading('Veri ve kur bilgisi'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Döviz kurları Frankfurter referans kurlarıdır; gerçek zamanlı işlem kuru değildir.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rateLabel(),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aylık bütçe kullanımı: ${SubscriptionService.instance.monthlyTotalInCurrency(prefs.currency).toStringAsFixed(2)} ${prefs.currency}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _rateLabel() {
    final service = CurrencyService.instance;
    final date = service.rateDate;
    if (date == null)
      return service.isLoading ? 'Kurlar alınıyor…' : 'Henüz kur verisi yok';
    final dateText =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return 'Referans tarihi: $dateText${service.isStale ? ' · Önbellekteki eski veri' : ''}';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.last) ?? 0,
    );
  }

  Future<void> _editBudget(BuildContext context) async {
    final prefs = AppPreferences.instance;
    final controller = TextEditingController(
      text: prefs.monthlyBudget?.toStringAsFixed(2) ?? '',
    );
    final value = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aylık bütçe'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Tutar (${prefs.currency})'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1),
            child: const Text('Kaldır'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          AppGradientButton(
            width: 100,
            height: 42,
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (value == -1) prefs.setMonthlyBudget(null);
    if (value != null && value >= 0) prefs.setMonthlyBudget(value);
  }
}

class DashboardCustomizationScreen extends StatelessWidget {
  const DashboardCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferences.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Ana sayfayı düzenle')),
      body: AppBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: prefs,
            builder: (context, _) => ReorderableListView(
              padding: const EdgeInsets.all(20),
              onReorder: prefs.reorderDashboard,
              children: [
                for (final key in prefs.dashboardOrder)
                  AppCard(
                    key: ValueKey(key),
                    padding: EdgeInsets.zero,
                    child: SwitchListTile.adaptive(
                      secondary: const Icon(Icons.drag_handle_rounded),
                      title: Text(AppPreferences.dashboardLabels[key] ?? key),
                      value: prefs.dashboardIsVisible(key),
                      onChanged: (value) =>
                          prefs.setDashboardVisible(key, value),
                    ),
                  ),
                Padding(
                  key: const ValueKey('restore'),
                  padding: const EdgeInsets.only(top: 12),
                  child: AppSecondaryButton(
                    onPressed: prefs.resetDashboard,
                    child: const Text('Varsayılan düzene dön'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppearanceCustomizationScreen extends StatelessWidget {
  const AppearanceCustomizationScreen({super.key});
  static const backgrounds = <(String, String)>[
    ('purpleGalaxy', 'Mor galaksi'),
    ('blueGalaxy', 'Koyu mavi galaksi'),
    ('pinkGalaxy', 'Koyu pembe galaksi'),
    ('solid', 'Sade koyu mor'),
  ];
  static const accents = <(String, Color, String)>[
    ('lavender', Color(0xFFC4B5FD), 'Lavanta'),
    ('violet', Color(0xFFA78BFA), 'Menekşe'),
    ('pinkLavender', Color(0xFFE9D5FF), 'Açık lavanta'),
    ('silver', Color(0xFFD1D5DB), 'Gümüş'),
  ];

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferences.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Görünümü özelleştir')),
      body: AppBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: prefs,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Heading('Arka plan'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in backgrounds)
                            ChoiceChip(
                              selected: entry.$1 == 'purpleGalaxy',
                              label: Text(entry.$2),
                              onSelected: null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Arka plan seçenekleri şimdilik kullanılamıyor. '
                        'Mor galaksi arka planı sabit olarak uygulanır.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _Heading('Vurgu rengi'),
                AppCard(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in accents)
                        ChoiceChip(
                          selected: prefs.accent == entry.$1,
                          avatar: CircleAvatar(
                            backgroundColor: entry.$2,
                            radius: 9,
                          ),
                          label: Text(entry.$3),
                          onSelected: (_) => prefs.setAccent(entry.$1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _Heading('Kartlar'),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Köşe yuvarlaklığı'),
                        subtitle: Text('${prefs.cornerRadius.round()} px'),
                      ),
                      Slider(
                        value: prefs.cornerRadius,
                        min: 12,
                        max: 32,
                        divisions: 10,
                        onChanged: prefs.setCornerRadius,
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.compactCards,
                        onChanged: prefs.setCompactCards,
                        title: const Text('Kompakt kartlar'),
                      ),
                      SwitchListTile.adaptive(
                        value: prefs.animations,
                        onChanged: prefs.setAnimations,
                        title: const Text('Animasyonlar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppSecondaryButton(
                  onPressed: prefs.resetAppearance,
                  child: const Text('Görünümü varsayılana döndür'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    ),
  );
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primaryLight),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  );
}

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});
  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final service = CategoryService.instance;
  @override
  void initState() {
    super.initState();
    service.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kategorileri yönet')),
    floatingActionButton: AppGradientFab(onPressed: () => _edit()),
    body: AppBackground(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: service,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final category in service.categories)
                AppCard(
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.color,
                      radius: 11,
                    ),
                    title: Text(category.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit')
                          _edit(category.name, category.color);
                        if (action == 'delete') service.remove(category.name);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _edit([String? oldName, Color? initialColor]) async {
    final controller = TextEditingController(text: oldName ?? '');
    var color = initialColor ?? CategoryService.palette.first;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(oldName == null ? 'Kategori ekle' : 'Kategoriyi düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Kategori adı'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in CategoryService.palette)
                    InkWell(
                      onTap: () => setDialog(() => color = option),
                      child: CircleAvatar(
                        backgroundColor: option,
                        radius: 15,
                        child: color == option
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            AppGradientButton(
              width: 100,
              height: 42,
              onPressed: () async {
                if (oldName == null) {
                  await service.add(controller.text, color);
                } else {
                  await service.rename(oldName, controller.text);
                  await service.setColor(controller.text.trim(), color);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}
