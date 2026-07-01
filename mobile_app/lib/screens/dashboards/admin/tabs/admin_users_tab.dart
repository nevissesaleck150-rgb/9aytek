import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';

import '../../../../config/api_config.dart';
import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminUsersTab extends StatefulWidget {
  final User user;
  const AdminUsersTab({super.key, required this.user});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  static const _blue = AppColors.primaryBlue;

  final _roleConfig = const {
    'admin': {
      'color': AppColors.primaryBlue,
      'label': 'Admin',
      'bg': AppColors.lightBlue,
    },
    'customer': {
      'color': AppColors.primaryBlue,
      'label': 'Client',
      'bg': AppColors.lightBlue,
    },
    'vendor': {
      'color': AppColors.primaryBlue,
      'label': 'Marchand',
      'bg': AppColors.lightBlue,
    },
    'influencer': {
      'color': AppColors.primaryBlue,
      'label': 'Influenceur',
      'bg': AppColors.lightBlue,
    },
    'driver': {
      'color': AppColors.primaryBlue,
      'label': 'Livreur',
      'bg': AppColors.lightBlue,
    },
  };

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
    final res = await _api.fetchUsers(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) _users = res.data!;
      _loading = false;
    });
  }

  Future<void> _approve(int userId) async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.approveUser(token, userId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Utilisateur approuvé avec succès !', success: true);
      _load();
    } else {
      _showSnack("Impossible d'approuver cet utilisateur.");
    }
  }

  Future<void> _reject(int userId) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog('Rejeter cet utilisateur ?');
    if (confirm != true) return;
    final res = await _api.rejectUser(token, userId);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Utilisateur rejeté.', success: true);
      _load();
    } else {
      _showSnack("Impossible de rejeter cet utilisateur.");
    }
  }

  Future<void> _showPreview(Map<String, dynamic> u) async {
    final token = widget.user.token;
    if (token == null) return;
    final res = await _api.fetchUserById(token, u['id'] as int);
    if (!mounted) return;
    final data = res['success'] == true
        ? Map<String, dynamic>.from(res['body'] as Map)
        : u;
    _openPreviewSheet(data);
  }

  void _openPreviewSheet(Map<String, dynamic> data) {
    final rc =
        _roleConfig[data['role']] ??
        {
          'color': Colors.black,
          'label': data['role'],
          'bg': AppColors.lightBlue,
        };
    final isApproved = data['is_approved'] == true;
    final role = data['role']?.toString() ?? '';
    final isVendor = role == 'vendor';
    final isInfluencer = role == 'influencer';
    final isDriver = role == 'driver';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Container(
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: _blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails de l\'utilisateur',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Consultez les informations avant d\'approuver.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Informations personnelles'),
              const SizedBox(height: 10),
              ...[
                ['Nom d\'utilisateur', _fmtVal(data['username'])],
                [
                  'Nom complet',
                  _fmtVal(
                    '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'
                        .trim(),
                    fallback: data['username']?.toString(),
                  ),
                ],
                ['Email', _fmtVal(data['email'])],
                ['Téléphone', _fmtVal(data['phone'])],
                ['Adresse', _fmtVal(data['address'])],
                ['Rôle', (rc['label'] as String?) ?? '—'],
                ['Statut', isApproved ? 'Approuvé' : 'En attente'],
                ['Solde portefeuille', '${data['wallet_balance'] ?? 0} MRU'],
                ['Latitude', _fmtVal(data['latitude'])],
                ['Longitude', _fmtVal(data['longitude'])],
              ].map((row) => _previewRow(row[0], row[1])),
              if (isVendor) ...[
                const SizedBox(height: 16),
                _sectionTitle('Informations du marchand'),
                const SizedBox(height: 10),
                ...[
                  ['Nom du magasin', _fmtVal(data['store_name'])],
                  ['Description', _fmtVal(data['store_description'])],
                  ['Type de magasin', _fmtVal(data['store_type'])],
                  ['Compte bancaire', _fmtVal(data['bank_account'])],
                ].map((row) => _previewRow(row[0], row[1])),
              ],
              if (isInfluencer) ...[
                const SizedBox(height: 16),
                _sectionTitle('Informations de l\'influenceur'),
                const SizedBox(height: 10),
                ...[
                  ['Specialite', _fmtVal(data['specialty'])],
                  ['Reseaux sociaux', _fmtVal(data['social_links'])],
                  ['CV / Notes', _fmtVal(data['resume'])],
                  ['Compte bancaire', _fmtVal(data['bank_account'])],
                ].map((row) => _previewRow(row[0], row[1])),
              ],
              if (isDriver) ...[
                const SizedBox(height: 16),
                _sectionTitle('Informations du livreur'),
                const SizedBox(height: 10),
                ...[
                  ['Type de vehicule', _fmtVal(data['vehicle_type'])],
                  ['Plaque d\'immat.', _fmtVal(data['vehicle_plate'])],
                  ['Compte bancaire', _fmtVal(data['bank_account'])],
                ].map((row) => _previewRow(row[0], row[1])),
              ],
              if (!isVendor && !isInfluencer && !isDriver) ...[
                const SizedBox(height: 16),
                _sectionTitle('Informations supplementaires'),
                const SizedBox(height: 10),
                _previewRow('Compte bancaire', _fmtVal(data['bank_account'])),
              ],
              const SizedBox(height: 16),
              _previewImage('Photo de profil', data['profile_image']),
              if (isVendor)
                _previewImage('Logo du magasin', data['store_logo']),
              if (isVendor || isInfluencer || isDriver)
                _previewImage('Carte nationale', data['national_id']),
              if (isDriver)
                _previewImage('Permis de conduire', data['driving_license']),
              if (isDriver)
                _previewImage('Image du vehicule', data['vehicle_image']),
              if (!isApproved) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approve(data['id'] as int);
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reject(data['id'] as int);
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final roleCtrl = ValueNotifier<String>('customer');
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final storeNameCtrl = TextEditingController();
    final vTypeCtrl = TextEditingController();
    final vPlateCtrl = TextEditingController();
    String? profileImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          initialChildSize: 0.9,
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
                const Text(
                  'Nouvel utilisateur',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Créez un compte selon le type d\'utilisateur.',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
                const SizedBox(height: 18),
                _fieldLabel('Type d\'utilisateur'),
                ValueListenableBuilder<String>(
                  valueListenable: roleCtrl,
                  builder: (_, role, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightBlue),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: role,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'customer',
                            child: Text('Client'),
                          ),
                          DropdownMenuItem(
                            value: 'vendor',
                            child: Text('Marchand'),
                          ),
                          DropdownMenuItem(
                            value: 'influencer',
                            child: Text('Influenceur'),
                          ),
                          DropdownMenuItem(
                            value: 'driver',
                            child: Text('Livreur'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            roleCtrl.value = v;
                            setS(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _formField(nameCtrl, 'Nom complet'),
                const SizedBox(height: 12),
                _formField(
                  emailCtrl,
                  'Adresse e-mail',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _formField(passCtrl, 'Mot de passe', obscure: true),
                const SizedBox(height: 12),
                _formField(
                  phoneCtrl,
                  'Téléphone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _formField(addrCtrl, 'Adresse'),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: roleCtrl,
                  builder: (_, role, __) => Column(
                    children: [
                      if (role == 'vendor') ...[
                        _formField(storeNameCtrl, 'Nom du magasin'),
                        const SizedBox(height: 12),
                      ],
                      if (role == 'driver') ...[
                        _formField(vTypeCtrl, 'Type de véhicule'),
                        const SizedBox(height: 12),
                        _formField(vPlateCtrl, 'Plaque d\'immatriculation'),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _createUser(
                        role: roleCtrl.value,
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        address: addrCtrl.text.trim(),
                        storeName: storeNameCtrl.text.trim(),
                        vehicleType: vTypeCtrl.text.trim(),
                        vehiclePlate: vPlateCtrl.text.trim(),
                        profileImagePath: profileImagePath,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Créer l\'utilisateur',
                      style: TextStyle(
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

  Future<void> _createUser({
    required String role,
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    String storeName = '',
    String vehicleType = '',
    String vehiclePlate = '',
    String? profileImagePath,
  }) async {
    final token = widget.user.token;
    if (token == null) return;
    final nameParts = fullName.split(' ');
    final extraFields = <String, dynamic>{
      'full_name': fullName,
      'first_name': nameParts.first,
      'last_name': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
      'phone': phone,
      'address': address,
      if (storeName.isNotEmpty) 'store_name': storeName,
      if (vehicleType.isNotEmpty) 'vehicle_type': vehicleType,
      if (vehiclePlate.isNotEmpty) 'vehicle_plate': vehiclePlate,
    };
    final filePaths = <String, String>{};
    if (profileImagePath != null) filePaths['profile_image'] = profileImagePath;

    final res = await _api.register(
      username: fullName,
      email: email,
      password: password,
      role: role,
      extraFields: extraFields,
      filePaths: filePaths.isEmpty ? null : filePaths,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Utilisateur créé avec succès.', success: true);
      _load();
    } else {
      _showSnack('Impossible de créer l\'utilisateur.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final totalCustomers = _users.where((u) => u['role'] == 'customer').length;
    final totalVendors = _users.where((u) => u['role'] == 'vendor').length;
    final totalInfluencers = _users
        .where((u) => u['role'] == 'influencer')
        .length;
    final totalDrivers = _users.where((u) => u['role'] == 'driver').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Subtitle + add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestion des comptes',
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Ajouter',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
          const SizedBox(height: 16),

          // Stat cards
          Row(
            children: [
              Expanded(child: _miniStat('CLIENTS', totalCustomers, _blue)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('MARCHANDS', totalVendors, _blue)),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'INFLUENCEURS',
                  totalInfluencers,
                  AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'LIVREURS',
                  totalDrivers,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Users count
          Text(
            '${_users.length} utilisateur${_users.length != 1 ? 's' : ''} enregistré${_users.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
          const SizedBox(height: 10),

          // User list
          ..._users.asMap().entries.map((entry) {
            final u = entry.value;
            final rc =
                _roleConfig[u['role']] ??
                {
                  'color': Colors.black,
                  'label': u['role'],
                  'bg': AppColors.lightBlue,
                };
            final isApproved = u['is_approved'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: entry.key % 2 == 0 ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightBlue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: _blue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['username']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              u['email']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rc['bg'] as Color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rc['label'] as String,
                          style: TextStyle(
                            color: rc['color'] as Color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isApproved ? Icons.check_circle : Icons.access_time,
                        size: 14,
                        color: isApproved
                            ? AppColors.primaryBlue
                            : AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isApproved ? 'Approuvé' : 'En attente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isApproved
                              ? AppColors.primaryBlue
                              : AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isApproved) ...[
                        _actionBtn(
                          'Approuver',
                          AppColors.primaryBlue,
                          () => _approve(u['id'] as int),
                        ),
                        const SizedBox(width: 8),
                        _actionBtn(
                          'Rejeter',
                          AppColors.primaryBlue,
                          () => _reject(u['id'] as int),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Eye button
                      InkWell(
                        onTap: () => _showPreview(u),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lightBlue),
                          ),
                          child: const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: _blue,
                          ),
                        ),
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

  // Helpers

  Widget _miniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 82),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      color: Colors.black,
    ),
  );

  Widget _previewImage(String label, dynamic value) {
    final url = ApiConfig.mediaUrl(value?.toString());
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(label),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _imagePlaceholder('Image non disponible'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(String text) => Container(
    height: 180,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.lightBlue, style: BorderStyle.solid),
    ),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.black)),
    ),
  );

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
  );

  Widget _formField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
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

  String _fmtVal(dynamic v, {String? fallback}) {
    if (v == null || (v is String && v.trim().isEmpty)) {
      return fallback ?? 'Non renseigné';
    }
    return v.toString();
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
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
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
