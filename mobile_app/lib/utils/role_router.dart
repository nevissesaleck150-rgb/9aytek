import 'package:flutter/material.dart';
import '../models/users.dart';
import '../screens/dashboards/admin/admin_dashboard.dart';
import '../screens/dashboards/customer/customer_dashboard.dart';
import '../screens/dashboards/courier/courier_dashboard.dart';
import '../screens/dashboards/influencer/influencer_dashboard.dart';
import '../screens/dashboards/vendor/vendor_dashboard.dart';
import '../screens/login_screen.dart';

class RoleRouter {
  static Widget dashboardFor(User user) {
    switch (user.role) {
      case 'vendor':
        return VendorDashboard(user: user);
      case 'influencer':
        return InfluencerDashboard(user: user);
      case 'driver':
        return CourierDashboard(user: user);
      case 'admin':
        return AdminDashboard(user: user);
      default:
        return CustomerDashboard(user: user);
    }
  }

  static void logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static Future<void> confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      logout(context);
    }
  }
}
