import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.resetPassword(_emailController.text.trim());

      if (success && mounted) {
        setState(() {
          _emailSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_reset_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Forgot Password?',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                _emailSent
                    ? 'Check your email for a password reset link'
                    : 'Enter your email address to receive a password reset link',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (!_emailSent)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 30),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          if (authProvider.isLoading) {
                            return const CircularProgressIndicator();
                          }

                          if (authProvider.error != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.error!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              authProvider.clearError();
                            });
                          }

                          return AppButton(
                            onPressed: _resetPassword,
                            text: 'Send Reset Link',
                            width: double.infinity,
                          );
                        },
                      ),
                    ],
                  ),
                ),

              if (_emailSent)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      text: 'Back to Login',
                      width: double.infinity,
                      variant: 'outline',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}