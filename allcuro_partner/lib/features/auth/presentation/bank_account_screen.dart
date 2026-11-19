import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/screen_header.dart';
import '../../../core/ui/surface.dart';
import 'onboarding_view_model.dart';

class BankAccountScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const BankAccountScreen({super.key, required this.onBack});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accNumCtrl;
  late final TextEditingController _confirmAccNumCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _holderNameCtrl;
  late final TextEditingController _panCtrl;
  String _accountType = 'Current Account';

  @override
  void initState() {
    super.initState();
    final current = ref.read(partnerOnboardingProvider).bankAccount;
    _bankNameCtrl = TextEditingController(text: current.bankName);
    _accNumCtrl = TextEditingController(text: current.accountNumber);
    _confirmAccNumCtrl = TextEditingController(text: current.accountNumber);
    _ifscCtrl = TextEditingController(text: current.ifscCode);
    _holderNameCtrl = TextEditingController(text: current.accountHolderName);
    _panCtrl = TextEditingController(text: current.panNumber);
    _accountType = current.accountType.isNotEmpty ? current.accountType : 'Current Account';
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _confirmAccNumCtrl.dispose();
    _ifscCtrl.dispose();
    _holderNameCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_accNumCtrl.text.trim() != _confirmAccNumCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account numbers do not match'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final newBank = BankAccountInfo(
      bankName: _bankNameCtrl.text.trim(),
      accountNumber: _accNumCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      accountHolderName: _holderNameCtrl.text.trim(),
      accountType: _accountType,
      panNumber: _panCtrl.text.trim().toUpperCase(),
      // Saved locally; ALLCURO verifies the account during review.
      isVerified: false,
    );

    ref.read(partnerOnboardingProvider.notifier).updateBankAccount(newBank);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bank details saved. ALLCURO will verify them during review.'),
        backgroundColor: AppColors.success,
      ),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Bank & Payout Setup',
              subtitle: 'Direct Razorpay Route settlements to your verified account',
              onBack: widget.onBack,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Surface(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automated Split Settlement',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'All patient booking fees are credited directly via NPCI/IMPS within 24 hours of shift completion.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Account details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CustomFormField(
                      label: 'Account Holder / Entity Name',
                      controller: _holderNameCtrl,
                      hint: 'Exactly as on your bank account',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter account holder name' : null,
                    ),
                    const SizedBox(height: 14),
                    _CustomFormField(
                      label: 'Bank Name',
                      controller: _bankNameCtrl,
                      hint: 'e.g. HDFC Bank, ICICI Bank, SBI',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter bank name' : null,
                    ),
                    const SizedBox(height: 14),
                    _CustomFormField(
                      label: 'Account Number',
                      controller: _accNumCtrl,
                      hint: 'Enter your 9-18 digit account number',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().length < 8) ? 'Enter valid account number' : null,
                    ),
                    const SizedBox(height: 14),
                    _CustomFormField(
                      label: 'Re-Enter Account Number',
                      controller: _confirmAccNumCtrl,
                      hint: 'Re-enter account number for confirmation',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please confirm account number' : null,
                    ),
                    const SizedBox(height: 14),
                    _CustomFormField(
                      label: 'IFSC Code',
                      controller: _ifscCtrl,
                      hint: 'e.g. HDFC0001234',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().length < 8) ? 'Enter valid 11-digit IFSC' : null,
                    ),
                    const SizedBox(height: 14),
                    _CustomFormField(
                      label: 'PAN Card Number (for TDS Exemption)',
                      controller: _panCtrl,
                      hint: 'e.g. ABCDE1234F',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().length < 10) ? 'Enter valid 10-character PAN' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _AccountTypeOption(
                            label: 'Current Account',
                            isSelected: _accountType == 'Current Account',
                            onTap: () => setState(() => _accountType = 'Current Account'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AccountTypeOption(
                            label: 'Savings Account',
                            isSelected: _accountType == 'Savings Account',
                            onTap: () => setState(() => _accountType = 'Savings Account'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.accentForeground,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save & Verify Account',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primarySoft : AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _CustomFormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
