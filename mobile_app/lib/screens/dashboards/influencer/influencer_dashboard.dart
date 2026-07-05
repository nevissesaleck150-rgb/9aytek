import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../../config/api_config.dart';
import '../../../models/api_order.dart';
import '../../../models/api_product.dart';
import '../../../models/api_shop.dart';
import '../../../models/influencer_ad.dart';
import '../../../models/users.dart';
import '../../../services/api_service.dart';
import '../../../models/notification_item.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../../widgets/editable_profile_tab.dart';
import '../../../widgets/ui_helpers.dart';

class InfluencerDashboard extends StatefulWidget {
  final User user;
  const InfluencerDashboard({super.key, required this.user});

  @override
  State<InfluencerDashboard> createState() => _InfluencerDashboardState();
}

class _InfluencerDashboardState extends State<InfluencerDashboard> {
  final ApiService _api = ApiService();
  int _currentIndex = 0;
  final TextEditingController _storeSearchCtrl = TextEditingController();
  String _storeSearchQuery = '';

  List<ApiProduct> _allProducts = [];
  List<ApiProduct> _myCuratedProducts = [];
  List<ApiShop> _shops = [];
  List<InfluencerAd> _myAds = [];
  List<ApiOrder> _myOrders = [];
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
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
    _storeSearchCtrl.addListener(() {
      setState(() {
        _storeSearchQuery = _storeSearchCtrl.text.trim().toLowerCase();
      });
    });
    _refreshData();
  }

  @override
  void dispose() {
    _storeSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final token = widget.user.token;
    if (token == null) return;
    setState(() => _isLoading = true);

    final profileRes = await _api.getCurrentUser(token);
    final productsRes = await _api.fetchProducts(token);
    final shopsRes = await _api.fetchShops(token);
    final adsRes = await _api.fetchInfluencerAds(token);
    final acceptedRes = await _api.fetchAcceptedProducts(token);
    final ordersRes = await _api.fetchOrders(token);
    final notifRes = await _api.fetchNotifications(token);
    final unread = await _api.fetchUnreadNotifCount(token);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (profileRes['success'] == true) {
        final w = profileRes['body']['wallet_balance'];
        _walletBalance = double.tryParse(w?.toString() ?? '0') ?? 0.0;
      }
      if (productsRes.isSuccess) _allProducts = productsRes.data ?? [];
      if (shopsRes.isSuccess) _shops = shopsRes.data ?? [];
      if (adsRes.isSuccess) _myAds = adsRes.data ?? [];
      if (acceptedRes.isSuccess) {
        _myCuratedProducts = (acceptedRes.data ?? [])
            .map((e) => ApiProduct.fromJson(e))
            .toList();
      }
      if (ordersRes.isSuccess) _myOrders = ordersRes.data ?? [];
      if (notifRes.isSuccess) _notifications = notifRes.data ?? [];
      _unreadCount = unread;
    });
  }

  // Get distinct stores
  // Returns the display name for a vendor: shop name if available, else vendorName.
  String _displayNameForVendor(int vendorId, String fallbackVendorName) {
    final shop = _shops.cast<ApiShop?>().firstWhere(
      (s) => s!.vendorId == vendorId && s.name.isNotEmpty,
      orElse: () => null,
    );
    return shop?.name ?? fallbackVendorName;
  }

  List<String> get _filteredStores {
    final stores = _allProducts
        .map((p) => _displayNameForVendor(p.vendorId, p.vendorName))
        .toSet()
        .toList();
    if (_storeSearchQuery.isNotEmpty) {
      return stores
          .where((s) => s.toLowerCase().contains(_storeSearchQuery))
          .toList();
    }
    return stores;
  }

  String? _shopImageForStore(String storeName) {
    final shop = _shops.cast<ApiShop?>().firstWhere(
      (s) => s!.name == storeName,
      orElse: () => null,
    );
    final image = shop?.image;
    return image != null && image.isNotEmpty ? image : null;
  }

  String get _influencerLink => 'https://9aytek.app/i/${widget.user.username}';

  void _copyStoreLink() {
    Clipboard.setData(ClipboardData(text: _influencerLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lien copié: $_influencerLink'),
        backgroundColor: successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestPromotion(ApiProduct product) async {
    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.createMarketingRequest(token, product.id);
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(
        context,
        "Demande envoyée au vendeur !",
        type: MessageType.success,
      );
    } else {
      final err = res.error ?? '';
      if (err.contains('unique') || err.contains('already') || err.contains('already_requested')) {
        showAppSnack(
          context,
          "Vous avez déjà demandé ce produit",
          type: MessageType.warning,
        );
      } else {
        showAppSnack(
          context,
          "Impossible d'envoyer la demande. Veuillez réessayer.",
          type: MessageType.error,
        );
      }
    }
  }

  void _removeCuratedProduct(ApiProduct product) async {
    // No direct API for this yet, just remove locally
    setState(() {
      _myCuratedProducts.removeWhere((p) => p.id == product.id);
    });
    showAppSnack(
      context,
      "Produit retiré de votre espace",
      type: MessageType.success,
    );
  }

  // --- Notifications ---
  void _openNotificationsSheet() async {
    final token = widget.user.token;
    if (token != null) {
      await _api.markAllNotificationsRead(token);
      if (mounted) setState(() => _unreadCount = 0);
    }
    if (!mounted) return;

    final notifications = List<NotificationItem>.from(_notifications);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.56,
          minChildSize: 0.34,
          maxChildSize: 0.88,
          builder: (_, controller) => Column(
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
                    Expanded(
                      child: const Text(
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
                        await _refreshData();
                        if (mounted) _openNotificationsSheet();
                      },
                      icon: Icon(Icons.refresh, color: AppColors.primaryBlue),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: notifications.length,
                        itemBuilder: (_, i) =>
                            _buildNotifTile(notifications[i], ctx),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifTile(NotificationItem n, BuildContext sheetCtx) {
    IconData icon;
    int targetTab;
    switch (n.type) {
      case 'marketing_accepted':
        icon = Icons.handshake_outlined;
        targetTab = 1; // Mon Espace
        break;
      case 'ad_purchase':
        icon = Icons.campaign_outlined;
        targetTab = 1; // Mon Espace
        break;
      case 'wallet_credit':
        icon = Icons.account_balance_wallet_outlined;
        targetTab = 2; // Statistiques
        break;
      default:
        icon = Icons.notifications_outlined;
        targetTab = 1;
    }

    final buyerPhone = n.data['buyer_phone'] as String?;

    return InkWell(
      onTap: () {
        Navigator.pop(sheetCtx);
        setState(() => _currentIndex = targetTab);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBlue),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (buyerPhone != null && buyerPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          buyerPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modal Sheets ---
  void _exploreStore(String storeName) {
    final storeProducts = _allProducts
        .where((p) => _displayNameForVendor(p.vendorId, p.vendorName) == storeName)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produits de $storeName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: storeProducts.length,
                  itemBuilder: (context, idx) {
                    final product = storeProducts[idx];
                    final isPromoted = _myCuratedProducts.any(
                      (p) => p.id == product.id,
                    );
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: accentBlue,
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: primaryBlue,
                                  ),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: accentBlue,
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: primaryBlue,
                                ),
                              ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('${product.priceMru} UM'),
                      trailing: isPromoted
                          ? const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primaryBlue,
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: primaryBlue,
                              ),
                              tooltip: 'Promouvoir',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _requestPromotion(product);
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
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
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black,
                  ),
                  onPressed: _openNotificationsSheet,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
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
            icon: Icon(Icons.search_outlined),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Mon Espace',
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
                _buildSearchTab(),
                _buildCuratedShopTab(),
                _buildStatsTab(),
                _buildProfileTab(),
              ],
            ),
    );
  }

  // --- Search Tab ---
  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _storeSearchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un magasin...',
                      prefixIcon: Icon(
                        Icons.search_outlined,
                        color: primaryBlue,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Boutiques des vendeurs partenaires',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredStores.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun magasin trouvé',
                      style: TextStyle(color: Colors.black),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredStores.length,
                    itemBuilder: (context, index) {
                      final storeName = _filteredStores[index];
                      final imageUrl = ApiConfig.mediaUrl(
                        _shopImageForStore(storeName),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.storefront_outlined,
                                            color: primaryBlue,
                                          ),
                                    )
                                  : Icon(
                                      Icons.storefront_outlined,
                                      color: primaryBlue,
                                    ),
                            ),
                          ),
                          title: Text(
                            storeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Vendeur certifié'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _exploreStore(storeName),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Curated Shop Tab ---
  Widget _buildCuratedShopTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mon Magasin Partagé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Lien public: $_influencerLink',
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy_outlined, size: 18),
                onPressed: _copyStoreLink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddAdDialog,
              icon: const Icon(Icons.add),
              label: const Text(
                'Ajouter Annonce',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _myAds.isEmpty && _myCuratedProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style_outlined,
                          size: 64,
                          color: AppColors.lightBlue,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun contenu publié',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      if (_myAds.isNotEmpty) ...[
                        const Text(
                          'Annonces',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._myAds.map((ad) => _buildAdCard(ad)),
                        const SizedBox(height: 16),
                      ],
                      if (_myCuratedProducts.isNotEmpty) ...[
                        const Text(
                          'Produits Promus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._myCuratedProducts.map(
                          (product) => _buildProductCard(product),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(InfluencerAd ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(
          Icons.campaign_outlined,
          color: AppColors.primaryBlue,
          size: 24,
        ),
        title: Text(
          ad.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${ad.priceMru} UM',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.primaryBlue),
          onPressed: () => _deleteAd(ad.id),
        ),
      ),
    );
  }

  Widget _buildProductCard(ApiProduct product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: accentBlue,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: primaryBlue,
                    ),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: accentBlue,
                  child: Icon(Icons.shopping_bag_outlined, color: primaryBlue),
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${product.priceMru} UM · Com. estimée: 15%'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.primaryBlue),
          onPressed: () => _removeCuratedProduct(product),
        ),
      ),
    );
  }

  void _openAddAdDialog() {
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une Annonce'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description de l\'annonce',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix (MRU)'),
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
              final desc = descCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              if (desc.isEmpty || price <= 0) {
                showAppSnack(
                  context,
                  'Veuillez remplir tous les champs',
                  type: MessageType.error,
                );
                return;
              }
              Navigator.pop(ctx);
              _createAd(desc, price);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAd(String description, int price) async {
    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.createInfluencerAd(
      token,
      description: description,
      price: price,
    );
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() => _myAds.add(res.data!));
      showAppSnack(
        context,
        'Annonce créée avec succès',
        type: MessageType.success,
      );
    } else {
      showAppSnack(
        context,
        "Impossible de créer l'annonce. Veuillez réessayer.",
        type: MessageType.error,
      );
    }
  }

  Future<void> _deleteAd(int adId) async {
    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.deleteInfluencerAd(token, adId);
    if (!mounted) return;

    if (res.isSuccess) {
      setState(() => _myAds.removeWhere((ad) => ad.id == adId));
      showAppSnack(context, 'Annonce supprimée', type: MessageType.success);
    } else {
      showAppSnack(
        context,
        "Impossible de supprimer l'annonce. Veuillez réessayer.",
        type: MessageType.error,
      );
    }
  }

  // --- Stats Tab ---
  Widget _buildStatsTab() {
    const visits = 425; // Simulator stats
    final soldCount = _myCuratedProducts.length;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Performance Marketing',
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
              childAspectRatio: 1.5,
            ),
            children: [
              _buildStatCard(
                'Commandes affiliées',
                '$soldCount',
                Icons.receipt_long_outlined,
              ),
              _buildStatCard(
                'Solde commissions',
                '${_walletBalance.round()} UM',
                Icons.account_balance_wallet_outlined,
              ),
              _buildStatCard(
                'Produits promus',
                '${_myCuratedProducts.length}',
                Icons.inventory_2_outlined,
              ),
              _buildStatCard(
                'Visites générées',
                '$visits',
                Icons.visibility_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          WeeklyEarningsChart(
            orders: _myOrders,
            title: 'Commissions de la semaine',
            color: primaryBlue,
            useInfluencerEarnings: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryBlue, size: 18),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 10),
              maxLines: 1,
            ),
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
