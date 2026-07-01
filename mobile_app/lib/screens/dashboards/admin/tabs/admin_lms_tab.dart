import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/api_config.dart';
import '../../../../models/users.dart';
import '../../../../services/api_service.dart';

class AdminLmsTab extends StatefulWidget {
  final User user;
  const AdminLmsTab({super.key, required this.user});

  @override
  State<AdminLmsTab> createState() => _AdminLmsTabState();
}

class _AdminLmsTabState extends State<AdminLmsTab> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];

  static const _blue = AppColors.primaryBlue;

  int get _totalLearners => _courses.fold<int>(
    0,
    (sum, course) =>
        sum + (int.tryParse('${course['student_count'] ?? 0}') ?? 0),
  );

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
    final res = await _api.fetchServices(token);
    if (!mounted) return;
    setState(() {
      if (res.isSuccess) {
        _courses = res.data!
            .where(
              (s) => (s['type']?.toString() ?? '').toLowerCase().contains(
                'course',
              ),
            )
            .toList();
      }
      _loading = false;
    });
  }

  Future<void> _deleteCourse(int id) async {
    final token = widget.user.token;
    if (token == null) return;
    final confirm = await _confirmDialog('Supprimer ce cours ?');
    if (confirm != true) return;
    final res = await _api.deleteServiceAdmin(token, id);
    if (!mounted) return;
    if (res['success'] == true) {
      _showSnack('Cours supprimé.', success: true);
      _load();
    } else {
      _showSnack('Impossible de supprimer ce cours.');
    }
  }

  void _showCourseForm({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(
      text:
          existing?['title']?.toString() ?? existing?['name']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final linkCtrl = TextEditingController(
      text: existing?['content_link']?.toString() ?? '',
    );
    String? imagePath;
    String? previewUrl = ApiConfig.mediaUrl(existing?['image']?.toString());

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
                Text(
                  existing == null ? 'Nouveau cours' : 'Modifier le cours',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 18),
                _formField(titleCtrl, 'Titre du cours'),
                const SizedBox(height: 12),
                _formField(
                  priceCtrl,
                  'Prix (MRU)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _formField(linkCtrl, 'Lien vidéo (Google Drive / YouTube)'),
                const SizedBox(height: 12),
                _formField(descCtrl, 'Description', maxLines: 3),
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
                        previewUrl = null;
                      });
                    }
                  },
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lightBlue),
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
                        : previewUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              previewUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => _imgPlaceholder(),
                            ),
                          )
                        : _imgPlaceholder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final fields = {
                        'title': titleCtrl.text.trim(),
                        'name': titleCtrl.text.trim(),
                        'price': priceCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'content_link': linkCtrl.text.trim(),
                        'type': 'course',
                      };
                      if (existing == null) {
                        await _createCourse(fields, imagePath);
                      } else {
                        await _updateCourse(
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
                      existing == null ? 'Créer le cours' : 'Enregistrer',
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

  Future<void> _createCourse(
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
      _showSnack('Cours créé avec succès.', success: true);
      _load();
    } else {
      _showSnack('Impossible de créer ce cours.');
    }
  }

  Future<void> _updateCourse(
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
      _showSnack('Cours mis à jour.', success: true);
      _load();
    } else {
      _showSnack('Impossible de mettre à jour ce cours.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Formations en ligne',
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCourseForm(),
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

          // Stats
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'TOTAL COURS',
                  _courses.length.toString(),
                  _blue,
                  Icons.menu_book_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'APPRENANTS',
                  _totalLearners.toString(),
                  AppColors.primaryBlue,
                  Icons.people_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Course list
          if (_courses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: _blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Aucun cours disponible.',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Appuyez sur "Ajouter" pour créer le premier cours.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._courses.map((c) {
              final imageUrl = ApiConfig.mediaUrl(c['image']?.toString());
              final title =
                  c['title']?.toString() ?? c['name']?.toString() ?? '';
              final price =
                  double.tryParse((c['price'] ?? 0).toString()) ?? 0.0;
              final desc = c['description']?.toString() ?? '';
              final link = c['content_link']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBlue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _thumbPlaceholder(),
                              )
                            : _thumbPlaceholder(),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${price.toStringAsFixed(2)} MRU',
                                  style: const TextStyle(
                                    color: _blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (link.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.play_circle_outline,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    'Vidéo disponible',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else
                                const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCourseForm(existing: c),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Modifier',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _blue,
                                    side: const BorderSide(color: _blue),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _deleteCourse(c['id'] as int),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Supprimer',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
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
            }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: AppColors.lightBlue,
    child: const Center(
      child: Icon(Icons.school_outlined, color: _blue, size: 40),
    ),
  );

  Widget _imgPlaceholder() => const Column(
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
