import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import '../../../models/api_order.dart';
import '../../../widgets/bankily_pay_button.dart';
import '../../../utils/bankily_split.dart';

class CustomerPaymentPage extends StatefulWidget {
  final ApiOrder order;
  final Future<String?> Function() onPayWithBankily;

  const CustomerPaymentPage({
    super.key,
    required this.order,
    required this.onPayWithBankily,
  });

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  bool _isPaying = false;

  String _safePaymentError(String error) {
    final lower = error.toLowerCase();
    final looksTechnical =
        lower.contains('http') ||
        lower.contains('exception') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('{') ||
        lower.contains('}');
    if (looksTechnical) {
      return 'Impossible de terminer le paiement. Veuillez réessayer.';
    }
    return error;
  }

  Future<void> _handlePayment() async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    final error = await widget.onPayWithBankily();
    if (!mounted) return;
    setState(() => _isPaying = false);

    if (error == null) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_safePaymentError(error))));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      _InfoRow(label: 'Commande', value: '#${order.id}'),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Montant',
                        value: formatMru(order.totalMru),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Nombre d\'articles',
                        value: '${order.items.length}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contenu de la commande',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: order.items.isEmpty
                      ? const Center(
                          child: Text(
                            'Cette commande ne contient aucun article',
                          ),
                        )
                      : ListView.separated(
                          itemCount: order.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.lightBlue),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.quantity} x ${item.itemName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (item.itemDescription.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.itemDescription,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  if (item.itemType == 'topup') ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if ((item.topupRechargeType ?? '')
                                            .isNotEmpty)
                                          _MetaChip(
                                            label: 'Type',
                                            value: item.topupRechargeType!,
                                          ),
                                        if ((item.topupAccountId ?? '')
                                            .isNotEmpty)
                                          _MetaChip(
                                            label: 'ID',
                                            value: item.topupAccountId!,
                                          ),
                                        if ((item.topupPayer ?? '').isNotEmpty)
                                          _MetaChip(
                                            label: 'Payer',
                                            value: item.topupPayer!,
                                          ),
                                      ],
                                    ),
                                  ],
                                  if (item.itemType == 'ad' &&
                                      (item.influencerPhone ?? '')
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _MetaChip(
                                      label: 'Influenceur',
                                      value: item.influencerPhone!,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                BankilyPayButton(
                  amountMru: order.totalMru,
                  isLoading: _isPaying,
                  onPressed: _handlePayment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
