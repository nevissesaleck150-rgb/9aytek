import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminFinanceTab extends StatefulWidget {
  final User user;
  const AdminFinanceTab({super.key, required this.user});

  @override
  State<AdminFinanceTab> createState() => _AdminFinanceTabState();
}

class _AdminFinanceTabState extends State<AdminFinanceTab> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _transactions = [];

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
    final res = await _api.fetchFinance(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) _transactions = res.data!;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final totalRevenue = _transactions.fold(
      0.0,
      (s, tx) =>
          s + (double.tryParse((tx['total_amount'] ?? 0).toString()) ?? 0.0),
    );
    final platformShare = _transactions.fold(
      0.0,
      (s, tx) =>
          s + (double.tryParse((tx['platform_share'] ?? 0).toString()) ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Vue financière globale',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Summary cards
          _statCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'REVENU TOTAL',
            value: '${totalRevenue.toStringAsFixed(2)} MRU',
            color: _blue,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  label: 'PART PLATEFORME',
                  value: '${platformShare.toStringAsFixed(2)} MRU',
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniCard(
                  label: 'NB. TRANSACTIONS',
                  value: _transactions.length.toString(),
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Transactions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.lightBlue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historique des transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_transactions.length} enregistrement${_transactions.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
                const SizedBox(height: 14),
                if (_transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucune transaction disponible.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  )
                else
                  ..._transactions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tx = entry.value;
                    final total =
                        double.tryParse((tx['total_amount'] ?? 0).toString()) ??
                        0.0;
                    final vendorShare =
                        double.tryParse((tx['vendor_share'] ?? 0).toString()) ??
                        0.0;
                    final influencerShare =
                        double.tryParse(
                          (tx['influencer_share'] ?? 0).toString(),
                        ) ??
                        0.0;
                    final platShare =
                        double.tryParse(
                          (tx['platform_share'] ?? 0).toString(),
                        ) ??
                        0.0;
                    final status = (tx['status'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: i % 2 == 0 ? Colors.white : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBlue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${tx['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _blue,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tx['customer_name']?.toString() ?? 'Client',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _statusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.lightBlue, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _shareItem('Total', total, Colors.black),
                              _shareItem('Marchand', vendorShare, _blue),
                              _shareItem(
                                'Influenceur',
                                influencerShare,
                                AppColors.primaryBlue,
                              ),
                              _shareItem(
                                'Plateforme',
                                platShare,
                                AppColors.primaryBlue,
                              ),
                            ],
                          ),
                          if (tx['created_at'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _fmtDate(tx['created_at'].toString()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black,
                              ),
                            ),
                          ],
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

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      height: 86,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBlue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'delivered':
        color = AppColors.primaryBlue;
        label = 'LIVRÉ';
        break;
      case 'paid':
        color = AppColors.primaryBlue;
        label = 'PAYÉ';
        break;
      case 'pending':
        color = AppColors.primaryBlue;
        label = 'ATTENTE';
        break;
      case 'cancelled':
        color = AppColors.primaryBlue;
        label = 'ANNULÉ';
        break;
      default:
        color = Colors.black;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
