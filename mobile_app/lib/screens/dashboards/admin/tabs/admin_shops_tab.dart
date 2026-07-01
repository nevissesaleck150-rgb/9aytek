import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

import '../../../../config/api_config.dart';
import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminShopsTab extends StatefulWidget {
  final User user;
  const AdminShopsTab({super.key, required this.user});

  @override
  State<AdminShopsTab> createState() => _AdminShopsTabState();
}

class _AdminShopsTabState extends State<AdminShopsTab> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _shops = [];

  static const _blue = AppColors.primaryBlue;

  // 0 = Products, 1 = Shops/Vendors
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.user.token;
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);

    final prodRes = await _api.fetchProductsAdmin(token);
    final shopRes = await _api.fetchShopsAdmin(token);

    if (!mounted) return;
    setState(() {
      if (prodRes.isSuccess) _products = prodRes.data!;
      if (shopRes.isSuccess) _shops = shopRes.data!;
      _loading = false;
    });
  }

  Future<void> _approveProduct(int productId) async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.approveProductAdmin(token, productId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Produit approuvé.', success: true);
      _load();
    } else {
      _showSnack('Impossible d\'approuver ce produit.');
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog('Supprimer ce produit ?');
    if (confirm != true) return;
    final res = await _api.deleteProductAdmin(token, productId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Produit supprimé.', success: true);
      _load();
    } else {
      _showSnack('Impossible de supprimer ce produit.');
    }
  }

  Future<void> _deleteShop(int shopId) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog('Supprimer cette boutique ?');
    if (confirm != true) return;
    final res = await _api.deleteShopAdmin(token, shopId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Boutique supprimée.', success: true);
      _load();
    } else {
      _showSnack('Impossible de supprimer cette boutique.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final approved = _products.where((p) => p['is_approved'] == true).length;
    final pending = _products.where((p) => p['is_approved'] != true).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          // Sub-tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tabChip('Produits', 0),
                const SizedBox(width: 8),
                _tabChip('Boutiques', 1),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBlue),
          Expanded(
            child: _tabIndex == 0
                ? _buildProductsList(approved, pending)
                : _buildShopsList(),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _blue : AppColors.lightBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList(int approved, int pending) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats
        Row(
          children: [
            Expanded(
              child: _miniCard('TOTAL', _products.length.toString(), _blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'APPROUVÉS',
                approved.toString(),
                AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniCard(
                'EN ATTENTE',
                pending.toString(),
                AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text(
          '${_products.length} produit${_products.length != 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        const SizedBox(height: 10),

        if (_products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'Aucun produit.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          )
        else
          ..._products.map((p) {
            final isApproved = p['is_approved'] == true;
            final imageUrl = ApiConfig.mediaUrl(p['image']?.toString());

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightBlue),
              ),
              child: Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder(),
                          )
                        : _imgPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name']?.toString() ?? 'Produit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p['price'] ?? 0} MRU',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isApproved
                                  ? Icons.check_circle
                                  : Icons.access_time,
                              size: 12,
                              color: isApproved
                                  ? AppColors.primaryBlue
                                  : AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isApproved ? 'Approuvé' : 'En attente',
                              style: TextStyle(
                                fontSize: 11,
                                color: isApproved
                                    ? AppColors.primaryBlue
                                    : AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (!isApproved)
                        _iconBtn(
                          Icons.check,
                          AppColors.primaryBlue,
                          () => _approveProduct(p['id'] as int),
                        ),
                      const SizedBox(height: 6),
                      _iconBtn(
                        Icons.delete_outline,
                        AppColors.primaryBlue,
                        () => _deleteProduct(p['id'] as int),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildShopsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_shops.length} boutique${_shops.length != 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        const SizedBox(height: 10),

        if (_shops.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'Aucune boutique.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          )
        else
          ..._shops.map((s) {
            final logoUrl = ApiConfig.mediaUrl(s['logo']?.toString());

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightBlue),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront_outlined,
                                color: _blue,
                                size: 22,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.storefront_outlined,
                            color: _blue,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name']?.toString() ?? 'Boutique',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        if (s['owner_name'] != null)
                          Text(
                            'Propriétaire : ${s['owner_name']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _iconBtn(
                    Icons.delete_outline,
                    AppColors.primaryBlue,
                    () => _deleteShop(s['id'] as int),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.image_outlined, color: _blue, size: 24),
  );

  Future<bool?> _confirmDialog(String message) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmation'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.primaryBlue : Colors.black,
      ),
    );
  }
}
