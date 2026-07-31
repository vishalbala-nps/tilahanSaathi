import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tilahan_saathi/core/network/error_message.dart';
import 'package:tilahan_saathi/core/theme/app_colors.dart';
import 'package:tilahan_saathi/core/widgets/app_card.dart';
import 'package:tilahan_saathi/core/widgets/primary_button.dart';
import 'package:tilahan_saathi/features/auth/auth_validators.dart';
import 'package:tilahan_saathi/providers/auth_provider.dart';
import 'package:tilahan_saathi/router/app_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _linkSent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) setState(() => _linkSent = true);
    } on FirebaseAuthException catch (error) {
      // Don't reveal whether an account exists for this email.
      if (error.code == 'user-not-found') {
        if (mounted) setState(() => _linkSent = true);
      } else if (mounted) {
        setState(() => _errorMessage = friendlyErrorMessage(error));
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: _linkSent ? _buildSentState(theme) : _buildFormState(theme),
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Forgot Password?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your email and we'll send you a link to reset your password",
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: AuthValidators.email,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: CircularProgressIndicator()),
                )
              : PrimaryButton(label: 'Send Reset Link', onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildSentState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            children: [
              const Icon(Icons.mark_email_read_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Check Your Email',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'If an account exists for ${_emailController.text.trim()}, '
                "you'll receive a password reset link shortly.",
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Back to Log In',
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
