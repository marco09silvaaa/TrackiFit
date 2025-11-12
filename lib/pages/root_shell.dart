import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'workouts/workouts_page.dart';
import 'stats_page.dart';
import 'profile_page.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    WorkoutsPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          _pages[_selectedIndex],

          // --- FLOATING NAVBAR ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 58, // 🔹 barra mais pequena
                    width: MediaQuery.of(context).size.width * 0.82,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4), // 🔹 ligeiramente mais alto
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildIcon(
                              CupertinoIcons.house,
                              CupertinoIcons.house_fill,
                              0,
                              'Home',
                            ),
                            _buildIcon(
                              Icons.fitness_center_outlined,
                              Icons.fitness_center,
                              1,
                              'Workouts',
                            ),
                            _buildIcon(
                              CupertinoIcons.chart_bar,
                              CupertinoIcons.chart_bar_fill,
                              2,
                              'Stats',
                            ),
                            _buildIcon(
                              CupertinoIcons.person,
                              CupertinoIcons.person_fill,
                              3,
                              'Profile',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(
    IconData icon,
    IconData activeIcon,
    int index,
    String label,
  ) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 24, // 🔹 ligeiramente menor
            color: isActive
                ? CupertinoColors.activeBlue
                : CupertinoColors.inactiveGray,
          ),
          const SizedBox(height: 1),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: isActive
                ? Text(
                    label,
                    key: ValueKey(label),
                    style: TextStyle(
                      fontSize: 10.5, // 🔹 texto um pouco mais pequeno
                      color: CupertinoColors.activeBlue,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
