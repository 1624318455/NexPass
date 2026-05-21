import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../main.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final pages = _buildPages(S);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(S.onboardingSkip, style: const TextStyle(color: Color(0xFF8B949E))),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _buildPage(pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  // Dots
                  Row(
                    children: List.generate(pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? const Color(0xFF2DD4BF) : const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const Spacer(),
                  // Next / Get Started
                  GestureDetector(
                    onTap: () {
                      if (_page < pages.length - 1) {
                        _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        _finish();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2DD4BF), Color(0xFF0EA5E9)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _page < pages.length - 1 ? S.onboardingNext : S.onboardingStart,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finish() {
    ref.read(onboardingDoneProvider.notifier).state = true;
  }

  Widget _buildPage(_OnbPage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(p.title, style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(p.desc, textAlign: TextAlign.center, style: const TextStyle(
            color: Color(0xFF8B949E), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  List<_OnbPage> _buildPages(S) => [
    _OnbPage('\u{1F6E1}', S.onboardingZeroKnowledgeTitle, S.onboardingZeroKnowledgeDesc),
    _OnbPage('\u{1F4CB}', S.onboardingDualClipboardTitle, S.onboardingDualClipboardDesc),
    _OnbPage('\u{2601}\u{FE0F}', S.onboardingSyncTitle, S.onboardingSyncDesc),
    _OnbPage('\u{1F510}', S.onboardingSecurityTitle, S.onboardingSecurityDesc),
  ];
}

class _OnbPage {
  final String emoji, title, desc;
  const _OnbPage(this.emoji, this.title, this.desc);
}
