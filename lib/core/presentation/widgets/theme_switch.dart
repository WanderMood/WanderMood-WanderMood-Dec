import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/models/user_preferences.dart';
import '../../../features/settings/presentation/providers/user_preferences_provider.dart';

class ThemeSwitch extends ConsumerWidget {
  final bool showLabel;
  
  const ThemeSwitch({
    Key? key, 
    this.showLabel = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final isDark = preferences.isDarkMode(context);
    
    return GestureDetector(
      onTap: () => ref.read(userPreferencesProvider.notifier).toggleTheme(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark 
            ? Colors.grey.shade800
            : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sun/Moon Icon with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: isDark 
                ? Icon(
                    Icons.dark_mode,
                    key: const ValueKey('dark'),
                    color: Colors.amber,
                    size: 20,
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 3.seconds, color: Colors.amber.shade200)
                : Icon(
                    Icons.light_mode,
                    key: const ValueKey('light'),
                    color: Colors.orange,
                    size: 20,
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2.seconds, color: Colors.orange.shade300),
            ),
            
            // Optional label
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                isDark ? 'Dark' : 'Light',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ThemeSwitchFloatingButton extends ConsumerWidget {
  final double size;
  
  const ThemeSwitchFloatingButton({
    Key? key, 
    this.size = 56.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);
    final isDark = preferences.isDarkMode(context);
    
    return GestureDetector(
      onTap: () => ref.read(userPreferencesProvider.notifier).toggleTheme(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark 
            ? const Color(0xFF2C2C2C)
            : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
              child: ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              ),
            );
          },
          child: isDark 
            ? Icon(
                Icons.dark_mode_rounded,
                key: const ValueKey('dark_fab'),
                color: Colors.amber,
                size: size * 0.5,
              )
            : Icon(
                Icons.light_mode_rounded,
                key: const ValueKey('light_fab'),
                color: Colors.orange,
                size: size * 0.5,
              ),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).scaleXY(
        begin: 1.0, 
        end: 1.05, 
        duration: 2.seconds,
        curve: Curves.easeInOut,
      ),
    );
  }
} 
 
 
 