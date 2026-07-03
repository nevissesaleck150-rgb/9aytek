import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import '../../../models/api_order.dart';
import '../../../widgets/bankily_pay_button.dart';
import '../../../utils/bankily_split.dart';

// Lightweight data class used only for rendering the invoice (facture).
// Populated by mapping CartItem in customer_dashboard.dart to avoid a
// circular import.
class FactureItem {
  final String title;
  final int unitPrice;
  final int quantity;
  final int subtotal;
  final bool isAd;
  final bool isTopup;
  final String? vendorName;
  final String? influencerName;
  final String? influencerPhone;
  final String? topupAccountId;
  final String? topupPayer;

  const FactureItem({
    required this.title,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.isAd = false,
    this.isTopup = false,
    this.vendorName,
    this.influencerName,
    this.influencerPhone,
    this.topupAccountId,
    this.topupPayer,
  });
}

class CustomerPaymentPage extends StatefulWidget {
  final ApiOrder order;
  final List<FactureItem> cartItems;
  final Future<String?> Function() onPayWithBankily;

  const CustomerPaymentPage({
    super.key,
    required this.order,
    required this.cartItems,
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
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _FactureDialog(
          order: widget.order,
          cartItems: widget.cartItems,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_safePaymentError(error)),
        backgroundColor: Colors.red,
      ),
    );
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

// ── Facture Dialog ────────────────────────────────────────────────────────────

class _FactureDialog extends StatelessWidget {
  final ApiOrder order;
  final List<FactureItem> cartItems;

  const _FactureDialog({
    required this.order,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              '9',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '9aytek',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const Text(
                          'FACTURE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Order info row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FactureLabel(
                            label: 'N° Commande',
                            value: '#${order.id}',
                          ),
                          _FactureLabel(
                            label: 'Date',
                            value: dateStr,
                            alignRight: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section divider
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'ARTICLES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Items
                    ...cartItems.map((item) => _FactureItemRow(item: item)),

                    const SizedBox(height: 12),
                    const Divider(thickness: 1.5),

                    // Total
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            formatMru(order.totalMru),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1.5),
                    const SizedBox(height: 16),

                    // Screenshot hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prenez une capture d\'écran de cette facture comme preuve de votre paiement',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fixed action button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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

// ── Facture item row ──────────────────────────────────────────────────────────

class _FactureItemRow extends StatelessWidget {
  final FactureItem item;
  const _FactureItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title.isEmpty ? 'Article' : item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatMru(item.subtotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          // Quantity × unit price (only if qty > 1)
          if (item.quantity > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${item.quantity} × ${formatMru(item.unitPrice)}',
              style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue),
            ),
          ],

          // Product → vendor
          if (!item.isAd && (item.vendorName ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoChip(
              icon: Icons.store_outlined,
              text: 'Boutique: ${item.vendorName}',
            ),
          ],

          // Ad → influencer name + phone
          if (item.isAd) ...[
            const SizedBox(height: 6),
            if ((item.influencerName ?? '').isNotEmpty)
              _InfoChip(
                icon: Icons.person_outline,
                text: 'Influenceur: ${item.influencerName}',
              ),
            if ((item.influencerPhone ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoChip(
                icon: Icons.phone_outlined,
                text: item.influencerPhone!,
                color: AppColors.primaryBlue,
              ),
            ],
          ],

          // Topup meta
          if (item.isTopup) ...[
            if ((item.topupAccountId ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoChip(
                icon: Icons.tag_outlined,
                text: 'ID: ${item.topupAccountId}',
              ),
            ],
            if ((item.topupPayer ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoChip(
                icon: Icons.phone_outlined,
                text: 'Payer: ${item.topupPayer}',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.color = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FactureLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _FactureLabel({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
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
