import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/users.dart';
import '../models/shop_categories.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../utils/role_router.dart';
import 'ui_helpers.dart';

// ── Sheet widget — owns all controllers so dispose() is called at the right time
class _ProfileEditSheet extends StatefulWidget {
  final User user;
  final Color primaryBlue;
  final Color accentBlue;
  final ApiService api;
  final String roleLabel;
  final IconData roleIcon;
  final void Function(User updated) onSaved;

  const _ProfileEditSheet({
    required this.user,
    required this.primaryBlue,
    required this.accentBlue,
    required this.api,
    required this.roleLabel,
    required this.roleIcon,
    required this.onSaved,
  });

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Images
  File? _pickedProfile;
  File? _pickedVehicle;
  File? _pickedNationalId;
  File? _pickedDrivingLicense;
  File? _pickedStoreLogo;

  // Controllers
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _bank;
  late final TextEditingController _storeName;
  late final TextEditingController _storeDesc;
  late final TextEditingController _storeType;
  late final TextEditingController _socialLinks;
  late final TextEditingController _specialty;
  late final TextEditingController _resume;
  late final TextEditingController _vehicleType;
  late final TextEditingController _vehiclePlate;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstName    = TextEditingController(text: u.firstName ?? '');
    _lastName     = TextEditingController(text: u.lastName ?? '');
    _username     = TextEditingController(text: u.username);
    _email        = TextEditingController(text: u.email ?? '');
    _phone        = TextEditingController(text: u.phone ?? '');
    _address      = TextEditingController(text: u.address ?? '');
    _lat          = TextEditingController(text: u.latitude?.toString() ?? '');
    _lng          = TextEditingController(text: u.longitude?.toString() ?? '');
    _bank         = TextEditingController(text: u.bankAccount ?? '');
    _storeName    = TextEditingController(text: u.storeName ?? '');
    _storeDesc    = TextEditingController(text: u.storeDescription ?? '');
    _storeType    = TextEditingController(text: u.storeType ?? '');
    _socialLinks  = TextEditingController(text: u.socialLinks ?? '');
    _specialty    = TextEditingController(text: u.specialty ?? '');
    _resume       = TextEditingController(text: u.resume ?? '');
    _vehicleType  = TextEditingController(text: u.vehicleType ?? '');
    _vehiclePlate = TextEditingController(text: u.vehiclePlate ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();    _lastName.dispose();
    _username.dispose();     _email.dispose();
    _phone.dispose();        _address.dispose();
    _lat.dispose();          _lng.dispose();
    _bank.dispose();         _storeName.dispose();
    _storeDesc.dispose();    _storeType.dispose();
    _socialLinks.dispose();  _specialty.dispose();
    _resume.dispose();       _vehicleType.dispose();
    _vehiclePlate.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {String target = 'profile'}) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null || !mounted) return;
    setState(() {
      final file = File(picked.path);
      switch (target) {
        case 'vehicle':         _pickedVehicle      = file; break;
        case 'national_id':     _pickedNationalId   = file; break;
        case 'driving_license': _pickedDrivingLicense = file; break;
        case 'store_logo':      _pickedStoreLogo    = file; break;
        default:                _pickedProfile      = file;
      }
    });
  }

  void _showSourceSheet({String target = 'profile'}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: widget.primaryBlue),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera, target: target); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: widget.primaryBlue),
              title: const Text('Choisir depuis la galerie'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery, target: target); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) showAppSnack(context, 'Activez la localisation', type: MessageType.error);
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (mounted) showAppSnack(context, 'Permission refusée', type: MessageType.error);
      return;
    }
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (!mounted) return;
    setState(() {
      _lat.text = pos.latitude.toString();
      _lng.text  = pos.longitude.toString();
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = widget.user.token;
    if (token == null) return;

    final role         = widget.user.role;
    final isVendor     = role == 'vendor';
    final isInfluencer = role == 'influencer';
    final isDriver     = role == 'driver';
    final showBank     = role != 'admin';

    // Truncate to 6 decimal places to match DecimalField(decimal_places=6)
    final latRaw = _lat.text.trim();
    final lngRaw = _lng.text.trim();
    final lat = latRaw.isEmpty ? null : double.tryParse(latRaw);
    final lng = lngRaw.isEmpty ? null : double.tryParse(lngRaw);
    final latStr = lat?.toStringAsFixed(6);
    final lngStr = lng?.toStringAsFixed(6);

    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{
        'first_name': _firstName.text.trim(),
        'last_name':  _lastName.text.trim(),
        'username':   _username.text.trim(),
        'email':      _email.text.trim(),
        'phone':      _phone.text.trim(),
        'address':    _address.text.trim(),
        if (latStr != null) 'latitude':  latStr,
        if (lngStr != null) 'longitude': lngStr,
        if (showBank)    'bank_account': _bank.text.trim(),
        if (isVendor) ...{
          'store_name':        _storeName.text.trim(),
          'store_description': _storeDesc.text.trim(),
          'store_type':        _storeType.text.trim(),
        },
        if (isInfluencer) ...{
          'social_links': _socialLinks.text.trim(),
          'specialty':    _specialty.text.trim(),
          'resume':       _resume.text.trim(),
        },
        if (isDriver) ...{
          'vehicle_type':  _vehicleType.text.trim(),
          'vehicle_plate': _vehiclePlate.text.trim(),
        },
      };

      final result = await widget.api.updateCurrentUserWithImage(
        token, updates,
        profileImagePath:   _pickedProfile?.path,
        vehicleImagePath:   _pickedVehicle?.path,
        nationalIdPath:     _pickedNationalId?.path,
        drivingLicensePath: _pickedDrivingLicense?.path,
        storeLogoPath:      _pickedStoreLogo?.path,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final updated = User.fromJson(Map<String, dynamic>.from(result['body']), token);
        widget.onSaved(updated);
        // Show snack BEFORE pop so context is still valid
        showAppSnack(context, 'Profil mis à jour', type: MessageType.success);
        Navigator.pop(context);
      } else {
        final error = result['error'] as String? ?? 'Échec de la mise à jour';
        debugPrint('[Save] Error: $error');
        _showError(error);
      }
    } catch (e) {
      debugPrint('[Save] Exception: $e');
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Parse a DRF error string like "HTTP 400: {"field": ["msg"]}" into human-readable text
  String _parseApiError(String raw) {
    final idx = raw.indexOf(': {');
    if (idx >= 0) {
      try {
        final decoded = jsonDecode(raw.substring(idx + 2)) as Map<String, dynamic>;
        final lines = <String>[];
        for (final e in decoded.entries) {
          final msgs = e.value is List ? (e.value as List).join(', ') : e.value.toString();
          lines.add('• ${e.key}: $msgs');
        }
        if (lines.isNotEmpty) return lines.join('\n');
      } catch (_) {}
    }
    return raw;
  }

  void _showError(String raw) {
    final msg = _parseApiError(raw);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erreur de mise à jour'),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  Widget _field(_FieldDef f) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: f.ctrl,
      keyboardType: f.type,
      maxLines: f.maxLines,
      validator: f.required ? (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null : null,
      decoration: InputDecoration(
        labelText: f.label,
        prefixIcon: Icon(f.icon, size: 20, color: widget.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightBlue)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightBlue)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.primaryBlue, width: 1.5)),
      ),
    ),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.primaryBlue)),
  );

  Widget _imagePicker({required String label, required File? picked, required String? existingPath, required String target}) {
    final url = ApiConfig.mediaUrl(existingPath);
    ImageProvider? img;
    if (picked != null) {
      img = FileImage(picked);
    } else if (url != null) {
      img = CachedNetworkImageProvider(url);
    }
    return GestureDetector(
      onTap: () => _showSourceSheet(target: target),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: widget.accentBlue.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBlue),
          image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
        ),
        child: img == null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_photo_alternate_outlined, color: widget.primaryBlue, size: 32),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(color: widget.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
              ]))
            : Align(alignment: Alignment.bottomRight, child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.edit, color: widget.primaryBlue, size: 16),
                ),
              )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u    = widget.user;
    final role = u.role;
    final isVendor     = role == 'vendor';
    final isInfluencer = role == 'influencer';
    final isDriver     = role == 'driver';
    final showBank     = role != 'admin';
    final profileUrl   = ApiConfig.mediaUrl(u.profileImage);
    final hasCoords    = _lat.text.isNotEmpty && _lng.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: widget.accentBlue, borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.roleIcon, color: widget.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Modifier le profil', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                      Text(widget.roleLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  )),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar
              Center(child: Stack(children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: widget.accentBlue,
                  backgroundImage: _pickedProfile != null
                      ? FileImage(_pickedProfile!) as ImageProvider
                      : (profileUrl != null ? CachedNetworkImageProvider(profileUrl) : null),
                  child: (_pickedProfile == null && profileUrl == null)
                      ? Icon(widget.roleIcon, size: 46, color: widget.primaryBlue) : null,
                ),
                Positioned(bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: () => _showSourceSheet(),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: widget.primaryBlue, shape: BoxShape.circle,
                          border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 2))),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ])),
              const SizedBox(height: 20),

              // Personal info
              _sectionTitle('Informations personnelles'),
              _field(_FieldDef(ctrl: _firstName,  label: 'Prénom',            icon: Icons.person_outline,       type: TextInputType.name)),
              _field(_FieldDef(ctrl: _lastName,   label: 'Nom',               icon: Icons.person_outline,       type: TextInputType.name)),
              // Username shown as read-only — it's the login ID and cannot be changed
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightBlue),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email, size: 20, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nom d'utilisateur",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(height: 2),
                            Text(widget.user.username,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              _field(_FieldDef(ctrl: _email,      label: 'Email',             icon: Icons.email_outlined,       type: TextInputType.emailAddress, required: true)),
              _field(_FieldDef(ctrl: _phone,      label: 'Téléphone',         icon: Icons.phone_outlined,       type: TextInputType.phone)),
              _field(_FieldDef(ctrl: _address,    label: 'Adresse',           icon: Icons.location_on_outlined, maxLines: 2)),

              // Bank
              if (showBank) ...[
                _sectionTitle('Informations financières'),
                _field(_FieldDef(ctrl: _bank, label: 'Compte bancaire / RIB', icon: Icons.account_balance_outlined, type: TextInputType.number)),
              ],

              // Vendor
              if (isVendor) ...[
                _sectionTitle('Informations du magasin'),
                _field(_FieldDef(ctrl: _storeName, label: 'Nom du magasin',      icon: Icons.storefront_outlined)),
                _field(_FieldDef(ctrl: _storeDesc, label: 'Description',         icon: Icons.description_outlined, maxLines: 4)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DropdownButtonFormField<String>(
                    initialValue: shopCategories.any((c) => c.id == _storeType.text)
                        ? _storeType.text
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Type de magasin',
                      prefixIcon: Icon(Icons.category_outlined, color: widget.accentBlue, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.primaryBlue, width: 1.5)),
                    ),
                    items: shopCategories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 18, color: widget.accentBlue),
                          const SizedBox(width: 10),
                          Text(cat.name, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) => _storeType.text = v ?? '',
                    hint: const Text('Choisir une catégorie'),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Logo du magasin', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Ajouter logo', picked: _pickedStoreLogo,  existingPath: u.storeLogo,  target: 'store_logo'),
                const SizedBox(height: 14),
                Text('Carte nationale', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Ajouter carte nationale', picked: _pickedNationalId, existingPath: u.nationalId, target: 'national_id'),
                const SizedBox(height: 14),
              ],

              // Influencer
              if (isInfluencer) ...[
                _sectionTitle('Profil Influenceur'),
                Text('Carte nationale', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Ajouter carte nationale', picked: _pickedNationalId, existingPath: u.nationalId, target: 'national_id'),
                const SizedBox(height: 14),
                _field(_FieldDef(ctrl: _specialty,   label: 'Domaine de spécialisation', icon: Icons.workspace_premium_outlined)),
                _field(_FieldDef(ctrl: _resume,      label: 'Curriculum vitae',          icon: Icons.description_outlined, maxLines: 4)),
                _field(_FieldDef(ctrl: _socialLinks, label: 'Liens des réseaux sociaux', icon: Icons.link_outlined, maxLines: 2)),
              ],

              // Driver
              if (isDriver) ...[
                _sectionTitle('Photo de profil'),
                Text('Votre photo', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Changer la photo de profil', picked: _pickedProfile, existingPath: u.profileImage, target: 'profile'),
                const SizedBox(height: 14),
                _sectionTitle('Informations du véhicule'),
                Text('Carte nationale', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Ajouter carte nationale', picked: _pickedNationalId, existingPath: u.nationalId, target: 'national_id'),
                const SizedBox(height: 14),
                Text('Permis de conduire', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Ajouter permis', picked: _pickedDrivingLicense, existingPath: u.drivingLicense, target: 'driving_license'),
                const SizedBox(height: 14),
                _field(_FieldDef(ctrl: _vehicleType,  label: 'Type de véhicule',         icon: Icons.directions_car_outlined)),
                _field(_FieldDef(ctrl: _vehiclePlate, label: "Plaque d'immatriculation", icon: Icons.pin_outlined)),
                const SizedBox(height: 4),
                Text('Photo du véhicule', style: TextStyle(fontSize: 12, color: widget.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _imagePicker(label: 'Ajouter photo du véhicule', picked: _pickedVehicle, existingPath: u.vehicleImage, target: 'vehicle'),
                const SizedBox(height: 14),
              ],

              // Location
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightBlue)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.my_location_outlined, size: 18, color: widget.primaryBlue),
                      const SizedBox(width: 8),
                      const Text('Localisation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      hasCoords ? '${_lat.text}, ${_lng.text}' : 'Aucune position enregistrée',
                      style: TextStyle(fontSize: 13, color: hasCoords ? Colors.black : Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickLocation,
                        icon: const Icon(Icons.gps_fixed_outlined, size: 16),
                        label: const Text('Utiliser ma position actuelle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.primaryBlue,
                          side: BorderSide(color: widget.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(_saving ? 'Enregistrement...' : 'Enregistrer',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditableProfileTab extends StatefulWidget {
  final User initialUser;
  final Color primaryBlue;
  final Color accentBlue;

  const EditableProfileTab({
    super.key,
    required this.initialUser,
    required this.primaryBlue,
    required this.accentBlue,
  });

  @override
  State<EditableProfileTab> createState() => _EditableProfileTabState();
}

class _EditableProfileTabState extends State<EditableProfileTab> {
  final ApiService _api = ApiService();

  late User _profileUser;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _profileUser = widget.initialUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = widget.initialUser.token;
    if (token == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    final result = await _api.getCurrentUser(token);
    if (!mounted) return;
    if (result['success'] == true) {
      final user = User.fromJson(
        Map<String, dynamic>.from(result['body']),
        token,
      );
      setState(() {
        _profileUser = user;
        _loadingProfile = false;
      });
      return;
    }
    setState(() => _loadingProfile = false);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'vendor':
        return 'Marchand';
      case 'influencer':
        return 'Influenceur';
      case 'driver':
        return 'Livreur';
      case 'admin':
        return 'Admin';
      default:
        return 'Client';
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'vendor':
        return Icons.storefront;
      case 'influencer':
        return Icons.campaign_outlined;
      case 'driver':
        return Icons.local_shipping_outlined;
      default:
        return Icons.person;
    }
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProfileEditSheet(
        user: _profileUser,
        primaryBlue: widget.primaryBlue,
        accentBlue: widget.accentBlue,
        api: _api,
        roleLabel: _roleLabel(_profileUser.role),
        roleIcon: _roleIcon(_profileUser.role),
        onSaved: (updated) => setState(() => _profileUser = updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final u = _profileUser;
    final profileUrl = ApiConfig.mediaUrl(u.profileImage);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 56,
              backgroundColor: widget.accentBlue,
              backgroundImage: profileUrl != null
                  ? CachedNetworkImageProvider(profileUrl)
                  : null,
              child: profileUrl == null
                  ? Icon(_roleIcon(u.role), size: 54, color: widget.primaryBlue)
                  : null,
            ),
            const SizedBox(height: 18),

            // Name
            Text(
              u.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: widget.accentBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _roleLabel(u.role),
                style: TextStyle(
                  color: widget.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Edit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openEditSheet,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text(
                  'Modifier le profil',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => RoleRouter.confirmLogout(context),
                icon: const Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _FieldDef {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  final bool required;

  const _FieldDef({
    required this.ctrl,
    required this.label,
    this.icon = Icons.edit_outlined,
    this.type = TextInputType.text,
    this.maxLines = 1,
    this.required = false,
  });
}
