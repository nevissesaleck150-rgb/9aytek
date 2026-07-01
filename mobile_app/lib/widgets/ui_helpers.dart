import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/demo_models.dart';
import '../theme/app_theme.dart';

enum MessageType { success, error, warning, info }

void showAppSnack(
  BuildContext context,
  String message, {
  MessageType type = MessageType.info,
  Color? color,
}) {
  Color backgroundColor;
  if (color != null) {
    backgroundColor = color;
  } else {
    switch (type) {
      case MessageType.success:
        backgroundColor = AppColors.success;
      case MessageType.error:
        backgroundColor = Colors.red;
      case MessageType.warning:
        backgroundColor = Colors.red;
      case MessageType.info:
        backgroundColor = AppColors.primaryBlue;
    }
  }
  final textColor = type == MessageType.error || type == MessageType.warning
      ? Colors.black
      : Colors.white;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 6,
    ),
  );
}

Future<void> showNotificationsSheet(
  BuildContext context,
  List<DemoNotification> items,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'Pas de nouvelles notifications',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              controller: controller,
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final n = items[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: n.read
                                        ? AppColors.lightBlue
                                        : AppColors.primaryBlue,
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: n.read
                                          ? AppColors.primaryBlue
                                          : Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(n.body),
                                  onTap: () {
                                    setModalState(() => n.read = true);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String initial = '',
}) async {
  final ctrl = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}

Future<void> showShareLinkDialog(BuildContext context, String link) async {
  await showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        title: const Text('Mon lien de boutique'),
        content: SelectableText(link),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(ctx);
              showAppSnack(context, 'Lien copié');
            },
            child: const Text('Copier'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    ),
  );
}

Future<DemoProduct?> showAddProductDialog(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final result = await showDialog<DemoProduct>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        title: const Text('Ajouter un produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du produit'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix (MRU)'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Image (optionnelle) - sélection à venir',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              if (name.isEmpty || price <= 0) return;
              Navigator.pop(
                ctx,
                DemoProduct(
                  id: 'local_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  priceMru: price,
                  storeName: 'Mon magasin',
                  category: 'Général',
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    ),
  );
  nameCtrl.dispose();
  priceCtrl.dispose();
  return result;
}

void showMapMockDialog(BuildContext context, {required String orderId}) {
  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        title: Text('Trajet du colis $orderId'),
        content: SizedBox(
          height: 220,
          width: double.maxFinite,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(height: 12),
                Text(
                  'Simulation de trajet',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Boutique → Point de collecte → Client',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    ),
  );
}
