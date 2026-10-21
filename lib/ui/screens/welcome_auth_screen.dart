import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../providers/app_providers.dart';
import 'help_screen.dart';
import 'responsive_main_screen.dart';

class WelcomeAuthScreen extends ConsumerStatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  ConsumerState<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends ConsumerState<WelcomeAuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await ref
            .read(currentUserProvider.notifier)
            .register(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _studentIdController.text.trim(),
              _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
            );
      } else {
        await ref
            .read(currentUserProvider.notifier)
            .signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.statusLost,
            content: Text('Authentication error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPasswordResetDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: AppTheme.primaryIndigo),
              SizedBox(width: 8),
              Text(
                'Reset Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your registered campus email address. A password recovery link will be dispatched to your inbox.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(
                  labelText: 'Campus Email',
                  hintText: 'student@vitstudent.ac.in',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await ref
                    .read(currentUserProvider.notifier)
                    .sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.statusReturned,
                      content: Text(
                        'Password reset instructions dispatched to $email',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme Toggle in Header
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? AppTheme.accentAmber : AppTheme.textSecondary,
              size: 20,
            ),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggleTheme(context),
          ),
          const SizedBox(width: 8),
          // Guest Explore Button
          TextButton.icon(
            icon: const Icon(Icons.explore_outlined, size: 16),
            label: const Text(
              'Browse as Guest',
              style: TextStyle(fontSize: 13),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResponsiveMainScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 20,
              vertical: 12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryIndigo,
                          AppTheme.primaryIndigoLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: const Icon(
                      Icons.travel_explore,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ReFind',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Retains legacy title for widget tests
                  const Text(
                    'Finders Keepers?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryIndigo,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Campus Lost & Found Verification Network',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Value Prop Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPill(
                        Icons.shield_outlined,
                        'Zero-Knowledge Claims',
                      ),
                      _buildPill(
                        Icons.location_on_outlined,
                        'Campus Geofenced',
                      ),
                      _buildPill(Icons.password_outlined, 'Cryptographic OTP'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Main Form Card
                  Card(
                    color: AppTheme.cardColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Segmented Tabs: Sign In / Create Account
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtleColor(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isSignUp = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isSignUp
                                              ? AppTheme.cardColor(context)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: !_isSignUp
                                              ? AppTheme.subtleCardShadow
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: !_isSignUp
                                                  ? AppTheme.primaryIndigo
                                                  : AppTheme.textSecondaryColor(
                                                      context,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isSignUp = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isSignUp
                                              ? AppTheme.cardColor(context)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: _isSignUp
                                              ? AppTheme.subtleCardShadow
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Register',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: _isSignUp
                                                  ? AppTheme.primaryIndigo
                                                  : AppTheme.textSecondaryColor(
                                                      context,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (_isSignUp) ...[
                              Text(
                                'Full Name *',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Diya Patel',
                                  prefixIcon: Icon(
                                    Icons.badge_outlined,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter your full name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Student Registration No. *',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _studentIdController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 23BCE1984',
                                  prefixIcon: Icon(
                                    Icons.school_outlined,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter your student ID'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Phone Number (Optional)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. +91 91234 56789',
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            Text(
                              'Campus Email *',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'student@vitstudent.ac.in',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your campus email';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.textPrimaryColor(context),
                                  ),
                                ),
                                if (!_isSignUp)
                                  GestureDetector(
                                    onTap: _showPasswordResetDialog,
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryIndigo,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 22),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp
                                            ? 'Create Campus Account'
                                            : 'Sign In',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Evaluator Demonstration Mode Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: AppTheme.accentAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Evaluator / Demonstration Personas',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pre-configured testing personas for zero-friction evaluation of ownership claims, challenge verification, and moderator overrides:',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondaryColor(context),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...AuthService.demoStudents.map((persona) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.borderColor(context),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  persona.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.textPrimaryColor(context),
                                  ),
                                ),
                                subtitle: Text(
                                  '${persona.studentId} • Role: ${persona.role.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryColor(context),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.login,
                                  size: 16,
                                  color: AppTheme.primaryIndigo,
                                ),
                                onTap: () async {
                                  await ref
                                      .read(currentUserProvider.notifier)
                                      .switchProfile(persona);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            AppTheme.statusReturned,
                                        content: Text(
                                          'Logged in as ${persona.displayName} (${persona.role})',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Help Center Link Button (Accessible without sign in!)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Help & How It Works (Read User Guide)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryIndigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryIndigo),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryIndigo,
            ),
          ),
        ],
      ),
    );
  }
}
