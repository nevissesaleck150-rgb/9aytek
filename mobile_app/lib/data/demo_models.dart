import 'package:flutter/material.dart';

class DemoProduct {
  final String id;
  final String name;
  final int priceMru;
  final String storeName;
  final String category;
  final IconData icon;

  const DemoProduct({
    required this.id,
    required this.name,
    required this.priceMru,
    required this.storeName,
    required this.category,
    this.icon = Icons.shopping_bag_outlined,
  });
}

class CartLine {
  final DemoProduct product;
  int quantity;

  CartLine({required this.product, this.quantity = 1});

  int get subtotal => product.priceMru * quantity;
}

enum DemoOrderStatus { pendingPayment, paid, ready, picked, onWay, delivered }

extension DemoOrderStatusX on DemoOrderStatus {
  String get label {
    switch (this) {
      case DemoOrderStatus.pendingPayment:
        return 'En attente de paiement';
      case DemoOrderStatus.paid:
        return 'Paye';
      case DemoOrderStatus.ready:
        return 'Pret';
      case DemoOrderStatus.picked:
        return 'Recupere';
      case DemoOrderStatus.onWay:
        return 'En route';
      case DemoOrderStatus.delivered:
        return 'Livre';
    }
  }

  IconData get icon {
    switch (this) {
      case DemoOrderStatus.pendingPayment:
        return Icons.payment_outlined;
      case DemoOrderStatus.paid:
        return Icons.check_outlined;
      case DemoOrderStatus.ready:
        return Icons.inventory_2_outlined;
      case DemoOrderStatus.picked:
        return Icons.shopping_basket_outlined;
      case DemoOrderStatus.onWay:
        return Icons.delivery_dining_outlined;
      case DemoOrderStatus.delivered:
        return Icons.done_all_outlined;
    }
  }

  DemoOrderStatus? get next {
    final i = DemoOrderStatus.values.indexOf(this);
    if (i >= DemoOrderStatus.values.length - 1) return null;
    return DemoOrderStatus.values[i + 1];
  }
}

class DemoOrder {
  final String id;
  final List<CartLine> lines;
  DemoOrderStatus status;
  final DateTime createdAt;

  DemoOrder({
    required this.id,
    required this.lines,
    this.status = DemoOrderStatus.pendingPayment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get total => lines.fold(0, (s, l) => s + l.subtotal);
}

class DemoNotification {
  final String title;
  final String body;
  final DateTime time;
  bool read;

  DemoNotification({
    required this.title,
    required this.body,
    DateTime? time,
    this.read = false,
  }) : time = time ?? DateTime.now();
}

class DemoCatalog {
  static const vendorProducts = [
    DemoProduct(
      id: 'p1',
      name: 'Smartphone',
      priceMru: 12500,
      storeName: 'Tech Store',
      category: 'Electronique',
      icon: Icons.smartphone_outlined,
    ),
    DemoProduct(
      id: 'p2',
      name: 'Ecouteurs sans fil',
      priceMru: 2800,
      storeName: 'Tech Store',
      category: 'Electronique',
      icon: Icons.headphones_outlined,
    ),
    DemoProduct(
      id: 'p3',
      name: 'Robe classique',
      priceMru: 4500,
      storeName: 'Boutique Elegance',
      category: 'Mode',
      icon: Icons.checkroom_outlined,
    ),
    DemoProduct(
      id: 'p4',
      name: 'Parfum premium',
      priceMru: 3200,
      storeName: 'Boutique Elegance',
      category: 'Soin',
      icon: Icons.spa_outlined,
    ),
    DemoProduct(
      id: 'p5',
      name: 'Cours de marketing',
      priceMru: 1500,
      storeName: 'Academie 9aytek',
      category: 'Cours',
      icon: Icons.school_outlined,
    ),
  ];

  static List<DemoProduct> get influencerCatalog => vendorProducts;
}
