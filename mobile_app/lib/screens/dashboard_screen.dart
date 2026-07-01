import 'package:flutter/material.dart';
import '../models/users.dart';
import '../theme/app_theme.dart';
import '../utils/role_router.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/ui_helpers.dart';

/// Simplified admin dashboard. Full administration is available in React Web.
class DashboardScreen extends StatelessWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tableau d\'administration')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WelcomeHeader(
              username: user.username,
              subtitle:
                  'Utilisez le tableau React Web pour l\'administration complete',
            ),
            const SizedBox(height: 24),
            QuickActionTile(
              title: 'Gestion de la plateforme',
              subtitle: 'Utilisateurs, commandes et finance via le web',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => showAppSnack(
                context,
                'Utilisez le tableau React Web pour l\'administration complete',
                type: MessageType.info,
              ),
            ),
            const SizedBox(height: 12),
            QuickActionTile(
              title: 'Cours et contenu',
              subtitle: 'Publier et gerer le contenu payant',
              icon: Icons.school_outlined,
              onTap: () => showAppSnack(
                context,
                'Gestion des cours depuis le tableau web',
                type: MessageType.info,
              ),
            ),
            const SizedBox(height: 12),
            QuickActionTile(
              title: 'Profil',
              subtitle: 'Parametres et deconnexion',
              icon: Icons.person_outline,
              onTap: () => RoleRouter.confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
