import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final pages = [
      _OnbPage(NexIconType.shield, S.onboardingZeroKnowledgeTitle, S.onboardingZeroKnowledgeDesc),
      _OnbPage(NexIconType.clipboard, S.onboardingDualClipboardTitle, S.onboardingDualClipboardDesc),
      _OnbPage(NexIconType.cloud, S.onboardingSyncTitle, S.onboardingSyncDesc),
      _OnbPage(NexIconType.lock, S.onboardingSecurityTitle, S.onboardingSecurityDesc),
    ];

    return Scaffold(
      backgroundColor: NexTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => ref.read(onboardingDoneProvider.notifier).state = true,
                child: Text(S.onboardingSkip, style: const TextStyle(color: NexTheme.textMuted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _buildPage(pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(NexTheme.xl, 0, NexTheme.xl, 32),
              child: Row(
                children: [
                  Row(children: List.generate(pages.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? NexTheme.primary : NexTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_page < pages.length - 1) {
                        _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        ref.read(onboardingDoneProvider.notifier).state = true;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: NexTheme.primary,
                        borderRadius: BorderRadius.circular(NexTheme.rMd),
                      ),
                      child: Text(
                        _page < pages.length - 1 ? S.onboardingNext : S.onboardingStart,
                        style: const TextStyle(color: NexTheme.background, fontWeight: FontWeight.w700),
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

  Widget _buildPage(_OnbPage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: NexTheme.primaryDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NexTheme.primary.withOpacity(0.3)),
            ),
            child: Center(child: NexIcon(p.icon, size: 36, color: NexTheme.primary)),
          ),
          const SizedBox(height: 28),
          Text(p.title, style: const TextStyle(
            color: NexTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          Text(p.desc, textAlign: TextAlign.center, style: const TextStyle(
            color: NexTheme.textSecondary, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

class _OnbPage {
  final NexIconType icon;
  final String title, desc;
  const _OnbPage(this.icon, this.title, this.desc);
}
