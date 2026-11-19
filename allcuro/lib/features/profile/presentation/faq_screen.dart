import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/supabase_config.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';

const List<Faq> _faqs = [
  (
    question: 'Can I book a nurse for just 30 minutes?',
    answer:
        'Yes! For procedures like IV injections, wound dressing, or catheterization, you can book a 30-minute or 45-minute quick visit without paying for a full shift.',
  ),
  (
    question: 'How quickly can a clinician reach my home?',
    answer:
        'Our verified clinicians are stationed across primary city sectors. For urgent requirements, an available clinician can reach your doorstep within 45 to 60 minutes.',
  ),
  (
    question: 'Are caregivers different from registered nurses?',
    answer:
        'Yes. Registered nurses hold B.Sc or GNM degrees for clinical procedures, injections, and post-op care. Caregivers assist with daily living activities, mobility, and companionship.',
  ),
  (
    question: 'Can I replace or reschedule if needed?',
    answer:
        'Yes. You can reschedule easily or request clinician replacement through our 24/7 care support desk with zero penalty.',
  ),
];

typedef Faq = ({String question, String answer});

/// FAQs from Supabase `public.faqs` (is_active, sort_order); the bundled list
/// above is used when Supabase isn't configured or returns nothing.
final faqsProvider = FutureProvider<List<Faq>>((ref) async {
  final client = supabaseOrNull;
  if (client == null) return _faqs;
  try {
    final rows = await client.from('faqs').select('question, answer').eq('is_active', true).order('sort_order');
    final live = [
      for (final r in rows) (question: (r['question'] ?? '').toString(), answer: (r['answer'] ?? '').toString()),
    ];
    return live.isEmpty ? _faqs : live;
  } catch (e) {
    debugPrint('FAQs: using bundled list — $e');
    return _faqs;
  }
});

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      currentPath: '/faq',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Everything you need to know about home health care',
                      style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final faq in ref.watch(faqsProvider).valueOrNull ?? _faqs) ...[
            _FaqTile(question: faq.question, answer: faq.answer),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(
                  widget.answer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
