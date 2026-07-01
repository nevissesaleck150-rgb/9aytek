/// Partage du montant après paiement Bankily (simulation) — répartition selon la plateforme.
class BankilySplit {
  final int totalMru;
  final int vendorMru;
  final int influencerMru;
  final int courierMru;
  final int platformMru;

  const BankilySplit({
    required this.totalMru,
    required this.vendorMru,
    required this.influencerMru,
    required this.courierMru,
    required this.platformMru,
  });

  /// Répartition correcte:
  /// - Cours/Recharge (digital): 100% plateforme
  /// - Boutique vendeur: 85% vendeur, 5% plateforme, 10% coursier
  /// - Boutique influenceur: 70% vendeur, 15% influenceur, 5% plateforme, 10% coursier
  factory BankilySplit.fromTotal(
    int totalMru, {
    bool isInfluencer = false,
    bool isDigital = false,
  }) {
    if (totalMru <= 0) {
      return const BankilySplit(
        totalMru: 0,
        vendorMru: 0,
        influencerMru: 0,
        courierMru: 0,
        platformMru: 0,
      );
    }

    if (isDigital) {
      // 100% plateforme
      return BankilySplit(
        totalMru: totalMru,
        vendorMru: 0,
        influencerMru: 0,
        courierMru: 0,
        platformMru: totalMru,
      );
    }

    if (isInfluencer) {
      // 70% vendeur, 15% influenceur, 5% plateforme, 10% coursier
      final vendor = (totalMru * 0.70).round();
      final influencer = (totalMru * 0.15).round();
      final platform = (totalMru * 0.05).round();
      final courier = totalMru - vendor - influencer - platform;
      return BankilySplit(
        totalMru: totalMru,
        vendorMru: vendor,
        influencerMru: influencer,
        courierMru: courier,
        platformMru: platform,
      );
    }

    // Boutique vendeur: 85% vendeur, 5% plateforme, 10% coursier
    final vendor = (totalMru * 0.85).round();
    final platform = (totalMru * 0.05).round();
    final courier = totalMru - vendor - platform;
    return BankilySplit(
      totalMru: totalMru,
      vendorMru: vendor,
      influencerMru: 0,
      courierMru: courier,
      platformMru: platform,
    );
  }

  List<({String label, int mru, double percent})> get rows => [
    (label: 'Marchand', mru: vendorMru, percent: vendorMru / totalMru),
    (
      label: 'Influenceur',
      mru: influencerMru,
      percent: influencerMru / totalMru,
    ),
    (label: 'Livreur', mru: courierMru, percent: courierMru / totalMru),
    (label: 'Plateforme', mru: platformMru, percent: platformMru / totalMru),
  ];
}

String formatMru(num amount) {
  if (amount is double) return '${amount.toStringAsFixed(0)} MRU';
  return '$amount MRU';
}
