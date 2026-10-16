import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await ref.read(currentUserProvider.notifier).register(
              _nameController.text.trim(),
              _emailController.text.trim(),
              _studentIdController.text.trim(),
              null,
            );
      } else {
        await ref.read(currentUserProvider.notifier).signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      }
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Student Registration' : 'Campus Sign In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & App Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.travel_explore,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Finders Keepers?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'VIT Campus Lost & Found Network',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (_isSignUp) ...[
                const Text('Full Name *',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'e.g. Aarav Sharma'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                const Text('Student Registration Number *',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(hintText: 'e.g. 23BCE1042'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter your registration number'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              const Text('Campus Email *',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    hintText: 'e.g. student@vitstudent.ac.in'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),

              const Text('Password *',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••••'),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp
                      ? 'Already have an account? Sign In'
                      : 'New student? Register here'),
                ),
              ),
              const SizedBox(height: 32),

              // Fast Demo Profile Switcher
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: AppTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Evaluator Fast-Switch Profiles',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any persona below to immediately log in and test two-party claim verification workflows:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 12),
                    ...AuthService.demoStudents.map((persona) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            persona.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${persona.studentId} • Role: ${persona.role.toUpperCase()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () async {
                            await ref
                                .read(currentUserProvider.notifier)
                                .switchProfile(persona);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.statusReturned,
                                  content: Text(
                                      'Switched to ${persona.displayName} (${persona.role})'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
