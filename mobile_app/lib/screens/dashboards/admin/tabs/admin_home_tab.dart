import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminHomeTab extends StatefulWidget {
  final User user;
  const AdminHomeTab({super.key, required this.user});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final _api = ApiService();

  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _orders = [];

  static const _blue = AppColors.primaryBlue;

  static const _daysFr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _monthsFr = [
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.user.token;
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    final statsRes = await _api.fetchDashboardStats(token);
    final ordersRes = await _api.fetchOrdersAdmin(token);

    if (!mounted) return;
    setState(() {
      if (statsRes['success'] == true) {
        _stats = Map<String, dynamic>.from(statsRes['body'] as Map);
      }
      if (ordersRes.isSuccess) _orders = ordersRes.data!;
      _loading = false;
    });
  }

  List<double> _weeklySales() {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final dayStart = monday.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      return _orders
          .where((o) {
            final raw = o['created_at'];
            if (raw == null) return false;
            final d = DateTime.tryParse(raw.toString());
            if (d == null) return false;
            final local = d.toLocal();
            return !local.isBefore(dayStart) && local.isBefore(dayEnd);
          })
          .fold(
            0.0,
            (s, o) =>
                s + (double.tryParse((o['total_amount'] ?? 0).toString()) ?? 0),
          );
    });
  }

  String _weekLabel() {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.day} ${_monthsFr[monday.month - 1]} – ${sunday.day} ${_monthsFr[sunday.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final incompleteOrders =
        (_stats['incomplete_orders'] as num?)?.toInt() ??
        _orders.where((o) => o['status'] != 'delivered').length;
    final activeDrivers = (_stats['active_drivers'] ?? 0) as int;
    final activeVendors = (_stats['active_vendors'] ?? 0) as int;
    final pending = (_stats['pending_approvals'] ?? 0) as int;

    final sales = _weeklySales();
    final weeklyTotal = sales.fold(0.0, (a, b) => a + b);
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon

    final recentOrders = _orders.take(10).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Subtitle
          const Text(
            "Vue d'ensemble en temps réel",
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Stat cards grid
          _twoColGrid([
            _statCard(
              'Marchands actifs',
              activeVendors.toString(),
              'comptes',
              _blue,
              Icons.storefront_outlined,
            ),
            _statCard(
              'Coursiers actifs',
              activeDrivers.toString(),
              'comptes',
              AppColors.primaryBlue,
              Icons.local_shipping_outlined,
            ),
            _statCard(
              'Cmds non terminées',
              incompleteOrders.toString(),
              'cmds',
              AppColors.primaryBlue,
              Icons.shopping_bag_outlined,
            ),
            _statCard(
              'En attente approbation',
              pending.toString(),
              'comptes',
              AppColors.primaryBlue,
              Icons.person_add_outlined,
            ),
          ]),
          const SizedBox(height: 24),

          // Weekly chart
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ventes — Semaine en cours',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _weekLabel(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${weeklyTotal.toStringAsFixed(2)} MRU',
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _BarChartPainter(
                      data: sales,
                      labels: _daysFr,
                      todayIndex: todayIndex,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent transactions
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dernières Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                if (recentOrders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucune transaction',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  )
                else
                  ...recentOrders.map((o) {
                    final status = (o['status'] ?? '').toString();
                    final statusColor = _statusColor(status);
                    final statusLabel = _statusLabel(status);
                    final amount =
                        double.tryParse((o['total_amount'] ?? 0).toString()) ??
                        0;
                    final dateStr = o['created_at'] != null
                        ? DateTime.tryParse(
                            o['created_at'].toString(),
                          )?.toLocal()
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBlue),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '#${o['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _blue,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  o['customer_name'] ?? 'Client',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (dateStr != null)
                                  Text(
                                    '${dateStr.day}/${dateStr.month}/${dateStr.year}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${amount.toStringAsFixed(2)} MRU',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _twoColGrid(List<Widget> children) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 12),
                if (i + 1 < children.length)
                  Expanded(child: children[i + 1])
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightBlue),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040A14FF),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
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
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBlue),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040A14FF),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':
        return AppColors.primaryBlue;
      case 'pending':
        return AppColors.primaryBlue;
      case 'ready':
        return _blue;
      case 'shipped':
        return AppColors.primaryBlue;
      case 'delivered':
        return AppColors.primaryBlue;
      default:
        return Colors.black;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'paid':
        return 'PAYÉ';
      case 'pending':
        return 'ATTENTE';
      case 'ready':
        return 'PRÊT';
      case 'shipped':
        return 'LIVRAISON';
      case 'delivered':
        return 'LIVRÉ';
      default:
        return s.toUpperCase();
    }
  }
}

// ── Weekly bar chart painter ───────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final int todayIndex;

  static const _blue = AppColors.primaryBlue;

  const _BarChartPainter({
    required this.data,
    required this.labels,
    required this.todayIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold(0.0, (a, b) => max(a, b));
    const padX = 36.0;
    const padTop = 24.0;
    const padBottom = 28.0;
    final chartW = size.width - padX * 2;
    final chartH = size.height - padTop - padBottom;
    const barGap = 10.0;
    final barW = (chartW - barGap * (data.length - 1)) / data.length;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.lightBlue
      ..strokeWidth = 1;
    for (int g = 0; g <= 4; g++) {
      final y = padTop + chartH - (g / 4) * chartH;
      canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), gridPaint);
      final val = g / 4 * (maxVal == 0 ? 1 : maxVal);
      final label = val >= 1000
          ? '${(val / 1000).toStringAsFixed(0)}k'
          : val.toStringAsFixed(0);
      _drawText(canvas, label, Offset(0, y - 5), 9, Colors.black);
    }

    for (int i = 0; i < data.length; i++) {
      final val = data[i];
      final barH = maxVal > 0 ? (val / maxVal) * chartH : 0.0;
      final x = padX + i * (barW + barGap);
      final y = padTop + chartH - barH;
      final isToday = i == todayIndex;

      final paint = Paint()
        ..color = val > 0
            ? _blue.withValues(alpha: isToday ? 1.0 : 0.75)
            : AppColors.lightBlue
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH.clamp(4, chartH)),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, paint);

      // Value
      if (val > 0) {
        final vLabel = val >= 1000
            ? '${(val / 1000).toStringAsFixed(1)}k'
            : val.toStringAsFixed(0);
        _drawText(
          canvas,
          vLabel,
          Offset(x + barW / 2, y - 14),
          9,
          Colors.black,
          centered: true,
          bold: true,
        );
      }

      // Day label
      _drawText(
        canvas,
        labels[i],
        Offset(x + barW / 2, size.height - padBottom + 6),
        11,
        isToday ? _blue : Colors.black,
        centered: true,
        bold: isToday,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double size,
    Color color, {
    bool centered = false,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      centered ? Offset(offset.dx - tp.width / 2, offset.dy) : offset,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.data != data || old.todayIndex != todayIndex;
}
