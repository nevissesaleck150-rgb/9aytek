import 'package:flutter/material.dart';

class ShopCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  ShopCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

final List<ShopCategory> shopCategories = [
  ShopCategory(
    id: 'food',
    name: 'Alimentation et boissons',
    description: 'Restaurants, cafés et jus',
    icon: Icons.restaurant_outlined,
  ),
  ShopCategory(
    id: 'home',
    name: 'Articles ménagers',
    description: 'Articles ménagers et décoration',
    icon: Icons.home_outlined,
  ),
  ShopCategory(
    id: 'supermarket',
    name: 'Supermarché et produits alimentaires',
    description: 'Produits alimentaires et épices',
    icon: Icons.shopping_cart_outlined,
  ),
  ShopCategory(
    id: 'fashion',
    name: 'Mode et vêtements',
    description: 'Vêtements, chaussures et accessoires',
    icon: Icons.shopping_bag_outlined,
  ),
  ShopCategory(
    id: 'electronics',
    name: 'Électronique et technologie',
    description: 'Appareils électroniques et accessoires',
    icon: Icons.devices_outlined,
  ),
];
