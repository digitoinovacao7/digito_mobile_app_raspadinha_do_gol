import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_bottom_sheet.dart';
import '../core/theme.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'my_scratchcards_screen.dart';
import 'admin_screen.dart';
import 'wallet_store_screen.dart';
import 'quiz_standalone_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    QuizStandaloneScreen(),
    WalletStoreScreen(),
    MyScratchcardsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin == true;

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.sports_soccer),
        label: 'Jogos Ao Vivo',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.psychology),
        label: 'Quiz Extra',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard),
        label: 'Prêmios',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Histórico',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Configurações',
      ),
    ];

    void onTabTapped(int index) {
      final isSettingsIndex = index == navItems.length - 1;
      final isAdminIndex = isAdmin && index == navItems.length - 2;

      if (isSettingsIndex) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      } else if (isAdminIndex) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
        setState(() {
          _currentIndex = index;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ProfileBottomSheet(),
              );
            },
            child: CircleAvatar(
              backgroundColor: AppTheme.textDark,
              child: const Icon(Icons.person, color: AppTheme.accentGold, size: 20),
            ),
          ),
        ),
        title: const Text('Raspadinha do Gol'),
      ),
      body: IndexedStack(
        index: _currentIndex >= _screens.length ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: (_currentIndex >= navItems.length - 1) ? 0 : _currentIndex, 
        onTap: onTabTapped,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
