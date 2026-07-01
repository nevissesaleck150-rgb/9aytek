import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

import '../../../models/users.dart';
import '../../../services/api_service.dart';
import '../../../utils/role_router.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_orders_tab.dart';
import 'tabs/admin_finance_tab.dart';
import 'tabs/admin_shops_tab.dart';
import 'tabs/admin_topup_tab.dart';
import 'tabs/admin_lms_tab.dart';

class AdminDashboard extends StatefulWidget {
  final User user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final ApiService _api = ApiService();
  final List<_AdminNotification> _notifications = [];
  bool _loadingNotifications = false;

  static const _primaryBlue = AppColors.primaryBlue;

  static const _labels = [
    'Tableau de bord',
    'Utilisateurs',
    'Commandes',
    'Finance',
    'Boutiques',
    'Recharges',
    'Formations',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.shopping_bag_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.storefront_outlined,
    Icons.smartphone_outlined,
    Icons.school_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final token = widget.user.token;
    if (token == null || token.isEmpty || _loadingNotifications) return;

    setState(() => _loadingNotifications = true);
    final usersRes = await _api.fetchUsers(token);
    final productsRes = await _api.fetchProductsAdmin(token);
    final topupsRes = await _api.fetchTopupRequests(token);

    final next = <_AdminNotification>[];

    if (usersRes.isSuccess) {
      for (final user in usersRes.data ?? <Map<String, dynamic>>[]) {
        if (user['is_approved'] != true) {
          next.add(
            _AdminNotification(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Compte a verifier',
              body: _joinInfo([
                _displayName(user),
                _textOf(user['role']),
                _textOf(user['email']),
              ]),
            ),
          );
        }
      }
    }

    if (productsRes.isSuccess) {
      for (final product in productsRes.data ?? <Map<String, dynamic>>[]) {
        if (product['is_approved'] != true) {
          next.add(
            _AdminNotification(
              icon: Icons.inventory_2_outlined,
              title: 'Produit a approuver',
              body: _joinInfo([
                _textOf(product['name']),
                _labeled(
                  'Boutique',
                  product['vendor_name'] ??
                      product['shop_name'] ??
                      product['vendor'],
                ),
              ]),
            ),
          );
        }
      }
    }

    if (topupsRes.isSuccess) {
      for (final request in topupsRes.data ?? <Map<String, dynamic>>[]) {
        if (_textOf(request['order_status']).toLowerCase() != 'delivered') {
          next.add(
            _AdminNotification(
              icon: Icons.smartphone_outlined,
              title: 'Recharge a completer',
              body: _joinInfo([
                _textOf(
                  request['item_name'] ??
                      request['digital_service_title'] ??
                      request['service_title'] ??
                      request['title'],
                ),
                _labeled('ID', request['topup_account_id']),
                _labeled('Payer', request['topup_payer']),
              ]),
            ),
          );
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _notifications
        ..clear()
        ..addAll(next);
      _loadingNotifications = false;
    });
  }

  static String _displayName(Map<String, dynamic> user) {
    final name = _joinInfo([
      _textOf(user['first_name']),
      _textOf(user['last_name']),
    ]);
    if (name.isNotEmpty) return name;
    return _textOf(user['username']);
  }

  static String _joinInfo(List<String> parts) =>
      parts.where((part) => part.trim().isNotEmpty).join(' - ');

  static String _textOf(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }

  static String _labeled(String label, Object? value) {
    final text = _textOf(value);
    return text.isEmpty ? '' : '$label: $text';
  }

  Future<void> _showNotifications() async {
    await _loadNotifications();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Actualiser',
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _showNotifications();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune notification pour le moment',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final item = _notifications[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.lightBlue,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        item.icon,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.body.isEmpty
                                                ? 'Nouvelle demande en attente'
                                                : item.body,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: _primaryBlue),
        title: Text(
          _labels[_currentIndex],
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _showNotifications,
            icon: Badge(
              isLabelVisible: _notifications.isNotEmpty,
              label: Text('${_notifications.length}'),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: Icon(
                _loadingNotifications
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.lightBlue),
        ),
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminHomeTab(user: widget.user),
          AdminUsersTab(user: widget.user),
          AdminOrdersTab(user: widget.user),
          AdminFinanceTab(user: widget.user),
          AdminShopsTab(user: widget.user),
          AdminTopupTab(user: widget.user),
          AdminLmsTab(user: widget.user),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _primaryBlue,
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header - Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Center(
                child: Image.asset('assets/images/logo.png', height: 72),
              ),
            ),
            const Divider(color: Colors.white24, height: 1, thickness: 1),
            const SizedBox(height: 6),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                itemCount: _labels.length,
                itemBuilder: (context, i) {
                  final selected = _currentIndex == i;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _currentIndex = i);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _icons[i],
                              color: selected ? Colors.white : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _labels[i],
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white60,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 1, thickness: 1),
            // Logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => RoleRouter.confirmLogout(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Se déconnecter',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNotification {
  final IconData icon;
  final String title;
  final String body;

  const _AdminNotification({
    required this.icon,
    required this.title,
    required this.body,
  });
}
