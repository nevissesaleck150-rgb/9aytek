import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/api_config.dart';
import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminTopupTab extends StatefulWidget {
  final User user;
  const AdminTopupTab({super.key, required this.user});

  @override
  State<AdminTopupTab> createState() => _AdminTopupTabState();
}

class _AdminTopupTabState extends State<AdminTopupTab> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _requests = [];

  static const _blue = AppColors.primaryBlue;

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
    final svcRes = await _api.fetchServices(token);
    final reqRes = await _api.fetchTopupRequests(token);
    if (!mounted) return;
    setState(() {
      if (svcRes.isSuccess) {
        _services = svcRes.data!
            .where((s) => (s['type']?.toString() ?? '') == 'topup')
            .toList();
      }
      if (reqRes.isSuccess) _requests = reqRes.data!;
      _loading = false;
    });
  }

  Future<void> _completeRequest(int orderId) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog(
      'Marquer cette recharge comme terminée ?',
    );
    if (confirm != true) return;
    final res = await _api.completeTopupOrder(token, orderId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Recharge complétée.', success: true);
      _load();
    } else {
      _showSnack('Impossible de terminer cette recharge.');
    }
  }

  Future<void> _deleteService(int id) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog('Supprimer ce service de recharge ?');
    if (confirm != true) return;
    final res = await _api.deleteServiceAdmin(token, id);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Service supprimé.', success: true);
      _load();
    } else {
      _showSnack('Impossible de supprimer ce service.');
    }
  }

  void _showServiceForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    String? imagePath;
    String? previewImageUrl = ApiConfig.mediaUrl(
      existing?['image']?.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (ctx2, scroll) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  existing == null
                      ? 'Nouveau service de recharge'
                      : 'Modifier le service',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 18),
                _formField(nameCtrl, 'Nom du service'),
                const SizedBox(height: 12),
                _formField(descCtrl, 'Description'),
                const SizedBox(height: 12),
                _formField(
                  priceCtrl,
                  'Prix (MRU)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setS(() {
                        imagePath = picked.path;
                        previewImageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.lightBlue,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              imagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : previewImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              previewImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _imgPickerPlaceholder(),
                            ),
                          )
                        : _imgPickerPlaceholder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final fields = {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'price': priceCtrl.text.trim(),
                        'type': 'topup',
                      };
                      if (existing == null) {
                        await _createService(fields, imagePath);
                      } else {
                        await _updateService(
                          existing['id'] as int,
                          fields,
                          imagePath,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      existing == null ? 'Créer le service' : 'Enregistrer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createService(
    Map<String, String> fields,
    String? imagePath,
  ) async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.createServiceAdmin(
      token,
      fields,
      imagePath: imagePath,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Service créé avec succès.', success: true);
      _load();
    } else {
      _showSnack('Impossible de créer ce service.');
    }
  }

  Future<void> _updateService(
    int id,
    Map<String, String> fields,
    String? imagePath,
  ) async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.updateServiceAdmin(
      token,
      id,
      fields,
      imagePath: imagePath,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Service mis à jour.', success: true);
      _load();
    } else {
      _showSnack('Impossible de mettre à jour ce service.');
    }
  }

  void _showRequestsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Demandes de recharge',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_requests.length}',
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.lightBlue),
              Expanded(
                child: _requests.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune demande en attente.',
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    : ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx2, i) {
                          final req = _requests[i];
                          final status = (req['status'] ?? '').toString();
                          final isDone =
                              status == 'completed' || status == 'delivered';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.lightBlue),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '#${req['id']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _blue,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        req['customer_name']?.toString() ??
                                            'Client',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  req['service_name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${req['total_amount'] ?? 0} MRU',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (!isDone)
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _completeRequest(req['id'] as int);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Terminer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightBlue,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Terminé',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Services de recharge',
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showServiceForm(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Requests CTA (when no pending badge but there are requests)
          if (_requests.isNotEmpty)
            GestureDetector(
              onTap: _showRequestsSheet,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightBlue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_outlined, color: _blue, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${_requests.length} demande${_requests.length != 1 ? 's' : ''} de recharge',
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: _blue),
                  ],
                ),
              ),
            ),

          // Services grid
          if (_services.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Aucun service de recharge. Appuyez sur "Ajouter".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black),
                ),
              ),
            )
          else
            ..._services.map((svc) {
              final imageUrl = ApiConfig.mediaUrl(svc['image']?.toString());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBlue),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _svcPlaceholder(),
                            )
                          : _svcPlaceholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            svc['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if ((svc['description']?.toString() ?? '').isNotEmpty)
                            Text(
                              svc['description'].toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${svc['price'] ?? 0} MRU',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _iconBtn(
                          Icons.edit_outlined,
                          _blue,
                          () => _showServiceForm(existing: svc),
                        ),
                        const SizedBox(height: 6),
                        _iconBtn(
                          Icons.delete_outline,
                          AppColors.primaryBlue,
                          () => _deleteService(svc['id'] as int),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),
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

  Widget _svcPlaceholder() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: AppColors.lightBlue,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.smartphone_outlined, color: _blue, size: 28),
  );

  Widget _imgPickerPlaceholder() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_photo_alternate_outlined, color: Colors.black, size: 28),
      SizedBox(height: 6),
      Text(
        'Appuyez pour choisir une image',
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
    ],
  );

  Widget _formField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }

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
          style: FilledButton.styleFrom(backgroundColor: _blue),
          child: const Text('Confirmer'),
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
