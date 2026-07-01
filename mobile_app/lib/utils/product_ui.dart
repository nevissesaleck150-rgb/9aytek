import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

IconData iconForProduct(String name, String description) {
  final t = '$name $description'.toLowerCase();
  if (t.contains('phone') ||
      t.contains('telephone') ||
      t.contains('smartphone')) {
    return Icons.smartphone_outlined;
  }
  if (t.contains('audio') || t.contains('casque') || t.contains('ecouteur')) {
    return Icons.headphones_outlined;
  }
  if (t.contains('robe') || t.contains('mode') || t.contains('vetement')) {
    return Icons.checkroom_outlined;
  }
  if (t.contains('parfum')) return Icons.spa_outlined;
  if (t.contains('cours') || t.contains('course') || t.contains('formation')) {
    return Icons.school_outlined;
  }
  return Icons.shopping_bag_outlined;
}

String statusLabelAr(String status) {
  return statusLabelFr(status);
}

String statusLabelFr(String status) {
  switch (status) {
    case 'pending':
      return 'En attente de paiement';
    case 'paid':
      return 'Paye';
    case 'ready':
      return 'Pret';
    case 'on_way':
      return 'En route';
    case 'arrived':
      return 'Arrive chez le client';
    case 'delivered':
      return 'Livre';
    default:
      return status;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.primaryBlue;
    case 'paid':
      return AppColors.primaryBlue;
    case 'ready':
      return AppColors.primaryBlue;
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

String? nextStatus(String status) {
  const flow = ['pending', 'paid', 'ready', 'on_way', 'arrived', 'delivered'];
  final i = flow.indexOf(status);
  if (i < 0 || i >= flow.length - 1) return null;
  return flow[i + 1];
}
