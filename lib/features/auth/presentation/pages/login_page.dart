import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/theme/congress_background.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_event.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: CongressBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return GlassCard(
                    radius: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'AFRIC',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.08,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '.',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.highlight,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'The Queens Edition — Admin Panel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.16,
                            color: AppColors.goldLight,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Sign in to manage the congress app',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LoginForm(
                          enabled: !state.isLoading,
                          error: state.error,
                        ),
                        if (state.isLoading) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final bool enabled;
  final String? error;

  const _LoginForm({required this.enabled, this.error});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthBloc>().add(
          SignInRequested(email: email, password: password),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassTextField(
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          hint: 'admin@afric-eg.com',
        ),
        const SizedBox(height: 14),
        GlassTextField(
          label: 'Password',
          controller: _password,
          obscureText: true,
          hint: '••••••••',
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.error!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.liveRed,
            ),
          ),
        ],
        const SizedBox(height: 18),
        GlassButton(
          label: 'Sign In',
          icon: Icons.lock_outline,
          onPressed: widget.enabled ? _submit : null,
        ),
      ],
    );
  }
}
