import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/providers.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../navigation/app_router.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';

/// Branded Overman splash screen featuring the silhouette visual, rotating quote,
/// and automatic transition to HomeScreen after 2.5 seconds.
class SplashScreen extends ConsumerStatefulWidget {
  final Duration delay;
  final QuoteDto? initialQuote;

  const SplashScreen({
    super.key,
    this.delay = const Duration(milliseconds: 2500),
    this.initialQuote,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  QuoteDto? _quote;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _quote = widget.initialQuote;
    _loadQuoteAndStartTimer();
  }

  Future<void> _loadQuoteAndStartTimer() async {
    if (_quote == null) {
      try {
        final quoteService = await ref.read(quoteServiceProvider.future);
        final picked = quoteService.pickQuote();
        if (mounted) {
          setState(() {
            _quote = picked;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _quote = const QuoteDto(
              id: 'fallback',
              text: 'Become who you are.',
              author: 'Friedrich Nietzsche',
              isActive: true,
            );
          });
        }
      }
    }

    _timer = Timer(widget.delay, () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _timer?.cancel();

    try {
      context.go(AppRoutes.home);
    } catch (_) {
      appNavigateTo(context, AppRoutes.home, const HomeScreen());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = (screenWidth * 0.65).clamp(240.0, 300.0);
    final boxHeight = boxWidth * (320.0 / 280.0);

    final displayQuote = _quote ??
        const QuoteDto(
          id: 'fallback',
          text: 'Become who you are.',
          author: 'Friedrich Nietzsche',
          isActive: true,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToHome,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Center Visual: Overman silhouette / muscular back icon_logo
                  Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icon_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to fitness center icon placeholder if image is unavailable
                          return const Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 100,
                              color: AppColors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Quote Text & Attribution
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      children: [
                        Text(
                          '"${displayQuote.text}"',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            fontFamily: AppTheme.fontPrimary,
                            color: AppColors.primaryText.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                        if (displayQuote.author != null &&
                            displayQuote.author!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            '— ${displayQuote.author}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontFamily: AppTheme.fontPrimary,
                              color: AppColors.mutedGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
