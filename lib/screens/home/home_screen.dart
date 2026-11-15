import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/app_preferences.dart';
import '../../services/payment_record_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_components.dart';
import 'add_subscription_screen.dart';
import 'analysis_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'subscriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    await AppPreferences.instance.initializeForUser(widget.user.email);
    await PaymentRecordService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        user: widget.user,
        onAddSubscription: _openAddSubscription,
        onShowSubscriptions: () => setState(() => _selectedIndex = 1),
      ),
      const SubscriptionsScreen(),
      const CalendarScreen(),
      const AnalysisScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 1
          ? AppGradientFab(
              onPressed: _openAddSubscription,
              tooltip: 'Abonelik ekle',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onSelect: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  void _openAddSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSubscriptionScreen()),
    );
  }
}
