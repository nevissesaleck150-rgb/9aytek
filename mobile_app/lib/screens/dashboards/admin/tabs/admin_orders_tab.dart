import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminOrdersTab extends StatefulWidget {
  final User user;
  const AdminOrdersTab({super.key, required this.user});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  static const _blue = AppColors.primaryBlue;

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
    final res = await _api.fetchOrdersAdmin(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) _orders = res.data!;
      _loading = false;
    });
  }

  Future<void> _updateStatus(int orderId, String status) async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.updateOrderStatusAdmin(token, orderId, status);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Statut mis à jour.', success: true);
      _load();
    } else {
      _showSnack('Impossible de mettre à jour la commande.');
    }
  }

  Future<void> _confirmBankily(int orderId) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog(
      'Confirmer le paiement Bankily pour cette commande ?',
    );
    if (confirm != true) return;
    final res = await _api.confirmBankilyAdmin(token, orderId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Paiement Bankily confirmé.', success: true);
      _load();
    } else {
      _showSnack('Impossible de confirmer le paiement.');
    }
  }

  void _showStatusSheet(Map<String, dynamic> order) {
    const statuses = [
      ('pending', 'En attente', AppColors.primaryBlue),
      ('paid', 'Payé', AppColors.primaryBlue),
      ('ready', 'Prêt', AppColors.primaryBlue),
      ('on_way', 'En route', AppColors.primaryBlue),
      ('arrived', 'Arrivé client', AppColors.primaryBlue),
      ('delivered', 'Livré', AppColors.primaryBlue),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #${order['id']} — Changer le statut',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 14),
            ...statuses.map((s) {
              final (val, label, color) = s;
              final isCurrent = order['status'] == val;
              return ListTile(
                dense: true,
                leading: Icon(
                  isCurrent
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isCurrent ? _blue : Colors.black,
                  size: 20,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isCurrent ? _blue : Colors.black,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isCurrent) _updateStatus(order['id'] as int, val);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final delivered = _orders.where((o) => o['status'] == 'delivered').length;
    final pending = _orders.where((o) => o['status'] == 'pending').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Gestion des commandes',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Stat cards
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'TOTAL',
                  _orders.length.toString(),
                  _blue,
                  Icons.list_alt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'LIVRÉES',
                  delivered.toString(),
                  AppColors.primaryBlue,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'EN ATTENTE',
                  pending.toString(),
                  AppColors.primaryBlue,
                  Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            '${_orders.length} commande${_orders.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
          const SizedBox(height: 10),

          ..._orders.map((o) {
            final status = (o['status'] ?? '').toString();
            final statusColor = _statusColor(status);
            final statusLabel = _statusLabel(status);
            final amount =
                double.tryParse((o['total_amount'] ?? 0).toString()) ?? 0.0;
            final isBankily = (o['payment_method'] ?? '') == 'bankily';
            final bankilyPaid = o['bankily_payment_confirmed'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBlue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${o['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _blue,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          o['customer_name']?.toString() ?? 'Client',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 14,
                        color: Colors.black,
                      ),
                      Text(
                        '${amount.toStringAsFixed(2)} MRU',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (o['created_at'] != null) ...[
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.black,
                        ),
                        Text(
                          _fmtDate(o['created_at'].toString()),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (isBankily && !bankilyPaid)
                        _chip(
                          'BANKILY',
                          AppColors.primaryBlue,
                          AppColors.lightBlue,
                        )
                      else if (isBankily)
                        _chip(
                          'BANKILY ✓',
                          AppColors.primaryBlue,
                          AppColors.lightBlue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Change status
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showStatusSheet(o),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text(
                            'Statut',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue,
                            side: const BorderSide(color: _blue),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (isBankily && !bankilyPaid) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmBankily(o['id'] as int),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text(
                              'Bankily',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
      case 'on_way':
        return AppColors.primaryBlue;
      case 'arrived':
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
      case 'on_way':
        return 'EN ROUTE';
      case 'arrived':
        return 'ARRIVÉ';
      case 'delivered':
        return 'LIVRÉ';
      default:
        return s.toUpperCase();
    }
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<bool?> _confirmDialog(String message) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmation'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.primaryBlue : Colors.black,
      ),
    );
  }
}
