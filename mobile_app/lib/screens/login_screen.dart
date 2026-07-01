import 'package:flutter/material.dart';
import '../models/users.dart';
import '../services/api_service.dart';
import '../utils/role_router.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Définition de la charte graphique blanc / bleu
  final Color primaryBlue = AppColors.primaryBlue;
  final Color backgroundWhite = AppColors.background;
  final Color accentBlue = AppColors.lightBlue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Affichage du logo
              Image.asset(
                'assets/images/logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: accentBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.shopping_basket_outlined,
                    size: 60,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Titre Login
              Text(
                'Login',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bienvenue sur votre espace de commerce local',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Champ identifiant
              _buildModernTextField(
                controller: _phoneController,
                label: 'Téléphone ou nom d\'utilisateur',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              // Champ Code
              _buildModernTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleObscure: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),

              const SizedBox(height: 32),

              // Bouton Se connecter
              GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Lien d'inscription
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    "Vous n'avez pas de compte ? ",
                    style: TextStyle(color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
          prefixIcon: Icon(icon, color: primaryBlue, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black,
                    size: 22,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: primaryBlue.withValues(alpha: 0.1),
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

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showMessage('Veuillez saisir votre identifiant et votre mot de passe');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.login(phone, password);

    if (!mounted) return;

    if (result['success'] == true) {
      final accessToken = result['body']['access'];
      if (accessToken == null || accessToken.isEmpty) {
        setState(() => _isLoading = false);
        _showMessage("Impossible d'ouvrir votre session. Veuillez réessayer.");
        return;
      }

      final profile = await _apiService.getCurrentUser(accessToken);
      if (!mounted) return;
      setState(() => _isLoading = false);

      User currentUser;
      if (profile['success'] == true) {
        currentUser = User.fromJson(profile['body'], accessToken);
      } else {
        currentUser = User(
          id: 0,
          username: phone,
          role: 'customer',
          token: accessToken,
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoleRouter.dashboardFor(currentUser),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      final err = result['error']?.toString() ?? '';
      if (err.contains('Unable to reach') ||
          err.contains('SocketException') ||
          err.contains('Timeout')) {
        _showMessage(
          "Connexion au serveur impossible. Veuillez vérifier votre connexion réseau et réessayer.",
        );
      } else if (err.contains('attente') || err.contains('approbation')) {
        _showMessage(
          "Votre compte est en attente d'approbation par l'administrateur.",
        );
      } else {
        _showMessage(
          'Identifiant ou mot de passe incorrect. Veuillez réessayer.',
        );
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    final isErrorMsg =
        isError ||
        message.contains('Erreur') ||
        message.contains('incorrect') ||
        message.contains('impossible');
    final messageColor = isErrorMsg
        ? AppColors.primaryBlue
        : AppColors.primaryBlue;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: messageColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
