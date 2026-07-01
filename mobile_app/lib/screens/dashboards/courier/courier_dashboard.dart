import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/api_order.dart';
import '../../../models/notification_item.dart';
import '../../../models/users.dart';
import '../../../services/api_service.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../../widgets/editable_profile_tab.dart';
import '../../../widgets/ui_helpers.dart';

class CourierDashboard extends StatefulWidget {
  final User user;
  const CourierDashboard({super.key, required this.user});

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  final ApiService _api = ApiService();
  int _currentIndex = 0;
  bool _isOnline = true;

  List<ApiOrder> _availableOrders = [];
  List<ApiOrder> _myDeliveries = [];
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  double _walletBalance = 0.0;

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
      if (ordersRes.isSuccess) {
        final all = ordersRes.data ?? [];
        _myDeliveries = all.where((o) => o.driverId == widget.user.id).toList();
        _availableOrders = all
            .where((o) => o.driverId == null && o.status == 'ready')
            .toList();
      }
      if (notifRes.isSuccess) _notifications = notifRes.data ?? [];
      _unreadCount = unread;
    });
  }

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
      case 'new_order':
        icon = Icons.delivery_dining_outlined;
        targetTab = 0; // Offres
        break;
      case 'driver_rating':
        icon = Icons.star_outline;
        targetTab = 2; // Gains
        break;
      case 'wallet_credit':
        icon = Icons.account_balance_wallet_outlined;
        targetTab = 2; // Gains
        break;
      default:
        icon = Icons.notifications_outlined;
        targetTab = 0;
    }
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(ApiOrder order) async {
    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.acceptDelivery(token, order.id);
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(context, "Livraison acceptée !", color: successGreen);
      await _refreshData();
      if (!mounted) return;
      setState(() => _currentIndex = 1); // Shifting to Map/Deliveries tab
    } else {
      showAppSnack(
        context,
        "Impossible d'accepter cette livraison. Veuillez réessayer.",
      );
    }
  }

  Future<void> _updateDeliveryStatus(ApiOrder order, String nextStatus) async {
    final token = widget.user.token;
    if (token == null) return;

    final res = await _api.updateOrderStatus(token, order.id, nextStatus);
    if (!mounted) return;

    if (res.isSuccess) {
      showAppSnack(context, "Statut mis à jour", color: successGreen);
      _refreshData();
    } else {
      showAppSnack(
        context,
        "Impossible de mettre à jour la livraison. Veuillez réessayer.",
      );
    }
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
            icon: Icon(Icons.list_alt_outlined),
            label: 'Offres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Trajets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Gains',
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
                _buildAvailableOffersTab(),
                _buildMapTab(),
                _buildEarningsTab(),
                _buildProfileTab(),
              ],
            ),
    );
  }

  // --- Offers Tab ---
  Widget _buildAvailableOffersTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Online Toggle
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentBlue),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut d\'activité',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isOnline
                          ? 'Disponible pour livrer'
                          : 'En pause / Inactif',
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
                Switch(
                  value: _isOnline,
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
                              ? 'Voulez-vous activer votre statut et recevoir des livraisons ?'
                              : 'Voulez-vous désactiver votre statut et passer en pause ?',
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
                      setState(() => _isOnline = v);
                      showAppSnack(
                        context,
                        v
                            ? 'Vous êtes maintenant en ligne'
                            : 'Vous êtes hors ligne',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Offres de livraison disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          !_isOnline
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Veuillez activer votre statut pour recevoir les offres',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                )
              : _availableOrders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Aucune offre disponible actuellement',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availableOrders.length,
                  itemBuilder: (context, idx) {
                    final order = _availableOrders[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Livraison ${order.displayId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                            const SizedBox(height: 8),
                            Text(
                              'Client: ${order.customerName ?? "Inconnu"}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                ),
                                onPressed: () => _acceptOrder(order),
                                child: const Text(
                                  'Accepter la livraison',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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

  // --- Map / Trajets Tab ---
  List<_RoutePoint> _buildRoutePoints(ApiOrder order) {
    final points = <_RoutePoint>[];
    final vendorLocs = order.vendorLocations
        .where((v) => v.lat != null && v.lng != null)
        .toList();

    for (int i = 0; i < vendorLocs.length; i++) {
      points.add(
        _RoutePoint(
          point: LatLng(vendorLocs[i].lat!, vendorLocs[i].lng!),
          label: vendorLocs[i].name,
          shortLabel: vendorLocs.length > 1 ? 'M${i + 1}' : 'Magasin',
          color: AppColors.primaryBlue,
          icon: Icons.store_mall_directory_outlined,
          isVendor: true,
        ),
      );
    }

    if (points.isEmpty && order.vendorLat != null && order.vendorLng != null) {
      points.add(
        _RoutePoint(
          point: LatLng(order.vendorLat!, order.vendorLng!),
          label: 'Magasin',
          shortLabel: 'Magasin',
          color: AppColors.primaryBlue,
          icon: Icons.store_mall_directory_outlined,
          isVendor: true,
        ),
      );
    }

    if (order.customerLat != null && order.customerLng != null) {
      points.add(
        _RoutePoint(
          point: LatLng(order.customerLat!, order.customerLng!),
          label: order.customerName ?? 'Client',
          shortLabel: 'Client',
          color: primaryBlue,
          icon: Icons.person_pin_circle_outlined,
          isVendor: false,
        ),
      );
    }

    return points;
  }

  double _computeMapZoom(List<_RoutePoint> points) {
    if (points.length <= 1) return 15;

    double minLat = points.first.point.latitude;
    double maxLat = minLat;
    double minLng = points.first.point.longitude;
    double maxLng = minLng;

    for (final point in points.skip(1)) {
      minLat = point.point.latitude < minLat ? point.point.latitude : minLat;
      maxLat = point.point.latitude > maxLat ? point.point.latitude : maxLat;
      minLng = point.point.longitude < minLng ? point.point.longitude : minLng;
      maxLng = point.point.longitude > maxLng ? point.point.longitude : maxLng;
    }

    final latDelta = (maxLat - minLat).abs();
    final lngDelta = (maxLng - minLng).abs();
    final span = latDelta > lngDelta ? latDelta : lngDelta;

    if (span < 0.005) return 15;
    if (span < 0.015) return 14;
    if (span < 0.04) return 13;
    if (span < 0.08) return 12;
    if (span < 0.16) return 11;
    return 10;
  }

  LatLng _computeMapCenter(List<_RoutePoint> points) {
    if (points.isEmpty) {
      return const LatLng(18.0735, -15.9582);
    }

    double totalLat = 0;
    double totalLng = 0;
    for (final point in points) {
      totalLat += point.point.latitude;
      totalLng += point.point.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  Widget _buildMapMarker(_RoutePoint point) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: point.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: point.color.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(point.icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            point.shortLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: point.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteMap(ApiOrder order) {
    final routePoints = _buildRoutePoints(order);
    if (routePoints.isEmpty) {
      return const Center(
        child: Text(
          'Aucune localisation disponible',
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    final center = _computeMapCenter(routePoints);
    final zoom = _computeMapZoom(routePoints);
    final polylinePoints = routePoints.map((point) => point.point).toList();

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(center: center, zoom: zoom),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.myproject.mobile_app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePoints,
                  strokeWidth: 4,
                  color: primaryBlue,
                ),
              ],
            ),
            MarkerLayer(
              markers: routePoints
                  .map(
                    (point) => Marker(
                      width: 90,
                      height: 72,
                      point: point.point,
                      builder: (context) => _buildMapMarker(point),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegendChip(
                icon: Icons.store_mall_directory_outlined,
                label:
                    '${routePoints.where((point) => point.isVendor).length} magasin(s)',
                color: AppColors.primaryBlue,
              ),
              _buildLegendChip(
                icon: Icons.person_pin_circle_outlined,
                label: order.customerName ?? 'Client',
                color: primaryBlue,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.route_outlined, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress?.isNotEmpty == true
                        ? order.deliveryAddress!
                        : 'Itineraire du magasin vers le client',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    if (_myDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            const Text(
              'Aucune livraison en cours',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myDeliveries.length,
        itemBuilder: (context, idx) {
          final order = _myDeliveries[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Route visual with vendor & customer markers
                SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildRouteMap(order),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande ${order.displayId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Destinataire: ${order.customerName ?? "Inconnu"}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nombre de magasins: ${_buildRoutePoints(order).where((point) => point.isVendor).length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      order.status == 'ready'
                          ? SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                ),
                                onPressed: () =>
                                    _updateDeliveryStatus(order, 'on_way'),
                                child: const Text(
                                  'Commencer le trajet (En Route)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          : order.status == 'on_way'
                          ? SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: successGreen,
                                ),
                                onPressed: () =>
                                    _updateDeliveryStatus(order, 'arrived'),
                                child: const Text(
                                  'Je suis arrive chez le client',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          : order.status == 'arrived'
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Vous etes arrive chez le client. En attente de confirmation du client.',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Livré avec succès',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
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
    );
  }

  // --- Earnings Tab ---
  Widget _buildEarningsTab() {
    final deliveredOrders = _myDeliveries
        .where((o) => o.status == 'delivered')
        .toList();
    final totalDelivered = deliveredOrders.length;
    final rating = 4.8; // Simulator value
    final totalDistanceKm = totalDelivered * 3.4;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Analyse des Gains',
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
                'Livrées',
                '$totalDelivered',
                Icons.done_all_outlined,
              ),
              _buildStatCard(
                'Portefeuille',
                '${_walletBalance.round()} UM',
                Icons.account_balance_wallet_outlined,
              ),
              _buildStatCard(
                'Distance',
                '${totalDistanceKm.toStringAsFixed(1)} km',
                Icons.directions_bike_outlined,
              ),
              _buildStatCard('Évaluation', '$rating / 5', Icons.star_outline),
            ],
          ),
          const SizedBox(height: 24),
          WeeklyEarningsChart(
            orders: _myDeliveries.where((o) => o.driverId != null).toList(),
            title: 'Gains de la semaine',
            color: primaryBlue,
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
          Icon(icon, color: primaryBlue, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: value.length > 12 ? 15 : 17,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 11),
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

class _RoutePoint {
  final LatLng point;
  final String label;
  final String shortLabel;
  final Color color;
  final IconData icon;
  final bool isVendor;

  const _RoutePoint({
    required this.point,
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.icon,
    required this.isVendor,
  });
}
