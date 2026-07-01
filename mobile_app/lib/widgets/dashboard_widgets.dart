import 'package:flutter/material.dart';
import '../models/api_order.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const QuickActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBlue, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}

class OrderStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const OrderStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateBox({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardShell extends StatelessWidget {
  final String title;
  final String username;
  final int currentIndex;
  final List<BottomNavigationBarItem> navItems;
  final ValueChanged<int> onNavTap;
  final List<Widget> pages;
  final VoidCallback onLogout;
  final VoidCallback? onNotifications;
  final int? notificationCount;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const DashboardShell({
    super.key,
    required this.title,
    required this.username,
    required this.currentIndex,
    required this.navItems,
    required this.onNavTap,
    required this.pages,
    required this.onLogout,
    this.onNotifications,
    this.notificationCount,
    this.floatingActionButton,
    this.showAppBar = true,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: showAppBar
            ? AppBar(
                title: Text(title),
                actions: [
                  IconButton(
                    icon: Badge(
                      isLabelVisible: (notificationCount ?? 0) > 0,
                      label: Text('${notificationCount ?? 0}'),
                      child: const Icon(Icons.notifications_none_outlined),
                    ),
                    onPressed: onNotifications,
                  ),
                ],
              )
            : null,
        body: IndexedStack(index: currentIndex, children: pages),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onNavTap,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.lightBlue,
          destinations: navItems
              .map(
                (item) => NavigationDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon,
                  label: item.label ?? '',
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class WelcomeHeader extends StatelessWidget {
  final String username;
  final String subtitle;

  const WelcomeHeader({
    super.key,
    required this.username,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.darkBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue, $username',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }
}

/// Weekly earnings chart showing current week's daily earnings.
class WeeklyEarningsChart extends StatelessWidget {
  final List<ApiOrder> orders;
  final String title;
  final Color? color;
  final bool useInfluencerEarnings;

  const WeeklyEarningsChart({
    super.key,
    required this.orders,
    this.title = 'Ventes de la semaine',
    this.color,
    this.useInfluencerEarnings = false,
  });

  @override
  Widget build(BuildContext context) {
    final chartColor = color ?? AppColors.primaryBlue;
    final now = DateTime.now();
    final mondayOffset = now.weekday == 7 ? -6 : 1 - now.weekday;
    final monday = DateTime(now.year, now.month, now.day + mondayOffset);

    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final todayIndex = now.weekday == 7 ? 6 : now.weekday - 1;

    final dailyEarnings = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return orders
          .where((o) {
            if (o.createdAt == null) return false;
            final d = o.createdAt!;
            return d.year == day.year &&
                d.month == day.month &&
                d.day == day.day;
          })
          .fold(
            0.0,
            (sum, o) =>
                sum +
                (useInfluencerEarnings
                    ? o.influencerEarnings
                    : o.totalMru.toDouble()),
          );
    });

    final total = dailyEarnings.fold(0.0, (a, b) => a + b);
    final maxVal = dailyEarnings.fold(0.0, (a, b) => a > b ? a : b);
    final maxDisplay = maxVal > 0 ? maxVal : 1.0;

    final sunday = monday.add(const Duration(days: 6));
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    final range =
        '${monday.day} ${months[monday.month - 1]} – ${sunday.day} ${months[sunday.month - 1]}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Journalier — $range',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chartColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${total.round()} UM',
                  style: TextStyle(
                    color: chartColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = dailyEarnings[i];
                final barH = maxDisplay > 0 ? (val / maxDisplay) * 90 : 0.0;
                final isToday = i == todayIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          val > 0
                              ? (val >= 1000
                                    ? '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}k'
                                    : val.round().toString())
                              : '—',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isToday ? chartColor : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barH.clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            color: val > 0 ? chartColor : AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isToday ? chartColor : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
