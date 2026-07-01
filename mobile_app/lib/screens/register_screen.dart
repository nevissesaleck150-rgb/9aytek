import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _resumeController = TextEditingController();
  final _socialLinksController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<String> _roles = ['Client', 'Vendeur', 'Influenceur', 'Livreur'];
  String _selectedRole = 'Client';

  final List<String> _shopTypes = [
    'Alimentation et boissons',
    'Articles ménagers',
    'Supermarché et produits alimentaires',
    'Mode et vêtements',
    'Électronique et technologie',
  ];
  String _selectedShopType = 'Alimentation et boissons';

  LatLng? _selectedLocation;
  String? _nationalIdPath;
  String? _storeLogoPath;
  String? _profileImagePath;
  String? _vehicleImagePath;
  String? _drivingLicensePath;

  // Couleurs de l'interface
  final Color primaryBlue = AppColors.primaryBlue;
  final Color backgroundWhite = AppColors.background;
  final Color accentBlue = AppColors.lightBlue;

  bool get _isCustomer => _selectedRole == 'Client';
  bool get _isVendor => _selectedRole == 'Vendeur';
  bool get _isInfluencer => _selectedRole == 'Influenceur';
  bool get _isDriver => _selectedRole == 'Livreur';

  String _roleDisplayToApi(String role) {
    final roleMap = {
      'Client': 'customer',
      'Vendeur': 'vendor',
      'Influenceur': 'influencer',
      'Livreur': 'driver',
    };
    return roleMap[role] ?? 'customer';
  }

  Future<void> _register() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final bankAccount = _bankAccountController.text.trim();
    final storeName = _storeNameController.text.trim();
    final storeDescription = _storeDescriptionController.text.trim();
    final resume = _resumeController.text.trim();
    final socialLinks = _socialLinksController.text.trim();
    final specialty = _specialtyController.text.trim();
    final vehicleType = _vehicleTypeController.text.trim();
    final vehiclePlate = _vehiclePlateController.text.trim();

    final missingFields = <String>[];

    if (fullName.isEmpty) missingFields.add('Nom complet');
    if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      missingFields.add('Adresse e-mail valide');
    }
    if (password.isEmpty) missingFields.add('Mot de passe');
    if (phone.isEmpty) missingFields.add('Numéro de téléphone');
    if (bankAccount.isEmpty) missingFields.add('Numéro de compte bancaire');

    if (_isCustomer) {
      if (address.isEmpty) missingFields.add('Adresse détaillée');
      if (_selectedLocation == null) missingFields.add('Localisation');
    }

    if (_isVendor) {
      if (storeName.isEmpty) missingFields.add('Nom du magasin');
      if (_storeLogoPath == null) missingFields.add('Logo du magasin');
      if (_nationalIdPath == null) {
        missingFields.add('Photo de la carte nationale');
      }
      if (storeDescription.isEmpty) missingFields.add('Description détaillée');
      if (_selectedLocation == null) missingFields.add('Adresse géographique');
    }

    if (_isInfluencer) {
      if (_profileImagePath == null) missingFields.add('Votre photo');
      if (_nationalIdPath == null) {
        missingFields.add('Photo de la carte nationale');
      }
      if (resume.isEmpty) missingFields.add('Curriculum vitae');
      if (socialLinks.isEmpty) missingFields.add('Liens des réseaux sociaux');
      if (specialty.isEmpty) missingFields.add('Domaine de spécialisation');
    }

    if (_isDriver) {
      if (_profileImagePath == null) missingFields.add('Votre photo de profil');
      if (_nationalIdPath == null) {
        missingFields.add('Photo de la carte nationale');
      }
      if (_drivingLicensePath == null) missingFields.add('Permis de conduire');
      if (vehicleType.isEmpty) missingFields.add('Type de véhicule');
      if (vehiclePlate.isEmpty) missingFields.add('Numéro de plaque');
      if (_vehicleImagePath == null) missingFields.add('Photo du véhicule');
      if (_selectedLocation == null) missingFields.add('Localisation');
    }

    if (missingFields.isNotEmpty) {
      _showMessage('Veuillez remplir : ${missingFields.join(', ')}');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Split full_name into first_name / last_name so Django admin shows them correctly
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

      final extraFields = <String, dynamic>{
        'full_name': fullName,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'address': address,
        'bank_account': bankAccount,
      };

      if (_selectedLocation != null) {
        extraFields['latitude'] = _selectedLocation!.latitude.toStringAsFixed(
          6,
        );
        extraFields['longitude'] = _selectedLocation!.longitude.toStringAsFixed(
          6,
        );
      }

      if (_isVendor) {
        extraFields.addAll({
          'store_name': storeName,
          'store_description': storeDescription,
          'store_type': _selectedShopType,
        });
      }

      if (_isInfluencer) {
        extraFields.addAll({
          'resume': resume,
          'social_links': socialLinks,
          'specialty': specialty,
        });
      }

      if (_isDriver) {
        extraFields.addAll({
          'vehicle_type': vehicleType,
          'vehicle_plate': vehiclePlate,
        });
      }

      final filePaths = <String, String>{};
      if (_nationalIdPath != null) filePaths['national_id'] = _nationalIdPath!;
      if (_storeLogoPath != null) filePaths['store_logo'] = _storeLogoPath!;
      if (_profileImagePath != null) {
        filePaths['profile_image'] = _profileImagePath!;
      }
      if (_vehicleImagePath != null) {
        filePaths['vehicle_image'] = _vehicleImagePath!;
      }
      if (_drivingLicensePath != null) {
        filePaths['driving_license'] = _drivingLicensePath!;
      }

      final result = await _apiService.register(
        username: fullName,
        email: email,
        password: password,
        role: _roleDisplayToApi(_selectedRole),
        extraFields: extraFields,
        filePaths: filePaths.isEmpty ? null : filePaths,
      );

      if (result['success'] == true) {
        _showMessage(
          "Compte créé avec succès. Il sera examiné par l'administrateur avant l'activation.",
        );
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMessage(
          "Impossible de créer le compte. Veuillez vérifier les informations et réessayer.",
        );
      }
    } catch (e) {
      _showMessage(
        "Une erreur s'est produite. Veuillez vérifier la connexion et réessayer plus tard.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(Function(String?) callback) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      callback(picked.path);
    }
  }

  Future<Position?> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Localisation désactivée'),
            content: const Text(
              'Le service de localisation est désactivé. Voulez-vous ouvrir les paramètres pour l\'activer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ouvrir paramètres'),
              ),
            ],
          ),
        );
        if (open == true) await Geolocator.openLocationSettings();
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission refusée'),
            content: const Text(
              'L\'accès à la localisation a été refusé définitivement. Veuillez l\'activer depuis les paramètres de l\'application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ouvrir paramètres'),
              ),
            ],
          ),
        );
        if (open == true) await Geolocator.openAppSettings();
      }
      return null;
    }
    if (permission == LocationPermission.denied) {
      _showMessage("L'autorisation d'accès à la localisation a été refusée.");
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _setCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await _determinePosition();
      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      _showMessage('Impossible de récupérer la position actuelle.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 86,
                  width: 86,
                  decoration: BoxDecoration(
                    color: accentBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    size: 40,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Créer un nouveau compte',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Choisissez le type de compte et complétez les informations requises. L'accès sera validé par l'administrateur.",
              style: TextStyle(color: Colors.black, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            _buildRoleSelector(),
            const SizedBox(height: 20),

            _buildTextField(
              _fullNameController,
              'Nom complet',
              Icons.person_outline,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              _phoneController,
              'Numéro de téléphone',
              Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              _emailController,
              'Adresse e-mail',
              Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              _passwordController,
              'Mot de passe',
              Icons.lock_open_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 16),

            if (_isCustomer || _isVendor) ...[
              _buildTextField(
                _addressController,
                'Adresse détaillée',
                Icons.location_city,
              ),
              const SizedBox(height: 14),
            ],

            if (_isVendor) ...[
              _buildTextField(
                _storeNameController,
                'Nom du magasin',
                Icons.storefront,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                _storeDescriptionController,
                'Description détaillée du magasin',
                Icons.description,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 14),
              _buildDropdownField(
                label: 'Type de magasin',
                items: _shopTypes,
                value: _selectedShopType,
                icon: Icons.category,
                onChanged: (val) => setState(() => _selectedShopType = val!),
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Photo de la carte nationale',
                filePath: _nationalIdPath,
                onPick: () => _pickImage(
                  (path) => setState(() => _nationalIdPath = path),
                ),
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Logo du magasin',
                filePath: _storeLogoPath,
                onPick: () =>
                    _pickImage((path) => setState(() => _storeLogoPath = path)),
              ),
              const SizedBox(height: 14),
            ],

            if (_isInfluencer) ...[
              _buildTextField(
                _specialtyController,
                'Domaine de spécialisation',
                Icons.workspace_premium,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                _resumeController,
                'Curriculum vitae',
                Icons.description,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                _socialLinksController,
                'Liens des réseaux sociaux',
                Icons.link,
                maxLines: 2,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Votre photo de profil',
                filePath: _profileImagePath,
                onPick: () => _pickImage(
                  (path) => setState(() => _profileImagePath = path),
                ),
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Photo de la carte nationale',
                filePath: _nationalIdPath,
                onPick: () => _pickImage(
                  (path) => setState(() => _nationalIdPath = path),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_isDriver) ...[
              _buildMediaPicker(
                label: 'Votre photo de profil',
                filePath: _profileImagePath,
                onPick: () => _pickImage(
                  (path) => setState(() => _profileImagePath = path),
                ),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                _vehicleTypeController,
                'Type de véhicule',
                Icons.directions_car,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                _vehiclePlateController,
                'Numéro de plaque',
                Icons.confirmation_number,
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Photo de la carte nationale',
                filePath: _nationalIdPath,
                onPick: () => _pickImage(
                  (path) => setState(() => _nationalIdPath = path),
                ),
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Permis de conduire',
                filePath: _drivingLicensePath,
                onPick: () => _pickImage(
                  (path) => setState(() => _drivingLicensePath = path),
                ),
              ),
              const SizedBox(height: 14),
              _buildMediaPicker(
                label: 'Photo du véhicule',
                filePath: _vehicleImagePath,
                onPick: () => _pickImage(
                  (path) => setState(() => _vehicleImagePath = path),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_isCustomer || _isVendor || _isDriver) ...[
              _buildLocationPicker(),
              const SizedBox(height: 14),
            ],

            _buildTextField(
              _bankAccountController,
              'Numéro de compte bancaire',
              Icons.account_balance,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),

            GestureDetector(
              onTap: _isLoading ? null : _register,
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Créer le compte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choisissez le type de compte',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: primaryBlue),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedRole = val;
                  _selectedLocation = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
          prefixIcon: Icon(icon, color: primaryBlue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: primaryBlue.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String value,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: primaryBlue),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPicker({
    required String label,
    required String? filePath,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: primaryBlue.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: filePath == null
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, color: primaryBlue),
                        const SizedBox(width: 8),
                        const Text(
                          'Appuyez pour sélectionner',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      File(filePath),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _setCurrentLocation,
            icon: const Icon(Icons.location_on, color: Colors.white),
            label: const Text(
              'Utiliser la position actuelle',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              disabledBackgroundColor: primaryBlue.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: _selectedLocation == null
              ? Center(
                  child: Text(
                    'Aucune position sélectionnée',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FlutterMap(
                    options: MapOptions(center: _selectedLocation, zoom: 15),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.myproject.mobile_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 50,
                            height: 50,
                            point: _selectedLocation!,
                            builder: (context) => const Icon(
                              Icons.location_pin,
                              size: 40,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 10),
          Text(
            'Coordonnées : ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Colors.black, fontSize: 13),
          ),
        ],
      ],
    );
  }

  void _showMessage(String message) {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return;
    final isSuccess =
        cleanMessage.contains('succès') || cleanMessage.contains('créé');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleanMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isSuccess ? AppColors.primaryBlue : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _resumeController.dispose();
    _socialLinksController.dispose();
    _specialtyController.dispose();
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }
}
