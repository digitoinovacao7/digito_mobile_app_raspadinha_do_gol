import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_bottom_sheet.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'wallet_store_screen.dart';
import 'quiz_standalone_screen.dart';
import 'my_scratchcards_screen.dart';
import 'admin_screen.dart';
import 'token_history_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin == true;

    void onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    final List<Widget> screens = isAdmin
        ? const [HomeScreen(), AdminScreen()]
        : [
            const HomeScreen(),
            const QuizStandaloneScreen(),
            WalletStoreScreen(onExploreGames: () => onTabTapped(0)),
            MyScratchcardsScreen(onExploreGames: () => onTabTapped(0)),
          ];

    final List<BottomNavigationBarItem> navItems = isAdmin 
      ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Jogos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ]
      : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Jogos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Prêmios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: 'Cartelas',
          ),
        ];

    String getAppBarTitle() {
      if (isAdmin) {
        if (_currentIndex == 1) return 'Painel Admin';
        return 'Raspadinha do Gol';
      }
      switch (_currentIndex) {
        case 1: return 'Quiz por Diversão';
        case 2: return 'Loja de Prêmios';
        case 3: return 'Minhas Cartelas';
        default: return 'Raspadinha do Gol';
      }
    }

    final bool showAppBar = true; // Always show AppBar since it has the unified layout

    return Scaffold(
      appBar: showAppBar ? AppBar(
        backgroundColor: AppTheme.primaryGreen,
        centerTitle: false,
        titleSpacing: 4,
        leadingWidth: 44,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/logo_transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
          ),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            getAppBarTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
          if (user != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TokenHistoryScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentGold, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      '${user.tokens}',
                      style: const TextStyle(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white, size: 26),
              tooltip: 'Perfil (${user.name.split(' ').first})',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ProfileBottomSheet(),
                );
              },
            ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex >= screens.length ? 0 : _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: (_currentIndex >= navItems.length) ? 0 : _currentIndex, 
        onTap: onTabTapped,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
