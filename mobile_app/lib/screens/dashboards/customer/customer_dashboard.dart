import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/api_config.dart';
import '../../../models/api_order.dart';
import '../../../models/api_product.dart';
import '../../../models/api_shop.dart';
import '../../../models/influencer_ad.dart';
import '../../../models/shop_categories.dart';
import '../../../models/users.dart';
import 'customer_payment_page.dart';
import '../../../services/api_service.dart';
import '../../../utils/bankily_split.dart';
import '../../../widgets/editable_profile_tab.dart';
import '../../../widgets/ui_helpers.dart';

class CustomerDashboard extends StatefulWidget {
  final User user;
  const CustomerDashboard({super.key, required this.user});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final ApiService _api = ApiService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<ApiProduct> _products = [];
  List<ApiShop> _shops = [];
  List<Map<String, dynamic>> _digitalServices = [];
  List<ApiOrder> _orders = [];
  final List<CartItem> _cart = [];
  final Set<int> _favorites = {};
  final Set<int> _selectedCartItems = {};

  String get _favoritesStorageKey =>
      'customer_favorites_${widget.user.id}_${widget.user.username}';
  List<Map<String, dynamic>> _influencerUsers = [];

  bool _loadingProducts = true;
  bool _loadingOrders = false;
  bool _showFavoritesOnly = false;

