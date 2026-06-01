import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../feed/feed_screen.dart';
import '../prendas/prendas_screen.dart';
import '../outfits/outfits_screen.dart';
import '../social/feed_social_screen.dart';
import '../perfil/perfil_screen.dart';
import '../../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const PrendasScreen(),
    const OutfitsScreen(),
    const FeedSocialScreen(),
    const PerfilScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined,
        activeIcon: Icons.home, label: 'Inicio'),
    _NavItem(icon: Icons.checkroom_outlined,
        activeIcon: Icons.checkroom, label: 'Armario'),
    _NavItem(icon: Icons.style_outlined,
        activeIcon: Icons.style, label: 'Outfits'),
    _NavItem(icon: Icons.people_outline,
        activeIcon: Icons.people, label: 'Comunidad'),
    _NavItem(icon: Icons.person_outline,
        activeIcon: Icons.person, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
          color: AppTheme.background,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _currentIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: selected
                        ? BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 20,
                          color: selected
                              ? AppTheme.background
                              : AppTheme.textSecondary,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(item.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.background,
                              )),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}