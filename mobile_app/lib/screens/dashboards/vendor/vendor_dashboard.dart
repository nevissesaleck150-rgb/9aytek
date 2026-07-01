import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/api_order.dart';
import '../../../models/api_product.dart';
import '../../../models/users.dart';
import '../../../services/api_service.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../../widgets/editable_profile_tab.dart';
import '../../../widgets/ui_helpers.dart';

class VendorDashboard extends StatefulWidget {
  final User user;
  const VendorDashboard({super.key, required this.user});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final ApiService _api = ApiService();
  int _currentIndex = 0;
  bool _isStoreActive = true;

  List<ApiProduct> _myProducts = [];
  List<ApiOrder> _vendorOrders = [];
  List<Map<String, dynamic>> _marketingRequests = [];
  double _walletBalance = 0.0;
  bool _isLoading = true;

  // Visual Theme Colors
  final Color primaryBlue = AppColors.primaryBlue;
  final Color backgroundWhite = AppColors.background;
  final Color accentBlue = AppColors.lightBlue;
  final Color successGreen = AppColors.primaryBlue;

  @override
  void initState() {
    super.initState();
    _walletBalance = widget.user.walletBalance;
    _refreshData();
  }

  Future<void> _refreshData() async {
    final token = widget.user.token;
    if (token == null) return;
    setState(() => _isLoading = true);

    final profileRes = await _api.getCurrentUser(token);
    final productsRes = await _api.fetchProducts(token);
    final ordersRes = await _api.fetchOrders(token);
    final marketingRes = await _api.fetchMarketingRequests(token);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (profileRes['success'] == true) {
        final w = profileRes['body']['wallet_balance'];
        _walletBalance = double.tryParse(w?.toString() ?? '0') ?? 0.0;
      }
      if (productsRes.isSuccess) {
        // Filter products belonging to this vendor
        _myProducts = (productsRes.data ?? [])
            .where((p) => p.vendorId == widget.user.id)
            .toList();
      }
      if (ordersRes.isSuccess) {
        _vendorOrders = ordersRes.data ?? [];
      }
      if (marketingRes.isSuccess) {
        _marketingRequests = (marketingRes.data ?? [])
            .where((r) => r['status'] == 'pending')
            .toList();
      }
    });
  }

  List<_VendorNotification> get _vendorNotifications {
    final items = <_VendorNotification>[];

    for (final order in _vendorOrders) {
      final myItems = order.items
          .where((item) => item.vendorId == widget.user.id)
          .toList();
      if (myItems.isEmpty) continue;
      final vendorAlreadyReady = myItems.every((item) => item.vendorReady);

      if (order.status == 'paid' && !vendorAlreadyReady) {
        items.add(
          _VendorNotification(
            icon: Icons.receipt_long_outlined,
            title: 'Nouvelle commande client',
            body:
                'Commande ${order.displayId} de ${order.customerName ?? "client"} a preparer.',
            tabIndex: 1,
          ),
        );
      }
    }

    for (final request in _marketingRequests) {
      items.add(
        _VendorNotification(
          icon: Icons.campaign_outlined,
          title: 'Demande marketing',
          body:
              '${_textOf(request['influencer_name'], fallback: 'Influenceur')} veut promouvoir ${_textOf(request['product_name'], fallback: 'un produit')}.',
          tabIndex: 0,
          openMarketing: true,
        ),
      );
    }

    final deliveredOrders = _vendorOrders.where((order) {
      final hasMyItems = order.items.any(
        (item) => item.vendorId == widget.user.id,
      );
      return hasMyItems && order.status == 'delivered';
    }).toList();
    if (_walletBalance > 0 && deliveredOrders.isNotEmpty) {
      items.add(
        _VendorNotification(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Argent recu',
          body:
              'Votre solde disponible est ${_walletBalance.round()} UM apres ${deliveredOrders.length} livraison${deliveredOrders.length == 1 ? '' : 's'}.',
          tabIndex: 2,
        ),
      );
    }

    return items;
  }

  static String _textOf(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  Future<void> _showVendorNotifications() async {
    await _refreshData();
    if (!mounted) return;
    final notifications = _vendorNotifications;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.56,
            minChildSize: 0.34,
            maxChildSize: 0.88,
            builder: (_, controller) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Actualiser',
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _showVendorNotifications();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune nouvelle notification',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final item = notifications[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() => _currentIndex = item.tabIndex);
                                  if (item.openMarketing) {
                                    Future.microtask(_openMarketingRequests);
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.lightBlue,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          item.icon,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.body,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // --- Actions ---
  Future<void> _addProduct() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    XFile? pickedImage;
    final ImagePicker picker = ImagePicker();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Ajouter un produit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Prix (UM)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité en stock',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      pickedImage != null
                          ? 'Image sélectionnée'
                          : 'Ajouter une image',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final img = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (img != null) {
                        setDialogState(() => pickedImage = img);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );

    if (created != true || !mounted) return;

    final token = widget.user.token;
    final name = nameCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
    final desc = descCtrl.text.trim();
    final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

    if (token == null || name.isEmpty || price <= 0) {
      showAppSnack(
        context,
        "Veuillez remplir le nom et le prix du produit",
        type: MessageType.error,
      );
      return;
    }

    final res = await _api.createProduct(
      token,
      name: name,
      description: desc,
      priceMru: price,
      stock: stock,
      imagePath: pickedImage?.path,
    );
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(
        context,
        "Produit ajouté avec succès",
        type: MessageType.success,
      );
      _refreshData();
    } else {
      showAppSnack(
        context,
        "Impossible d'ajouter le produit. Veuillez vérifier les informations.",
        type: MessageType.error,
      );
    }
  }

  Future<void> _editProduct(ApiProduct product) async {
    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(text: product.priceMru.toString());
    final descCtrl = TextEditingController(text: product.description);
    final stockCtrl = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    XFile? pickedImage;
    final ImagePicker picker = ImagePicker();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Modifier le produit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Prix (UM)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité en stock',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      pickedImage != null
                          ? 'Image sélectionnée'
                          : 'Changer l\'image',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final img = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (img != null) {
                        setDialogState(() => pickedImage = img);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final token = widget.user.token;
    if (token == null) return;

    final data = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      'price': int.tryParse(priceCtrl.text.trim()) ?? product.priceMru,
      'description': descCtrl.text.trim(),
      'stock_quantity':
          int.tryParse(stockCtrl.text.trim()) ?? product.stockQuantity,
    };

    final res = await _api.updateProduct(
      token,
      product.id,
      data,
      imagePath: pickedImage?.path,
    );
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(
        context,
        "Produit modifié avec succès",
        type: MessageType.success,
      );
      _refreshData();
    } else {
      showAppSnack(
        context,
        "Impossible de modifier le produit. Veuillez réessayer.",
        type: MessageType.error,
      );
    }
  }

  Future<void> _deleteProduct(ApiProduct product) async {
    final token = widget.user.token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Voulez-vous vraiment supprimer ${product.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final res = await _api.deleteProduct(token, product.id);
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(context, "Produit supprimé", type: MessageType.success);
      _refreshData();
    } else {
      showAppSnack(
        context,
        "Impossible de terminer l'opération. Veuillez réessayer.",
        type: MessageType.error,
      );
    }
  }

  Future<void> _markOrderReady(ApiOrder order) async {
    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.updateOrderStatus(token, order.id, 'ready');
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(
        context,
        "Commande marquée prête pour livraison",
        type: MessageType.success,
      );
      _refreshData();
    } else {
      showAppSnack(
        context,
        "Impossible de terminer l'opération. Veuillez réessayer.",
        type: MessageType.error,
      );
    }
  }

  void _openMarketingRequests() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Demandes de Marketing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ces influenceurs souhaitent promouvoir vos produits :',
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _marketingRequests.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune demande en attente',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _marketingRequests.length,
                      itemBuilder: (context, index) {
                        final req = _marketingRequests[index];
                        final infName = req['influencer_name'] ?? 'Influenceur';
                        final prodName = req['product_name'] ?? 'Produit';
                        final prodImage = req['product_image'] as String?;
                        final reqId = req['id'] ?? 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: prodImage != null && prodImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: prodImage,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: accentBlue,
                                        child: Icon(
                                          Icons.campaign_outlined,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: accentBlue,
                                      child: Icon(
                                        Icons.campaign_outlined,
                                        color: primaryBlue,
                                      ),
                                    ),
                            ),
                            title: Text(
                              infName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Produit: $prodName'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onPressed: () async {
                                    final token = widget.user.token;
                                    if (token == null) return;
                                    final navigator = Navigator.of(ctx);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await _api.rejectMarketingRequest(
                                      token,
                                      reqId is int ? reqId : 0,
                                    );
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Demande refusée'),
                                      ),
                                    );
                                    _refreshData();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onPressed: () async {
                                    final token = widget.user.token;
                                    if (token == null) return;
                                    final navigator = Navigator.of(ctx);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await _api.acceptMarketingRequest(
                                      token,
                                      reqId is int ? reqId : 0,
                                    );
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: const Text('Demande acceptée'),
                                        backgroundColor: successGreen,
                                      ),
                                    );
                                    _refreshData();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-pages Layout ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Bienvenue, ${widget.user.displayName}',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Badge(
                isLabelVisible: _vendorNotifications.isNotEmpty,
                label: Text('${_vendorNotifications.length}'),
                backgroundColor: Colors.red,
                textColor: Colors.white,
                child: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.black,
                ),
              ),
              onPressed: _showVendorNotifications,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Boutique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildShopTab(),
                _buildOrdersTab(),
                _buildStatsTab(),
                _buildProfileTab(),
              ],
            ),
    );
  }

  // --- Shop Tab ---
  Widget _buildShopTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Marketing request trigger & Store toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.campaign_outlined),
                label: Text(
                  'Demandes Marketing (${_marketingRequests.length})',
                ),
                onPressed: _openMarketingRequests,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isStoreActive ? 'Boutique Active' : 'Boutique Inactive',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Switch(
                    value: _isStoreActive,
                    activeThumbColor: successGreen,
                    onChanged: (v) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: const Text(
                            'Confirmation',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          content: Text(
                            v
                                ? 'Voulez-vous activer votre boutique et la rendre visible aux clients ?'
                                : 'Voulez-vous désactiver votre boutique et la masquer aux clients ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Confirmer'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        setState(() => _isStoreActive = v);
                        showAppSnack(
                          context,
                          v ? 'Boutique activée' : 'Boutique désactivée',
                          type: MessageType.success,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes articles en vente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_box_outlined,
                  color: primaryBlue,
                  size: 28,
                ),
                onPressed: _addProduct,
              ),
            ],
          ),
          const SizedBox(height: 12),

          _myProducts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Aucun produit enregistré pour le moment',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myProducts.length,
                  itemBuilder: (context, idx) {
                    final p = _myProducts[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: p.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: p.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: accentBlue,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: accentBlue,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppColors.lightBlue,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: accentBlue,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: primaryBlue,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          p.stockQuantity > 0
                              ? '${p.priceMru} UM · Stock: ${p.stockQuantity}'
                              : '${p.priceMru} UM · Rupture de stock',
                          style: TextStyle(
                            color: p.stockQuantity > 0
                                ? null
                                : AppColors.primaryBlue,
                            fontWeight: p.stockQuantity > 0
                                ? null
                                : FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              onPressed: () => _editProduct(p),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.primaryBlue,
                              ),
                              onPressed: () => _deleteProduct(p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // --- Orders Tab ---
  Widget _buildOrdersTab() {
    final paidOrders = _vendorOrders.where((o) => o.status == 'paid').toList();
    final preparedOrders = _vendorOrders
        .where(
          (o) =>
              o.status == 'ready' ||
              o.status == 'on_way' ||
              o.status == 'arrived',
        )
        .toList();
    final deliveredOrders = _vendorOrders
        .where((o) => o.status == 'delivered')
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (paidOrders.isNotEmpty) ...[
            const Text(
              'Commandes à préparer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            ...paidOrders.map((o) => _buildOrderTile(o, true)),
            const SizedBox(height: 20),
          ],
          if (preparedOrders.isNotEmpty) ...[
            const Text(
              'Prêtes / En cours de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            ...preparedOrders.map((o) => _buildOrderTile(o, false)),
            const SizedBox(height: 20),
          ],
          if (deliveredOrders.isNotEmpty) ...[
            const Text(
              'Livrées',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            ...deliveredOrders.map((o) => _buildOrderTile(o, false)),
          ],
          if (_vendorOrders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'Aucune commande client reçue',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(ApiOrder order, bool canPrepare) {
    final vendorId = widget.user.id;
    // Show only items belonging to this vendor
    final myItems = order.items.where((i) => i.vendorId == vendorId).toList();
    // Check if this vendor has already marked their items ready
    final vendorAlreadyReady =
        myItems.isNotEmpty && myItems.every((i) => i.vendorReady);
    // Multi-vendor progress
    final hasMultipleVendors = order.vendorsTotal > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande ${order.displayId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${order.totalMru} UM',
                  style: TextStyle(
                    color: successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Client: ${order.customerName ?? "Inconnu"}',
              style: const TextStyle(color: Colors.black, fontSize: 13),
            ),
            const SizedBox(height: 8),
            // Show only vendor's own items
            ...myItems.map(
              (item) => Row(
                children: [
                  Expanded(
                    child: Text(
                      '- ${item.quantity} x ${item.itemName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (item.vendorReady)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Prêt',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Multi-vendor progress indicator
            if (hasMultipleVendors && order.status == 'paid') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: order.allVendorsReady
                      ? successGreen.withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.allVendorsReady
                      ? 'Tous les marchands sont prêts !'
                      : 'Marchands prêts: ${order.vendorsReady}/${order.vendorsTotal}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: order.allVendorsReady
                        ? successGreen
                        : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
            if (canPrepare && !vendorAlreadyReady) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: primaryBlue),
                  onPressed: () => _markOrderReady(order),
                  child: const Text('Prête'),
                ),
              ),
            ],
            if (vendorAlreadyReady) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: successGreen, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Préparée',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Stats Tab ---
  Widget _buildStatsTab() {
    final orderCount = _vendorOrders.length;
    final totalSales = _vendorOrders
        .where((o) => o.status == 'delivered')
        .fold(0, (sum, o) => sum + o.totalMru);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Analyse de la Boutique',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            children: [
              _buildStatCard(
                'Commandes',
                '$orderCount',
                Icons.receipt_long_outlined,
              ),
              _buildStatCard(
                'Solde disponible',
                '${_walletBalance.round()} UM',
                Icons.account_balance_wallet_outlined,
              ),
              _buildStatCard(
                'Produits actifs',
                '${_myProducts.length}',
                Icons.inventory_2_outlined,
              ),
              _buildStatCard(
                'Ventes livrées',
                '$totalSales UM',
                Icons.trending_up_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          WeeklyEarningsChart(
            orders: _vendorOrders,
            title: 'Ventes de la semaine',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: primaryBlue, size: 20),
              const SizedBox(width: 4),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Profile Tab ---
  Widget _buildProfileTab() {
    return EditableProfileTab(
      initialUser: widget.user,
      primaryBlue: primaryBlue,
      accentBlue: accentBlue,
    );
  }
}

class _VendorNotification {
  final IconData icon;
  final String title;
  final String body;
  final int tabIndex;
  final bool openMarketing;

  const _VendorNotification({
    required this.icon,
    required this.title,
    required this.body,
    required this.tabIndex,
    this.openMarketing = false,
  });
}
