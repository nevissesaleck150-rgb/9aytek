import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/bankily_split.dart';
import 'bankily_pay_button.dart';

/// Feuille de paiement Bankily : simulation de paiement puis partage du montant.
Future<bool> showBankilyPaymentSheet(
  BuildContext context, {
  required int amountMru,
  String? title,
  bool isDigital = false,
  bool isInfluencer = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BankilySheet(
      amountMru: amountMru,
      title: title ?? 'Paiement',
      isDigital: isDigital,
      isInfluencer: isInfluencer,
    ),
  );
  return result == true;
}

class _BankilySheet extends StatefulWidget {
  final int amountMru;
  final String title;
  final bool isDigital;
  final bool isInfluencer;

  const _BankilySheet({
    required this.amountMru,
    required this.title,
    this.isDigital = false,
    this.isInfluencer = false,
  });

  @override
  State<_BankilySheet> createState() => _BankilySheetState();
}

class _BankilySheetState extends State<_BankilySheet> {
  /// 0 = affichage du montant et du bouton Bankily · 1 = chargement · 2 = partage des parts · 3 = terminé
  int _step = 0;
  late BankilySplit _split;

  @override
  void initState() {
    super.initState();
    _split = BankilySplit.fromTotal(
      widget.amountMru,
      isDigital: widget.isDigital,
      isInfluencer: widget.isInfluencer,
    );
  }

  Future<void> _onBankilyPressed() async {
    setState(() => _step = 1);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(top: 48),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_outlined),
                  ),
                ],
              ),
              _totalBox(),
              const SizedBox(height: 8),
              if (_step == 0) ...[
                const Text(
                  'Appuyez sur Bankily pour simuler le paiement et partager le montant',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                BankilyPayButton(
                  amountMru: widget.amountMru,
                  onPressed: _onBankilyPressed,
                ),
              ] else if (_step == 1) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                const Text(
                  'Traitement du paiement Bankily...',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ] else if (_step == 2) ...[
                const SizedBox(height: 8),
                const Text(
                  'Répartition du montant entre les parties',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total : ${formatMru(widget.amountMru)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ..._split.rows
                    .where((row) => row.label != 'Plateforme')
                    .map(_splitCard),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Confirmer et terminer'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Montant total',
            style: TextStyle(color: AppColors.textMuted),
          ),
          Text(
            formatMru(widget.amountMru),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.darkBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitCard(({String label, int mru, double percent}) row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                formatMru(row.mru),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: row.percent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.lightBlue,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
