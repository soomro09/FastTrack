import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/fasting_provider.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'plans_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    PlansScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    _NavItem(icon: Icons.timer_outlined, selectedIcon: Icons.timer_rounded, label: 'Timer'),
    _NavItem(icon: Icons.tune_outlined, selectedIcon: Icons.tune_rounded, label: 'Plans'),
    _NavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart_rounded, label: 'History'),
    _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final fastingState = ref.watch(fastingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        items: _items,
        isFasting: fastingState.isFasting,
        isDark: isDark,
        onSelect: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final bool isFasting;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.isFasting,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset + 8 : 16),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.border(isDark)),
          boxShadow: AppTheme.shadowLg(isDark),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * currentIndex + 8,
                  top: 8,
                  bottom: 8,
                  width: itemWidth - 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(isDark ? 45 : 26),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = index == currentIndex;
                    final showBadge = index == 0 && isFasting;
                    final color = selected
                        ? AppTheme.primary
                        : AppTheme.textSecondary(isDark);

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        onTap: () => onSelect(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  selected ? item.selectedIcon : item.icon,
                                  color: color,
                                  size: 22,
                                ),
                                if (showBadge)
                                  Positioned(
                                    right: -3,
                                    top: -2,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: AppTheme.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? AppTheme.darkSurface : Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: color,
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
