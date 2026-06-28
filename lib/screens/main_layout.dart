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

    final List<Widget> screens = isAdmin 
      ? const [
          HomeScreen(),
          AdminScreen(),
        ]
      : const [
          HomeScreen(),
          QuizStandaloneScreen(),
          WalletStoreScreen(),
          MyScratchcardsScreen(),
        ];

    final List<BottomNavigationBarItem> navItems = isAdmin 
      ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Jogos Ao Vivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ]
      : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Jogos Ao Vivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Quiz Extra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Prêmios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
            label: 'Minhas Rasp.',
          ),
        ];

    void onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    final bool showAppBar = !(isAdmin && _currentIndex == 1);

    return Scaffold(
      appBar: showAppBar ? AppBar(
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
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TokenHistoryScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentGold, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${user.tokens}',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
