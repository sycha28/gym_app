import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'workouts_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String _selectedAvatar = 'https://api.dicebear.com/7.x/bottts/png?seed=Sycha1';

  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=Sycha1',
    'https://api.dicebear.com/7.x/bottts/png?seed=Sycha2',
    'https://api.dicebear.com/7.x/bottts/png?seed=Sycha3',
    'https://api.dicebear.com/7.x/bottts/png?seed=Sycha4',
  ];

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs obligatoires');
      return;
    }

    if (_isSignUp && fullName.isEmpty) {
      _showSnackBar('Veuillez entrer votre nom et prénom');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        final AuthResponse res = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'avatar_url': _selectedAvatar,
          },
        );

        if (mounted) {
          if (res.session != null) {
            _showSnackBar('Compte créé et connecté !');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WorkoutsListScreen()),
            );
          } else {
            _showSnackBar('Inscription réussie ! Connexion en cours...', isError: false);
            try {
              final signInRes = await _supabase.auth.signInWithPassword(email: email, password: password);
              if (mounted && signInRes.session != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const WorkoutsListScreen()),
                );
              }
            } catch (_) {
              setState(() => _isSignUp = false);
            }
          }
        }
      } else {
        final AuthResponse res = await _supabase.auth.signInWithPassword(email: email, password: password);
        if (mounted && res.session != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WorkoutsListScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnackBar('Erreur inattendue : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE05297), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE05297).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 60,
                      color: Color(0xFFE05297),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SychaFit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE05297),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'DÉPASSE-TOI. POUR TOI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_isSignUp) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom et Prénom',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFFE05297)),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email, color: Color(0xFFE05297)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFFE05297)),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE05297),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isSignUp ? 'S\'inscrire' : 'Se connecter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp ? 'Déjà un compte ? Se connecter' : 'Pas encore de compte ? S\'inscrire',
                      style: const TextStyle(color: Color(0xFFE05297), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}