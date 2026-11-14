import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_service.dart';
import 'phone_auth_view_model.dart';

const _resendCooldownSeconds = 30;

/// Two-step phone authentication screen for customer app (Mobile + OTP).
class PhoneAuthScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onAuthenticated;

  const PhoneAuthScreen({
    super.key,
    required this.onBack,
    required this.onAuthenticated,
  });

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _resendSecondsLeft = 0);
      } else {
        setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(phoneAuthViewModelProvider, (previous, next) {
      if (previous?.step != PhoneAuthStep.otp && next.step == PhoneAuthStep.otp) {
        _otpController.clear();
        _startResendCooldown();
      }
      if (previous?.step == PhoneAuthStep.otp && next.step == PhoneAuthStep.phone) {
        _resendTimer?.cancel();
        setState(() => _resendSecondsLeft = 0);
      }
    });

    final state = ref.watch(phoneAuthViewModelProvider);
    final notifier = ref.read(phoneAuthViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackButton(
                            onTap: state.step == PhoneAuthStep.otp
                                ? notifier.editPhoneNumber
                                : widget.onBack,
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.06, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: state.step == PhoneAuthStep.phone
                                  ? _PhoneStep(
                                      key: const ValueKey('phone'),
                                      controller: _phoneController,
                                      isSubmitting: state.isSubmitting,
                                      error: state.error,
                                      onContinue: () => notifier.submitPhone(_phoneController.text),
                                    )
                                  : _OtpStep(
                                      key: const ValueKey('otp'),
                                      controller: _otpController,
                                      phone: state.phone,
                                      isSubmitting: state.isSubmitting,
                                      error: state.error,
                                      resendSecondsLeft: _resendSecondsLeft,
                                      onEditNumber: notifier.editPhoneNumber,
                                      onResend: () {
                                        notifier.resendOtp();
                                        _startResendCooldown();
                                      },
                                      onVerify: () async {
                                        await notifier.verifyOtp(_otpController.text);
                                        if (mounted && ref.read(phoneAuthViewModelProvider).error == null) {
                                          widget.onAuthenticated();
                                        }
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryForeground.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryForeground.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: AppColors.primaryForeground,
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatefulWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final String? error;
  final VoidCallback onContinue;

  const _PhoneStep({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.error,
    required this.onContinue,
  });

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final canContinue = widget.controller.text.length == 10 && !widget.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Healthcare at\nyour Doorstep',
          style: appHeadingStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
            color: AppColors.primaryForeground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your phone number to access certified care.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.primaryForeground.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 32),
        const _FieldLabel('Mobile Number'),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryForeground.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 18),
                child: Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryForeground,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                width: 1,
                height: 26,
                color: AppColors.primaryForeground.withValues(alpha: 0.25),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onSubmitted: (_) {
                    if (canContinue) widget.onContinue();
                  },
                  style: const TextStyle(
                    color: AppColors.primaryForeground,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                  decoration: InputDecoration(
                    hintText: '98765 43210',
                    hintStyle: TextStyle(
                      color: AppColors.primaryForeground.withValues(alpha: 0.5),
                    ),
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 10),
          _ErrorText(widget.error!),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canContinue ? widget.onContinue : null,
            style: _primaryButtonStyle(),
            child: widget.isSubmitting
                ? const _ButtonSpinner()
                : const Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
          ),
        ),

      ],
    );
  }
}

class _OtpStep extends StatefulWidget {
  final TextEditingController controller;
  final String phone;
  final bool isSubmitting;
  final String? error;
  final int resendSecondsLeft;
  final VoidCallback onEditNumber;
  final VoidCallback onResend;
  final VoidCallback onVerify;

  const _OtpStep({
    super.key,
    required this.controller,
    required this.phone,
    required this.isSubmitting,
    required this.error,
    required this.resendSecondsLeft,
    required this.onEditNumber,
    required this.onResend,
    required this.onVerify,
  });

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  final _focusNode = FocusNode();
  late final TapGestureRecognizer _editRecognizer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _editRecognizer = TapGestureRecognizer()..onTap = widget.onEditNumber;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    _editRecognizer.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final canVerify = code.length == 6 && !widget.isSubmitting;
    final canResend = widget.resendSecondsLeft == 0 && !widget.isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Verify OTP',
          style: appHeadingStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.primaryForeground,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.primaryForeground.withValues(alpha: 0.75),
            ),
            children: [
              TextSpan(text: "We sent a 6-digit code to +91 ${widget.phone}. "),
              TextSpan(
                text: 'Edit',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primarySoft),
                recognizer: _editRecognizer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enter verification code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryForeground,
              ),
            ),
            GestureDetector(
              onTap: canResend ? widget.onResend : null,
              child: Text(
                canResend
                    ? 'Resend code'
                    : '0:${widget.resendSecondsLeft.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: canResend ? AppColors.primarySoft : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final active = i == code.length;
                  final filled = i < code.length;
                  return _OtpBox(
                    char: filled ? code[i] : '',
                    active: active && _focusNode.hasFocus,
                  );
                }),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (v) {
                      if (v.length == 6) widget.onVerify();
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 14),
          _ErrorText(widget.error!),
        ],
        const Spacer(),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryForeground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              AuthService.isDemo
                  ? 'Demo mode: use ${AuthService.demoOtp} as verification code'
                  : 'Enter the 6-digit code we sent by SMS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryForeground.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canVerify ? widget.onVerify : null,
            style: _primaryButtonStyle(),
            child: widget.isSubmitting
                ? const _ButtonSpinner()
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String char;
  final bool active;

  const _OtpBox({required this.char, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryForeground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: active
              ? AppColors.primarySoft
              : AppColors.primaryForeground.withValues(alpha: 0.25),
          width: active ? 2 : 1,
        ),
      ),
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryForeground,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.primaryForeground.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFFB4B0)),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryForeground),
    );
  }
}

ButtonStyle _primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.accentForeground,
    disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
    disabledForegroundColor: AppColors.accentForeground.withValues(alpha: 0.8),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
    elevation: 0,
  );
}
