import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aegis_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Emergency medical details
  final _bloodGroupController = TextEditingController(text: 'O+');
  final _allergiesController = TextEditingController(text: 'None');
  final _medicalNotesController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showMedicalSection = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AegisColors.dangerRed : AegisColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final emergencyProfile = {
      'blood_group': _bloodGroupController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'medical_notes': _medicalNotesController.text.trim(),
    };

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: email,
      password: password,
      fullName: name,
      phone: phone.isNotEmpty ? phone : null,
      emergencyProfile: emergencyProfile,
    );

    if (mounted) {
      if (success) {
        _showSnackBar('Account created and verified in Firebase!', isError: false);
        // Pop back to root if register was pushed
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        _showSnackBar(authProvider.errorMessage ?? 'Registration failed.');
      }
    }
  }

  void _fillSampleData() {
    setState(() {
      _nameController.text = 'Jane Doe';
      _emailController.text = 'jane.doe@aegis-one.org';
      _phoneController.text = '+1555019823';
      _passwordController.text = 'Password123!';
      _confirmPasswordController.text = 'Password123!';
      _bloodGroupController.text = 'A+';
      _allergiesController.text = 'Penicillin';
      _medicalNotesController.text = 'Asthma (Carries inhaler)';
      _showMedicalSection = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shield Icon & Banner
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AegisColors.primaryBlueLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AegisColors.primaryBlue.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: AegisColors.primaryBlue,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AEGIS Registration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AegisColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Saved & validated in Firebase Authentication & Cloud Firestore',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AegisColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name.' : null,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: const Icon(Icons.person_outline, color: AegisColors.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AegisColors.background,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email Address
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                        if (!v.contains('@') || !v.contains('.')) return 'Invalid email address.';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: const Icon(Icons.email_outlined, color: AegisColors.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AegisColors.background,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (for emergency SMS dispatch)',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AegisColors.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AegisColors.background,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter a password.';
                        if (v.length < 6) return 'Password must be at least 6 characters.';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password (min 6 characters) *',
                        prefixIcon: const Icon(Icons.lock_outline, color: AegisColors.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AegisColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AegisColors.background,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: (v) {
                        if (v != _passwordController.text) return 'Passwords do not match.';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock_reset, color: AegisColors.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: AegisColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AegisColors.background,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Emergency Medical Card Toggle
                    InkWell(
                      onTap: () => setState(() => _showMedicalSection = !_showMedicalSection),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AegisColors.primaryBlueLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AegisColors.primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.medical_services_outlined, color: AegisColors.primaryBlue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Emergency Medical Profile (Optional)',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AegisColors.primaryBlue),
                                ),
                              ],
                            ),
                            Icon(
                              _showMedicalSection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AegisColors.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showMedicalSection) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bloodGroupController,
                              decoration: InputDecoration(
                                labelText: 'Blood Group',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: AegisColors.background,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _allergiesController,
                              decoration: InputDecoration(
                                labelText: 'Allergies',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: AegisColors.background,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _medicalNotesController,
                        decoration: InputDecoration(
                          labelText: 'Medical Notes / Conditions',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: AegisColors.background,
                          isDense: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Register Button
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
                              'Create Account & Connect',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 10),

                    // Auto-fill sample button
                    TextButton.icon(
                      onPressed: _fillSampleData,
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Auto-Fill Sample Registration'),
                    ),
                    const SizedBox(height: 16),

                    // Already have an account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AegisColors.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AegisColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