  // Visual Theme Colors
  final Color primaryBlue = AppColors.primaryBlue;
  final Color backgroundWhite = AppColors.background;
  final Color accentBlue = AppColors.lightBlue;
  final Color successGreen = AppColors.primaryBlue;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _restoreCart();
    _restoreFavorites();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadProducts(),
      _loadShops(),
      _loadDigitalServices(),
      _loadOrders(),
      _loadInfluencers(),
    ]);
  }

  String get _cartStorageKey =>
      'customer_cart_${widget.user.id}_${widget.user.username}';

  Future<void> _persistCart() async {
    try {
      final payload = _cart.map((item) => item.toJson()).toList();
      await _storage.write(key: _cartStorageKey, value: jsonEncode(payload));
    } catch (_) {
      // Ignore local storage failures to avoid interrupting the UI flow.
    }
  }

  Future<void> _restoreCart() async {
    try {
      final raw = await _storage.read(key: _cartStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = decoded
          .whereType<Map>()
          .map((entry) => CartItem.fromJson(Map<String, dynamic>.from(entry)))
          .toList();
      if (!mounted) return;
      setState(() {
        _cart
          ..clear()
          ..addAll(restored);
        _selectedCartItems
          ..clear()
          ..addAll(List.generate(_cart.length, (index) => index));
      });
    } catch (_) {
      // Ignore invalid cached cart content.
    }
  }

  Future<void> _persistFavorites() async {
    try {
      await _storage.write(
        key: _favoritesStorageKey,
        value: jsonEncode(_favorites.toList()),
      );
    } catch (_) {}
  }

  Future<void> _restoreFavorites() async {
    try {
      final raw = await _storage.read(key: _favoritesStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      if (!mounted) return;
      setState(() {
        _favorites
          ..clear()
          ..addAll(decoded.whereType<int>());
      });
    } catch (_) {}
  }

  Future<void> _loadInfluencers() async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.fetchUsers(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) {
        final allUsers = res.data ?? [];
        _influencerUsers = allUsers
            .where((u) => u['role'] == 'influencer')
            .toList();
      }
    });
  }

  Future<void> _loadProducts() async {
    final token = widget.user.token;
    if (token == null) return;
    setState(() => _loadingProducts = true);
    final res = await _api.fetchProducts(token);
    if (!mounted) return;
    setState(() {
      _loadingProducts = false;
      if (res.isSuccess) {
        _products = res.data ?? [];
      }
    });
  }

  Future<void> _loadDigitalServices() async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.fetchDigitalServices(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) {
        _digitalServices = res.data ?? [];
      }
    });
  }

  Future<void> _loadShops() async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.fetchShops(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) {
        _shops = _uniqueShops(res.data ?? []);
      }
    });
  }

  List<ApiShop> _uniqueShops(List<ApiShop> shops) {
    final seen = <String>{};
    return shops.where((shop) {
      final key = shop.id > 0
          ? 'shop:${shop.id}'
          : 'vendor:${shop.vendorId}:${shop.name.trim().toLowerCase()}:${shop.category.trim().toLowerCase()}';
      return seen.add(key);
    }).toList();
  }

  String _normalizeShopCategory(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';
    if (shopCategories.any((category) => category.id == value)) return value;
    if (value.contains('mode') ||
        value.contains('vêtement') ||
        value.contains('vetement') ||
        value.contains('vÃªtement') ||
        value.contains('v�tement') ||
        value.contains('fashion')) {
      return 'fashion';
    }
    if (value.contains('aliment') ||
        value.contains('boisson') ||
        value.contains('restaurant') ||
        value.contains('café') ||
        value.contains('caf')) {
      return 'food';
    }
    if (value.contains('ménager') ||
        value.contains('menager') ||
        value.contains('mÃ©nager') ||
        value.contains('m�nager') ||
        value.contains('maison') ||
        value.contains('home')) {
      return 'home';
    }
    if (value.contains('supermarch') ||
        value.contains('produits alimentaire') ||
        value.contains('épice') ||
        value.contains('epice')) {
      return 'supermarket';
    }
    if (value.contains('électron') ||
        value.contains('electron') ||
        value.contains('technologie') ||
        value.contains('tech')) {
      return 'electronics';
    }
    return value;
  }

  Future<void> _loadOrders() async {
    final token = widget.user.token;
    if (token == null) return;
    setState(() => _loadingOrders = true);
    final res = await _api.fetchOrders(token);
    if (!mounted) return;
    setState(() {
      _loadingOrders = false;
      if (res.isSuccess) {
        _orders = res.data ?? [];
      }
    });
  }

  List<_CustomerOrderNotification> get _orderNotifications {
    final items = <_CustomerOrderNotification>[];
    for (final order in _orders) {
      final isTopupOrder = order.items.any((item) => item.itemType == 'topup');
      final isCourseOrder = order.items.any(
        (item) => item.itemType == 'course',
      );
      if (isTopupOrder || isCourseOrder || order.status == 'delivered') {
        continue;
      }

      final hasDriver = order.driverId != null || order.driverInfo != null;
      final orderLabel = 'Commande ${order.displayId}';

      if (order.status == 'arrived') {
        items.add(
          _CustomerOrderNotification(
            icon: Icons.location_on_outlined,
            title: 'Le livreur est arrive',
            body: '$orderLabel est arrivee. Confirmez la reception.',
          ),
        );
      } else if (order.status == 'on_way' ||
          (order.status == 'ready' && hasDriver)) {
        final driverName = _driverNameFor(order);
        items.add(
          _CustomerOrderNotification(
            icon: Icons.delivery_dining_outlined,
            title: 'Commande prise par le livreur',
            body: driverName.isEmpty
                ? '$orderLabel est avec le livreur.'
                : '$orderLabel est avec $driverName.',
          ),
        );
      } else if (order.status == 'ready') {
        items.add(
          _CustomerOrderNotification(
            icon: Icons.check_circle_outline,
            title: 'Commande prete',
            body: '$orderLabel est prete et attend un livreur.',
          ),
        );
      }
    }
    return items;
  }

  String _driverNameFor(ApiOrder order) {
    final infoName = order.driverInfo?.fullName.trim() ?? '';
    if (infoName.isNotEmpty) return infoName;
    return order.driverName?.trim() ?? '';
  }

  Future<void> _showOrderNotifications() async {
    await _loadOrders();
    if (!mounted) return;
    final notifications = _orderNotifications;

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
            initialChildSize: 0.52,
            minChildSize: 0.32,
            maxChildSize: 0.85,
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
                            await _showOrderNotifications();
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
                                  setState(() => _currentIndex = 2);
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

  Future<void> _searchByImage() async {
    final token = widget.user.token;
    if (token == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    final navigator = Navigator.of(context);
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _api.searchProductsByImage(token, image.path);
    if (!mounted) return;
    navigator.pop(); // dismiss loading

    if (!res.isSuccess) {
      showAppSnack(
        context,
        'Impossible de terminer la recherche. Veuillez réessayer.',
        type: MessageType.error,
      );
      return;
    }

    final results = res.data ?? [];
    if (results.isEmpty) {
      // No match found
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.search_off, color: AppColors.primaryBlue, size: 28),
              const SizedBox(width: 8),
              const Text('Non trouvé'),
            ],
          ),
          content: const Text(
            'Aucun produit correspondant à cette image n\'a été trouvé sur la plateforme.',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show matching products in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: successGreen, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${results.length} produit${results.length > 1 ? 's' : ''} trouvé${results.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: results.length,
                  itemBuilder: (context, idx) {
                    final product = results[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: product.imageUrl != null
                              ? () => _showProductImage(
                                  product.imageUrl!,
                                  product.name,
                                  description: product.description,
                                )
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: accentBlue,
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    color: accentBlue,
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: primaryBlue,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${product.priceMru} UM — ${product.vendorName}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add_shopping_cart_outlined,
                            color: successGreen,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _addToCart(product);
                            showAppSnack(
                              context,
                              '${product.name} ajouté au panier',
                              type: MessageType.success,
                            );
                          },
                        ),
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

  // Helpers
  int get _cartTotal {
    if (_selectedCartItems.isEmpty) {
      return _cart.fold(0, (sum, item) => sum + item.subtotal);
    }
    return _cart
        .asMap()
        .entries
        .where((e) => _selectedCartItems.contains(e.key))
        .fold(0, (sum, e) => sum + e.value.subtotal);
  }

  List<ApiProduct> get _filteredProducts {
    List<ApiProduct> list = _products;
    if (_showFavoritesOnly) {
      list = list.where((p) => _favorites.contains(p.id)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery) ||
                p.vendorName.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }
    return list;
  }

  // --- Actions ---
  void _addToCart(
    ApiProduct product, {
    int? influencerId,
    bool isAd = false,
    String? adPhone,
  }) {
    setState(() {
      final index = _cart.indexWhere(
        (item) =>
            item.product?.id == product.id &&
            item.digitalService == null &&
            item.influencerId == influencerId &&
            item.isAd == isAd,
      );
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(
          CartItem(
            product: product,
            influencerId: influencerId,
            isAd: isAd,
            adPhone: adPhone,
          ),
        );
        _selectedCartItems.add(_cart.length - 1);
      }
    });
    _persistCart();
    showAppSnack(
      context,
      '${product.name} ajouté au panier',
      type: MessageType.success,
    );
  }

  void _addTopupToCart({
    required Map<String, dynamic> app,
    required String rechargeType,
    required String accountId,
    required String payer,
  }) {
    setState(() {
      _cart.add(
        CartItem(
          digitalService: app,
          quantity: 1,
          topupAccountId: accountId,
          topupPayer: payer,
          topupRechargeType: rechargeType,
        ),
      );
      _selectedCartItems.add(_cart.length - 1);
    });
    _persistCart();
    showAppSnack(
      context,
      'Recharge ajoutée au panier',
      type: MessageType.success,
    );
  }

  void _addCourseToCart(Map<String, dynamic> course) {
    final alreadyInCart = _cart.any(
      (item) =>
          item.digitalService != null &&
          item.digitalService!['id'] == course['id'],
    );
    if (alreadyInCart) {
      showAppSnack(
        context,
        'Ce cours est déjà dans votre panier',
        type: MessageType.warning,
      );
      return;
    }
    setState(() {
      _cart.add(CartItem(digitalService: course, quantity: 1));
      _selectedCartItems.add(_cart.length - 1);
    });
    _persistCart();
    showAppSnack(
      context,
      '${course['title']} ajouté au panier',
      type: MessageType.success,
    );
  }

  void _toggleFavorite(ApiProduct product) {
    setState(() {
      if (_favorites.contains(product.id)) {
        _favorites.remove(product.id);
      } else {
        _favorites.add(product.id);
      }
    });
    _persistFavorites();
  }

  void _showProductImage(
    String imageUrl,
    String productName, {
    String? description,
  }) {
    final cleanDescription = (description ?? '').trim();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(
                          top: BorderSide(color: Color(0xFF1E293B), width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cleanDescription.isEmpty
                                ? 'Aucune description disponible'
                                : cleanDescription,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                              height: 1.35,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkoutCart() async {
    final token = widget.user.token;
    if (token == null || _cart.isEmpty) return;

    // Only checkout selected items (or all if none selected)
    final itemsToCheckout = _selectedCartItems.isEmpty
        ? _cart.toList()
        : _cart
              .asMap()
              .entries
              .where((e) => _selectedCartItems.contains(e.key))
              .map((e) => e.value)
              .toList();

    if (itemsToCheckout.isEmpty) {
      showAppSnack(
        context,
        'Veuillez sélectionner au moins un article',
        type: MessageType.warning,
      );
      return;
    }

    final amount = itemsToCheckout.fold(0, (sum, item) => sum + item.subtotal);

    // Create Order on Backend directly (skip payment sheet)
    final itemsPayload = <Map<String, dynamic>>[];
    for (final item in itemsToCheckout) {
      final payload = <String, dynamic>{'quantity': item.quantity};
      if (item.isAd) {
        final adId = item.resolvedAdId;
        if (adId == null) {
          showAppSnack(
            context,
            'Veuillez retirer cette annonce du panier puis l’ajouter à nouveau.',
            type: MessageType.error,
          );
          return;
        }
        payload['influencer_ad'] = adId;
      } else {
        if (item.product != null) payload['product'] = item.product!.id;
        if (item.digitalService != null) {
          payload['digital_service'] = item.digitalService!['id'];
        }
      }
      if (item.influencerId != null) payload['influencer'] = item.influencerId;
      if (item.isTopup) payload['topup_account_id'] = item.topupAccountId;
      if (item.isTopup) payload['topup_payer'] = item.topupPayer;
      if (item.isTopup) {
        payload['topup_recharge_type'] = item.topupRechargeType;
      }
      itemsPayload.add(payload);
    }

    final orderRes = await _api.createOrderWithItems(token, itemsPayload);
    if (!mounted) return;

    if (orderRes.isSuccess) {
      final order = orderRes.data!;
      final paid =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CustomerPaymentPage(
                order: order,
                cartItems: itemsToCheckout.map((item) => FactureItem(
                  title: item.title,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                  subtotal: item.subtotal,
                  isAd: item.isAd,
                  isTopup: item.isTopup,
                  vendorName: item.product?.vendorName,
                  influencerName: item.adInfluencerName,
                  influencerPhone: item.adPhone,
                  topupAccountId: item.topupAccountId,
                  topupPayer: item.topupPayer,
                )).toList(),
                onPayWithBankily: () async {
                  final paymentRes = await _api.confirmBankilyOrder(
                    token,
                    order.id,
                  );
                  return paymentRes.isSuccess
                      ? null
                      : 'Impossible de traiter le paiement Bankily. Veuillez réessayer.';
                },
              ),
            ),
          ) ??
          false;
      if (!mounted || !paid) return;

      setState(() {
        // Remove only checked items from cart
        final indicesToRemove = _selectedCartItems.isEmpty
            ? List.generate(_cart.length, (i) => i)
            : _selectedCartItems.toList();
        indicesToRemove.sort((a, b) => b.compareTo(a));
        for (final idx in indicesToRemove) {
          if (idx < _cart.length) _cart.removeAt(idx);
        }
        _selectedCartItems.clear();
        _currentIndex = 2; // Redirect to orders tab
      });
      _persistCart();
      _loadOrders();

      showAppSnack(
        context,
        'Commande payée et enregistrée de ${formatMru(amount)}',
        type: MessageType.success,
      );
    } else {
      showAppSnack(
        context,
        "Impossible de créer la commande. Veuillez réessayer.",
        type: MessageType.error,
      );
    }
  }

  // --- Sub-pages ---
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
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
                  isLabelVisible: _orderNotifications.isNotEmpty,
                  label: Text('${_orderNotifications.length}'),
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black,
                  ),
                ),
                onPressed: _showOrderNotifications,
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _showFavoritesOnly =
                  false; // Reset favorites view when shifting tabs
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'Panier',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildCartTab(),
            _buildOrdersTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }

  // --- Home Tab ---
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Favorites Row
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          prefixIcon: Icon(
                            Icons.search_outlined,
                            color: primaryBlue,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.camera_alt_outlined,
                              color: primaryBlue,
                            ),
                            onPressed: _searchByImage,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _showFavoritesOnly ? primaryBlue : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _showFavoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _showFavoritesOnly
                            ? Colors.white
                            : AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Categories Cards (4 Columns)
              Text(
                'Explorer les catégories',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryCard(
                    'Boutiques',
                    'assets/images/customer_shop.jpeg',
                    _openStoresList,
                  ),
                  _buildCategoryCard(
                    'Influenceurs',
                    'assets/images/customer_person.jpeg',
                    _openInfluencerList,
                  ),
                  _buildCategoryCard(
                    'Cours',
                    'assets/images/customer_graduation.jpeg',
                    _openCoursesList,
                  ),
                  _buildCategoryCard(
                    'Recharges',
                    'assets/images/customer_card.jpeg',
                    _openTopUpForm,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Product list header
              Text(
                _showFavoritesOnly ? 'Mes favoris' : 'Découvrir nos produits',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              _loadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'Aucun produit trouvé',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.76,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final isFav = _favorites.contains(product.id);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentBlue, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: product.imageUrl != null
                                      ? () => _showProductImage(
                                          product.imageUrl!,
                                          product.name,
                                          description: product.description,
                                        )
                                      : null,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        product.imageUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: product.imageUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) =>
                                                    Container(
                                                      color: accentBlue,
                                                    ),
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                      color:
                                                          AppColors.lightBlue,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        color:
                                                            AppColors.lightBlue,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: accentBlue,
                                                child: Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: primaryBlue,
                                                  size: 36,
                                                ),
                                              ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _toggleFavorite(product),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isFav
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFav
                                                    ? AppColors.primaryBlue
                                                    : Colors.black,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.vendorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${product.priceMru} UM',
                                          style: TextStyle(
                                            color: successGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _addToCart(product),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryBlue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String label,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentBlue, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  primaryBlue.withValues(alpha: 0.6),
                  BlendMode.multiply,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --- Category Sheets/Dialogs ---
  void _openStoresList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildStoresSelector(ctx),
      isScrollControlled: true,
    );
  }

  Widget _buildStoresSelector(BuildContext ctx) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Types de magasins',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: shopCategories.length,
                itemBuilder: (context, index) {
                  final category = shopCategories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        category.icon,
                        color: primaryBlue,
                        size: 28,
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        category.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showStoresInCategory(category);
                      },
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

  void _showStoresInCategory(ShopCategory category) {
    const defaultCategory = 'fashion';

    List<ApiShop> shops;
    if (_shops.isNotEmpty) {
      shops = _uniqueShops(_shops)
          .map(
            (s) => s.category.trim().isEmpty
                ? s.copyWith(category: defaultCategory)
                : s,
          )
          .toList();
    } else {
      // Build from products, deduplicated by vendorId
      final seen = <int>{};
      shops = _products
          .where((p) => seen.add(p.vendorId))
          .map(
            (p) => ApiShop(
              id: p.vendorId,
              name: p.vendorName,
              description: '',
              category: defaultCategory,
              isActive: true,
              vendorId: p.vendorId,
              vendorName: p.vendorName,
            ),
          )
          .toList();
    }

    // Keep only shops matching the selected category id
    shops = shops
        .where((s) => _normalizeShopCategory(s.category) == category.id)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(category.icon, color: primaryBlue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${shops.length} ${shops.length == 1 ? 'magasin' : 'magasins'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    final imageUrl = ApiConfig.mediaUrl(shop.image);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
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
                        shop.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showStoreProducts(shop.name, false, shop.vendorId);
                      },
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

  void _openInfluencerList() {
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
              'Boutiques des Influenceurs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _influencerUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun influenceur disponible',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _influencerUsers.length,
                      itemBuilder: (context, index) {
                        final inf = _influencerUsers[index];
                        final firstName = (inf['first_name'] as String? ?? '')
                            .trim();
                        final lastName = (inf['last_name'] as String? ?? '')
                            .trim();
                        final fullName = [
                          firstName,
                          lastName,
                        ].where((s) => s.isNotEmpty).join(' ');
                        final name = fullName.isNotEmpty
                            ? fullName
                            : (inf['username'] ?? 'Influenceur');
                        final infId = (inf['id'] as num?)?.toInt() ?? 0;
                        final imageUrl = ApiConfig.mediaUrl(
                          inf['profile_image']?.toString(),
                        );
                        return ListTile(
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipOval(
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: accentBlue,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: accentBlue,
                                            child: Icon(
                                              Icons.person_pin_outlined,
                                              color: primaryBlue,
                                            ),
                                          ),
                                    )
                                  : Container(
                                      color: accentBlue,
                                      child: Icon(
                                        Icons.person_pin_outlined,
                                        color: primaryBlue,
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(name),
                          subtitle: const Text('Boutique sponsorisée'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showInfluencerProducts(
                              name,
                              infId,
                              influencerUsername: inf['username']?.toString(),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInfluencerProducts(
    String influencerName,
    int influencerId, {
    String? influencerUsername,
  }) async {
    final token = widget.user.token;
    if (token == null) return;

    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch only accepted products and ads for this specific influencer
    final productsRes = await _api.fetchInfluencerProducts(token, influencerId);
    final adsRes = await _api.fetchInfluencerAds(
      token,
      influencerId: influencerId,
    );
    if (!mounted) return;
    navigator.pop(); // dismiss loading

    final productsJson = productsRes.isSuccess
        ? (productsRes.data ?? [])
        : <Map<String, dynamic>>[];
    final storeProducts = productsJson
        .map((e) => ApiProduct.fromJson(e))
        .toList();
    var ads = adsRes.isSuccess ? (adsRes.data ?? []) : <InfluencerAd>[];
    var adsError = adsRes.isSuccess ? null : adsRes.error;

    // Fallback: if the filtered endpoint returns nothing, fetch all public ads
    // and filter locally. This protects the storefront from query/ID mismatches.
    if (ads.isEmpty && adsError == null) {
      final allAdsRes = await _api.fetchInfluencerAds(token);
      if (allAdsRes.isSuccess) {
        final username = (influencerUsername ?? '').trim().toLowerCase();
        ads = (allAdsRes.data ?? []).where((ad) {
          final sameId = ad.influencerId == influencerId;
          final sameUsername =
              username.isNotEmpty &&
              ad.influencerName.trim().toLowerCase() == username;
          return sameId || sameUsername;
        }).toList();
      } else {
        adsError = allAdsRes.error;
      }
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                influencerName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Ads section is always visible.
                    Text(
                      'Annonces',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (adsError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Impossible de charger les annonces pour le moment.',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (ads.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Aucune annonce pour le moment.',
                            style: const TextStyle(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...ads.map(
                        (ad) => _buildInfluencerAdCard(ad, influencerId),
                      ),
                    const SizedBox(height: 16),
                    // Products section.
                    if (storeProducts.isNotEmpty) ...[
                      Text(
                        'Produits Promus',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...storeProducts.map(
                        (product) =>
                            _buildInfluencerProductCard(product, influencerId),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfluencerAdCard(InfluencerAd ad, int influencerId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: ad.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ad.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.lightBlue,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _buildAdImagePlaceholder(),
                      )
                    : _buildAdImagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Annonce',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ad.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${ad.priceMru} UM',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _addAdToCart(ad),
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdImagePlaceholder() {
    return Container(
      color: AppColors.lightBlue,
      child: const Center(
        child: Icon(
          Icons.campaign_outlined,
          color: AppColors.primaryBlue,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildInfluencerProductCard(ApiProduct product, int influencerId) {
    return ListTile(
      leading: GestureDetector(
        onTap: product.imageUrl != null
            ? () => _showProductImage(
                product.imageUrl!,
                product.name,
                description: product.description,
              )
            : null,
        child: ClipRRect(
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
      ),
      title: Text(product.name),
      subtitle: Text('${product.priceMru} UM'),
      trailing: IconButton(
        icon: Icon(Icons.add_shopping_cart_outlined, color: successGreen),
        onPressed: () {
          _addToCart(product, influencerId: influencerId);
        },
      ),
    );
  }

  void _addAdToCart(InfluencerAd ad) {
    final alreadyInCart = _cart.any((item) => item.isAd && item.adId == ad.id);
    if (alreadyInCart) {
      showAppSnack(
        context,
        'Cette annonce est déjà dans votre panier',
        type: MessageType.warning,
      );
      return;
    }

    setState(() {
      _cart.add(
        CartItem(
          isAd: true,
          adId: ad.id,
          adDescription: ad.description,
          adPriceMru: ad.priceMru,
          adImageUrl: ad.imageUrl,
          adPhone: null,
          influencerId: ad.influencerId,
          adInfluencerName: ad.influencerName,
        ),
      );
      _selectedCartItems.add(_cart.length - 1);
    });
    _persistCart();
    showAppSnack(
      context,
      'Annonce ajoutée au panier',
      type: MessageType.success,
    );
  }

  void _showStoreProducts(
    String storeName,
    bool isInfluencer, [
    int? vendorId,
  ]) {
    // Show products corresponding to this store
    final storeProducts = _products
        .where(
          (p) => vendorId != null
              ? p.vendorId == vendorId
              : p.vendorName == storeName,
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: storeProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun produit disponible dans cette boutique.',
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: storeProducts.length,
                        itemBuilder: (context, idx) {
                          final product = storeProducts[idx];
                          return ListTile(
                            leading: GestureDetector(
                              onTap: product.imageUrl != null
                                  ? () => _showProductImage(
                                      product.imageUrl!,
                                      product.name,
                                      description: product.description,
                                    )
                                  : null,
                              child: ClipRRect(
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
                            ),
                            title: Text(product.name),
                            subtitle: Text('${product.priceMru} UM'),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.add_shopping_cart_outlined,
                                color: successGreen,
                              ),
                              onPressed: () {
                                _addToCart(product);
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

  void _openCoursesList() {
    // Collect purchased course items and their service IDs
    final purchasedCourseItems = <ApiOrderItem>[];
    final purchasedServiceIds = <int>{};
    for (final order in _orders) {
      if (order.status == 'paid' || order.status == 'delivered') {
        for (final item in order.items) {
          if (item.itemType == 'course') {
            purchasedCourseItems.add(item);
            if (item.digitalServiceId != null) {
              purchasedServiceIds.add(item.digitalServiceId!);
            }
          }
        }
      }
    }

    // Exclude already-purchased courses from the available list
    final courses = _digitalServices
        .where(
          (s) =>
              s['type'] == 'course' &&
              !purchasedServiceIds.contains(s['id'] as int?),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cours en Ligne',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Mes Cours button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openMyCourses();
                  },
                  icon: const Icon(Icons.school),
                  label: Text(
                    'Mes Cours (${purchasedCourseItems.length})',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Cours disponibles',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: courses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: successGreen,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Vous avez déjà tous les cours disponibles !',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Consultez "Mes Cours" pour y accéder.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: courses.length,
                        itemBuilder: (context, idx) {
                          final item = courses[idx];
                          final title = item['title']?.toString() ?? '';
                          final description =
                              item['description']?.toString() ?? '';
                          final price =
                              (double.tryParse(
                                        item['price']?.toString() ?? '0',
                                      ) ??
                                      0)
                                  .round();
                          final buyerCount =
                              int.tryParse(
                                item['student_count']?.toString() ?? '0',
                              ) ??
                              0;
                          final imageUrl = ApiConfig.mediaUrl(
                            item['image'] as String?,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (imageUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: accentBlue,
                                              width: 70,
                                              height: 70,
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    color: accentBlue,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.menu_book,
                                                    color:
                                                        AppColors.primaryBlue,
                                                  ),
                                                ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: accentBlue,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.menu_book,
                                            color: AppColors.primaryBlue,
                                            size: 32,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$price UM',
                                              style: TextStyle(
                                                color: successGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$buyerCount apprenants',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 180,
                                          maxWidth: 260,
                                        ),
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: primaryBlue,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _addCourseToCart(item);
                                          },
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Ajouter au panier',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }

  void _openMyCourses() {
    // Collect purchased course items from paid/delivered orders
    final purchasedCourseItems = <ApiOrderItem>[];
    for (final order in _orders) {
      if (order.status == 'paid' || order.status == 'delivered') {
        for (final item in order.items) {
          if (item.itemType == 'course') {
            purchasedCourseItems.add(item);
          }
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: successGreen, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Mes Cours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: purchasedCourseItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: Colors.black,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Aucun cours acheté',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: purchasedCourseItems.length,
                        itemBuilder: (context, idx) {
                          final item = purchasedCourseItems[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: successGreen.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: successGreen,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'Acheté',
                                style: TextStyle(
                                  color: successGreen,
                                  fontSize: 12,
                                ),
                              ),
                              trailing:
                                  item.contentLink != null &&
                                      item.contentLink!.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.play_circle_outline,
                                        color: primaryBlue,
                                        size: 28,
                                      ),
                                      tooltip: 'Voir le cours',
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _showCourseLink(
                                          item.contentLink!,
                                          item.itemName,
                                        );
                                      },
                                    )
                                  : null,
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

  void _showCourseLink(String link, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_filled, color: primaryBlue, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      link,
                      style: TextStyle(color: primaryBlue, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Copier le lien',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: link));
                      showAppSnack(
                        context,
                        'Lien copiÃ©',
                        type: MessageType.success,
                      );
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Copiez ce lien et ouvrez-le dans votre navigateur',
              style: TextStyle(color: Colors.black, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openTopUpForm() {
    final apps = _digitalServices.where((s) => s['type'] == 'topup').toList();
    if (apps.isEmpty) {
      showAppSnack(context, "Aucune application disponible pour recharge");
      return;
    }

    Map<String, dynamic> selectedApp = apps.first;
    final TextEditingController idController = TextEditingController();
    final String autoPayer = widget.user.phone ?? widget.user.username;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final price =
              double.tryParse(
                selectedApp['price']?.toString() ?? '0',
              )?.round() ??
              0;
          final imageUrl = ApiConfig.mediaUrl(selectedApp['image'] as String?);
          final description = selectedApp['description']?.toString() ?? '';

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (sheetContext, scrollController) {
              return SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Recharge d'application",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // App selector when multiple top-up services exist.
                      if (apps.length > 1) ...[
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: apps.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final app = apps[i];
                              final selected = app['id'] == selectedApp['id'];
                              return ChoiceChip(
                                label: Text(app['title']?.toString() ?? ''),
                                selected: selected,
                                onSelected: (_) =>
                                    setModalState(() => selectedApp = app),
                                selectedColor: primaryBlue,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Selected app information card.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentBlue),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 62,
                                  height: 62,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 62,
                                    height: 62,
                                    color: accentBlue,
                                    child: Icon(
                                      Icons.phone_android,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: accentBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.phone_android,
                                  color: primaryBlue,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedApp['title']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    description.isEmpty
                                        ? 'Aucune description disponible'
                                        : description,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildInfoChip('Service', 'Recharge'),
                                      _buildInfoChip('Prix', '$price UM'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText:
                              selectedApp['required_field_name'] ??
                              'Identifiant du compte',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Total: $price UM',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            final idVal = idController.text.trim();
                            if (idVal.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedApp['required_field_name'] != null
                                        ? 'Veuillez saisir ${selectedApp['required_field_name']}'
                                        : "Veuillez saisir l'identifiant",
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            _addTopupToCart(
                              app: selectedApp,
                              rechargeType: 'standard',
                              accountId: idVal,
                              payer: autoPayer,
                            );
                          },
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Ajouter au panier',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Cart Tab ---
  Widget _buildCartTab() {
    if (_cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Votre panier est vide',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mon Panier',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedCartItems.length == _cart.length) {
                      _selectedCartItems.clear();
                    } else {
                      _selectedCartItems.clear();
                      for (int i = 0; i < _cart.length; i++) {
                        _selectedCartItems.add(i);
                      }
                    }
                  });
                },
                child: Text(
                  _selectedCartItems.length == _cart.length
                      ? 'Tout désélectionner'
                      : 'Tout sélectionner',
                  style: TextStyle(color: primaryBlue, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                final isSelected = _selectedCartItems.contains(index);
                final itemImageUrl = item.imageUrl;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? primaryBlue : accentBlue,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCartItems.remove(index);
                        } else {
                          _selectedCartItems.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: primaryBlue,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedCartItems.add(index);
                                } else {
                                  _selectedCartItems.remove(index);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: itemImageUrl != null
                                ? () => _showProductImage(
                                    itemImageUrl,
                                    item.title,
                                    description: item.description,
                                  )
                                : null,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: itemImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: itemImageUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: accentBlue,
                                        child: Icon(
                                          item.isTopup
                                              ? Icons.phone_android
                                              : item.isCourse
                                              ? Icons.menu_book
                                              : Icons.shopping_bag_outlined,
                                          color: primaryBlue,
                                          size: 24,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: accentBlue,
                                      child: Icon(
                                        item.isTopup
                                            ? Icons.phone_android
                                            : item.isCourse
                                            ? Icons.menu_book
                                            : Icons.shopping_bag_outlined,
                                        color: primaryBlue,
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item.unitPrice} UM',
                                  style: TextStyle(color: successGreen),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (item.product != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 22,
                                  ),
                                  constraints: const BoxConstraints.tightFor(
                                    width: 34,
                                    height: 34,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      if (item.quantity > 1) {
                                        item.quantity--;
                                      } else {
                                        _selectedCartItems.remove(index);
                                        _cart.removeAt(index);
                                      }
                                    });
                                    _persistCart();
                                  },
                                ),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 22,
                                  ),
                                  constraints: const BoxConstraints.tightFor(
                                    width: 34,
                                    height: 34,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() => item.quantity++);
                                    _persistCart();
                                  },
                                ),
                              ],
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() {
                                  _selectedCartItems.remove(index);
                                  _cart.removeAt(index);
                                });
                                _persistCart();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentBlue),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Total: $_cartTotal UM',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      height: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: _checkoutCart,
                        child: const Text(
                          'Payer',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Orders Tab ---
  Widget _buildOrdersTab() {
    if (_loadingOrders) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune commande enregistrée',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    final activeOrders = _orders.where((o) => o.status != 'delivered').toList();
    final pastOrders = _orders.where((o) => o.status == 'delivered').toList();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (activeOrders.isNotEmpty) ...[
            const Text(
              'En Cours',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...activeOrders.map((o) => _buildOrderCard(o, false)),
            const SizedBox(height: 24),
          ],
          if (pastOrders.isNotEmpty) ...[
            const Text(
              'Terminées',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...pastOrders.map((o) => _buildOrderCard(o, true)),
          ],
        ],
      ),
    );
  }

  void _showCourierInfoSheet(ApiOrder order) {
    final driver = order.driverInfo;
    final profileImageUrl = driver != null
        ? ApiConfig.mediaUrl(driver.profileImage)
        : null;
    final vehicleImageUrl = driver != null
        ? ApiConfig.mediaUrl(driver.vehicleImage)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.delivery_dining_outlined,
                      color: primaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Informations du livreur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Driver photo.
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: accentBlue,
                        backgroundImage: profileImageUrl != null
                            ? CachedNetworkImageProvider(profileImageUrl)
                            : null,
                        child: profileImageUrl == null
                            ? Icon(Icons.person, size: 46, color: primaryBlue)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: successGreen,
                            shape: BoxShape.circle,
                            border: const Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Personal information.
                _buildCourierInfoRow(
                  'Nom complet',
                  driver?.fullName.isNotEmpty == true
                      ? driver!.fullName
                      : (order.driverName ?? 'Non disponible'),
                  Icons.person_outline,
                ),
                _buildCourierInfoRow(
                  'Email',
                  (driver?.email ?? '').isNotEmpty
                      ? driver!.email!
                      : 'Non disponible',
                  Icons.email_outlined,
                ),
                _buildCourierInfoRow(
                  'Telephone',
                  (driver?.phone ?? '').isNotEmpty
                      ? driver!.phone!
                      : 'Non disponible',
                  Icons.phone_outlined,
                ),
                _buildCourierInfoRow(
                  'Type de vehicule',
                  (driver?.vehicleType ?? '').isNotEmpty
                      ? driver!.vehicleType!
                      : 'Non disponible',
                  Icons.directions_car_outlined,
                ),
                _buildCourierInfoRow(
                  'Plaque',
                  (driver?.vehiclePlate ?? '').isNotEmpty
                      ? driver!.vehiclePlate!
                      : 'Non disponible',
                  Icons.confirmation_number_outlined,
                ),
                // Vehicle photo.
                if (vehicleImageUrl != null || driver != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Photo du vehicule',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCourierImagePreview(
                    vehicleImageUrl,
                    Icons.local_shipping_outlined,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourierInfoRow(String label, String value, [IconData? icon]) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentBlue),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: primaryBlue),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierImagePreview(String? imageUrl, IconData fallbackIcon) {
    if (imageUrl == null) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: accentBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(fallbackIcon, size: 52, color: primaryBlue),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: accentBlue),
        errorWidget: (_, __, ___) => Container(
          color: accentBlue,
          child: Icon(fallbackIcon, size: 52, color: primaryBlue),
        ),
      ),
    );
  }

  Widget _buildOrderCard(ApiOrder order, bool isDelivered) {
    final hasTopup = order.items.any((item) => item.itemType == 'topup');
    final hasCourse = order.items.any((item) => item.itemType == 'course');
    final hasAd = order.items.any((item) => item.itemType == 'ad');
    final hasProduct = order.items.any((item) => item.itemType == 'product');
    final isTopupOnly = hasTopup && !hasProduct && !hasCourse && !hasAd;
    final isCourseOnly = hasCourse && !hasProduct && !hasTopup && !hasAd;
    final isAdOnly = hasAd && !hasProduct && !hasTopup && !hasCourse;
    final hasDelivery = hasProduct;
    final hasDriver = order.driverId != null || order.driverInfo != null;

    // ── Status label + color ──
    String statusText;
    Color statusColor;

    if (isTopupOnly) {
      statusText = order.status == 'delivered'
          ? 'Recharge effectuée'
          : 'En attente du traitement admin';
      statusColor = order.status == 'delivered'
          ? AppColors.primaryBlue
          : AppColors.primaryBlue;
    } else if (isCourseOnly) {
      statusText = (order.status == 'paid' || order.status == 'delivered')
          ? 'Acheté - disponible dans Mes Cours'
          : 'En attente';
      statusColor = (order.status == 'paid' || order.status == 'delivered')
          ? AppColors.primaryBlue
          : AppColors.primaryBlue;
    } else if (isAdOnly) {
      statusText = (order.status == 'paid' || order.status == 'delivered')
          ? 'Annonce payée'
          : 'En attente';
      statusColor = AppColors.primaryBlue;
    } else {
      switch (order.status) {
        case 'paid':
          statusText = order.vendorsTotal > 1
              ? 'En attente des vendeurs (${order.vendorsReady}/${order.vendorsTotal})'
              : 'En attente du vendeur';
          statusColor = order.allVendorsReady
              ? AppColors.primaryBlue
              : AppColors.primaryBlue;
          break;
        case 'ready':
          statusText = hasDriver ? 'Acceptée par le livreur' : 'Prête';
          statusColor = AppColors.primaryBlue;
          break;
        case 'on_way':
          statusText = 'Avec le livreur';
          statusColor = AppColors.primaryBlue;
          break;
        case 'arrived':
          statusText = 'Le livreur est arrivé';
          statusColor = AppColors.primaryBlue;
          break;
        case 'delivered':
          statusText = 'Livrée';
          statusColor = AppColors.primaryBlue;
          break;
        default:
          statusText = 'En attente';
          statusColor = AppColors.primaryBlue;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accentBlue, width: 1.2),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header: status and price.
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${order.totalMru} UM',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.lightBlue),
            const SizedBox(height: 12),

            // Order contents.
            ...order.items.map((item) => _buildOrderItemRow(order, item)),

            // Driver information button.
            if (hasDelivery && hasDriver) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCourierInfoSheet(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Informations du livreur',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],

            if (order.status == 'arrived') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _confirmReceipt(order),
                  child: const Text(
                    'Confirmer la reception et noter le livreur',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(ApiOrder order, ApiOrderItem item) {
    final isTopup = item.itemType == 'topup';
    final isCourse = item.itemType == 'course';
    final isAd = item.itemType == 'ad';
    final isPaid = const {
      'paid',
      'ready',
      'on_way',
      'arrived',
      'delivered',
    }.contains(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAd &&
                    isPaid &&
                    (item.influencerPhone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Influenceur: ${item.influencerPhone}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isTopup && !isCourse && !isAd)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'x${item.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmReceipt(ApiOrder order) async {
    // Star rating selection
    int selectedRating = 5;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            title: const Text('Évaluer le coursier'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Veuillez attribuer une note au coursier pour valider la livraison:',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final starIdx = index + 1;
                      final isSelected = starIdx <= selectedRating;
                      return IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isSelected ? Icons.star : Icons.star_border,
                          color: isSelected
                              ? const Color(0xFFFFC107)
                              : const Color(0xFFCBD5E1),
                          size: 34,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starIdx;
                          });
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.confirmDelivery(token, order.id, selectedRating);
    if (!mounted) return;

    if (res.isSuccess) {
      _loadOrders();
      showAppSnack(
        context,
        "Livraison confirmée. La part financière a été partagée !",
        color: successGreen,
      );
    } else {
      showAppSnack(
        context,
        "Impossible de confirmer la livraison. Veuillez réessayer.",
      );
    }
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

class _CustomerOrderNotification {
  final IconData icon;
  final String title;
  final String body;

  const _CustomerOrderNotification({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class CartItem {
  final ApiProduct? product;
  final Map<String, dynamic>? digitalService;
  int quantity;
  final int? influencerId;
  final bool isAd;
  final int? adId;
  final String? adDescription;
  final int? adPriceMru;
  final String? adImageUrl;
  final String? adPhone;
  final String? adInfluencerName;
  final String? topupAccountId;
  final String? topupPayer;
  final String? topupRechargeType;

  CartItem({
    this.product,
    this.digitalService,
    this.quantity = 1,
    this.influencerId,
    this.isAd = false,
    this.adId,
    this.adDescription,
    this.adPriceMru,
    this.adImageUrl,
    this.adPhone,
    this.adInfluencerName,
    this.topupAccountId,
    this.topupPayer,
    this.topupRechargeType,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final serviceJson = json['digital_service'];
    final product = productJson is Map<String, dynamic>
        ? ApiProduct.fromJson(productJson)
        : null;
    final isAd = json['is_ad'] == true;
    final legacyAdId = isAd && product != null && product.id < 0
        ? -product.id
        : null;
    return CartItem(
      product: product,
      digitalService: serviceJson is Map<String, dynamic> ? serviceJson : null,
      quantity: _toInt(json['quantity'], fallback: 1),
      influencerId: json['influencer_id'] is int
          ? json['influencer_id'] as int
          : int.tryParse('${json['influencer_id']}'),
      isAd: isAd,
      adId: _nullableInt(json['ad_id']) ?? legacyAdId,
      adDescription: json['ad_description'] as String? ?? product?.description,
      adPriceMru: _nullableInt(json['ad_price_mru']) ?? product?.priceMru,
      adImageUrl: json['ad_image_url'] as String? ?? product?.imageUrl,
      adPhone: null,
      adInfluencerName: json['ad_influencer_name'] as String?,
      topupAccountId: json['topup_account_id'] as String?,
      topupPayer: json['topup_payer'] as String?,
      topupRechargeType: json['topup_recharge_type'] as String?,
    );
  }

  bool get isTopup => digitalService?['type'] == 'topup';
  bool get isCourse => digitalService?['type'] == 'course';
  int? get resolvedAdId {
    if (!isAd) return null;
    if (adId != null) return adId;
    final productId = product?.id;
    if (productId != null && productId < 0) return -productId;
    return null;
  }

  String get title => isAd
      ? 'Annonce: ${(adDescription ?? product?.description ?? '').trim()}'
      : product?.name ?? digitalService?['title']?.toString() ?? '';

  String get description => isAd
      ? adDescription ?? ''
      : product?.description ??
            digitalService?['description']?.toString() ??
            '';

  int get unitPrice {
    if (isAd) return adPriceMru ?? 0;
    if (product != null) return product!.priceMru;
    final value = digitalService?['price'];
    if (value is int) return value;
    return double.tryParse(value?.toString() ?? '0')?.round() ?? 0;
  }

  String? get imageUrl {
    if (isAd) return adImageUrl;
    if (product != null) return product!.imageUrl;
    return ApiConfig.mediaUrl(digitalService?['image'] as String?);
  }

  int get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product == null
          ? null
          : {
              'id': product!.id,
              'name': product!.name,
              'description': product!.description,
              'price': product!.priceMru,
              'image': product!.imagePath,
              'vendor': product!.vendorId,
              'vendor_name': product!.vendorName,
              'stock_quantity': product!.stockQuantity,
            },
      'digital_service': digitalService,
      'quantity': quantity,
      'influencer_id': influencerId,
      'is_ad': isAd,
      'ad_id': adId,
      'ad_description': adDescription,
      'ad_price_mru': adPriceMru,
      'ad_image_url': adImageUrl,
      'ad_phone': null,
      'ad_influencer_name': adInfluencerName,
      'topup_account_id': topupAccountId,
      'topup_payer': topupPayer,
      'topup_recharge_type': topupRechargeType,
    };
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }
}
