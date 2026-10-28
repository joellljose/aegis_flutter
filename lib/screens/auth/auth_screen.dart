import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aegis_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Login
  final _loginEmailController = TextEditingController(text: 'jane.doe@aegis-one.org');
  final _loginPasswordController = TextEditingController(text: 'Password123!');

  // Controllers for Register
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regBloodGroupController = TextEditingController(text: 'O+');
  final _regAllergiesController = TextEditingController(text: 'None');

  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regBloodGroupController.dispose();
    _regAllergiesController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AegisColors.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter your email and password.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email: email, password: password);

    if (!success && mounted) {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Authentication failed.');
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please provide full name, email, and password.');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters long.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final emergencyProfile = {
      'blood_group': _regBloodGroupController.text.trim(),
      'allergies': _regAllergiesController.text.trim(),
    };

    final success = await authProvider.register(
      email: email,
      password: password,
      fullName: name,
      phone: phone.isNotEmpty ? phone : null,
      emergencyProfile: emergencyProfile,
    );

    if (!success && mounted) {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Registration failed.');
    }
  }

  void _fillSampleRegistration() {
    setState(() {
      _regNameController.text = 'Jane Doe';
      _regEmailController.text = 'jane.doe@aegis-one.org';
      _regPhoneController.text = '+1555019823';
      _regPasswordController.text = 'Password123!';
      _regBloodGroupController.text = 'A+';
      _regAllergiesController.text = 'Penicillin';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding & Shield
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AegisColors.primaryBlueLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AegisColors.primaryBlue.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: AegisColors.primaryBlue,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AEGIS One',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AegisColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Smart Emergency Response Companion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AegisColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Bar for Sign In / Register
                  Container(
                    decoration: BoxDecoration(
                      color: AegisColors.primaryBlueLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AegisColors.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AegisColors.textPrimary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Register'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Views
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSignInForm(authProvider),
                        _buildRegisterForm(authProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined, color: AegisColors.primaryBlue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AegisColors.primaryBlue),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                color: AegisColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AegisColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Sign In to AEGIS One',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _loginEmailController.text = 'jane.doe@aegis-one.org';
              _loginPasswordController.text = 'Password123!';
            });
            _handleLogin();
          },
          icon: const Icon(Icons.bolt, color: AegisColors.primaryBlue, size: 18),
          label: const Text('Quick Demo Login (Jane Doe)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AegisColors.primaryBlue,
            side: const BorderSide(color: AegisColors.primaryBlueLight),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const Spacer(),
        const Center(
          child: Text(
            'Secured with Firebase Auth & FastAPI Admin SDK',
            style: TextStyle(fontSize: 12, color: AegisColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _regNameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: const Icon(Icons.person_outline, color: AegisColors.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              prefixIcon: const Icon(Icons.email_outlined, color: AegisColors.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number (for SMS dispatch)',
              prefixIcon: const Icon(Icons.phone_outlined, color: AegisColors.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            decoration: InputDecoration(
              labelText: 'Password (min 6 characters) *',
              prefixIcon: const Icon(Icons.lock_outline, color: AegisColors.primaryBlue),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                  color: AegisColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regBloodGroupController,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _regAllergiesController,
                  decoration: InputDecoration(
                    labelText: 'Allergies',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AegisColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Create Account & Profile',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fillSampleRegistration,
            child: const Text('Auto-Fill Sample Data'),
          ),
        ],
      ),
    );
  }
}
