import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/audio_helper.dart';
import '../services/db_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_bottom_sheet.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'bolao_screen.dart';
import 'quiz_standalone_screen.dart';
import 'my_scratchcards_screen.dart';
import 'wallet_store_screen.dart';
import 'admin_screen.dart';
import 'token_history_screen.dart';
import 'help_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  bool _isAdminPanelActive = true;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  bool _isLoadingRewardedAd = false;

  final SafeAudioPlayer _goalAudioPlayer = SafeAudioPlayer();
  StreamSubscription<QuerySnapshot>? _goalsSubscription;
  final DateTime _sessionStartTime = DateTime.now();
  final Set<String> _processedGoalIds = {};

  @override
  void initState() {
    super.initState();
    _listenToLiveGoals();
    if (!kIsWeb) {
      _loadRewardedAd();
    }
  }

  void _listenToLiveGoals() {
    _goalsSubscription = FirebaseFirestore.instance
        .collection('recent_goals')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (_processedGoalIds.contains(docId)) continue;
          _processedGoalIds.add(docId);

          final data = change.doc.data();
          if (data == null) continue;

          final Timestamp? createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final goalTime = createdAt.toDate();
            // Ignora gols com mais de 20 segundos antes da sessão
            if (goalTime.isBefore(_sessionStartTime.subtract(const Duration(seconds: 20)))) {
              continue;
            }
          }

          final scoringTeam = data['scoringTeam']?.toString() ?? 'GOL!';
          final homeTeam = data['homeTeamName']?.toString() ?? '';
          final awayTeam = data['awayTeamName']?.toString() ?? '';
          final homeScore = data['homeScore'] ?? 0;
          final awayScore = data['awayScore'] ?? 0;

          // ⚽ Toca o som do gol vibrante
          _goalAudioPlayer.play('sounds/goal.wav', volume: 1.0);

          if (!mounted) return;
          final user = ref.read(currentUserProvider);
          final favTeam = (user?.favoriteTeamName ?? '').toLowerCase().trim();
          final isFav = favTeam.isNotEmpty &&
              (scoringTeam.toLowerCase().contains(favTeam) || favTeam.contains(scoringTeam.toLowerCase()));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: isFav ? const Color(0xFF143820) : const Color(0xFF0F291E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isFav ? const Color(0xFFFBBF24) : AppTheme.primaryGreen,
                  width: isFav ? 2 : 1,
                ),
              ),
              duration: const Duration(seconds: 7),
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFav ? const Color(0xFFFBBF24) : AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: isFav ? Colors.black : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFav ? '🔥 GOOOOOOOL DO SEU TIME! 🔥' : '⚽ GOOOOOOOL!',
                          style: TextStyle(
                            color: isFav ? const Color(0xFFFBBF24) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$scoringTeam balançou as redes! ($homeTeam $homeScore x $awayScore $awayTeam)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'RASPAR',
                textColor: const Color(0xFF00E676),
                onPressed: () {
                  setState(() => _currentIndex = 1);
                },
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    _goalAudioPlayer.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadRewardedAd({bool showFeedbackOnLoad = false}) {
    if (kIsWeb || _isLoadingRewardedAd) return;
    setState(() {
      _isLoadingRewardedAd = true;
    });

    RewardedAd.load(
      adUnitId: 'ca-app-pub-9124633416063149/3978038915',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded in layout.');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show rewarded ad: $error');
              ad.dispose();
              _loadRewardedAd();
            },
          );
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isRewardedAdLoaded = true;
              _isLoadingRewardedAd = false;
            });
            if (showFeedbackOnLoad) {
              _showRewardedAd();
            }
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          if (mounted) {
            setState(() {
              _isRewardedAdLoaded = false;
              _isLoadingRewardedAd = false;
            });
            if (showFeedbackOnLoad) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nenhum vídeo premiado disponível no momento. Tente novamente em instantes.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _onRewardedButtonPressed() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vídeos premiados estão disponíveis apenas no aplicativo Android/iOS.'),
        ),
      );
      return;
    }

    if (_rewardedAd != null && _isRewardedAdLoaded) {
      _showRewardedAd();
    } else if (_isLoadingRewardedAd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carregando vídeo premiado... aguarde alguns segundos!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buscando vídeo premiado para você ganhar tokens...'),
          duration: Duration(seconds: 2),
        ),
      );
      _loadRewardedAd(showFeedbackOnLoad: true);
    }
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) return;

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        final user = ref.read(currentUserProvider);
        if (user != null) {
          int amount = reward.amount.toInt();
          if (amount <= 1) amount = 250;

          await DbService().addTokens(user.id, amount);
          await DbService().addTokenTransaction(
            user.id,
            amount,
            'rewarded_ad',
            'Vídeo Premiado',
          );

          ref.read(currentUserProvider.notifier).state = user.copyWith(
            tokens: user.tokens + amount,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 Você ganhou $amount Tokens!'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        }
      },
    );
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin == true;

    void onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    final bool isViewingAdminScreen = isAdmin && _isAdminPanelActive;

    final List<Widget> playerScreens = [
      const HomeScreen(),
      const QuizStandaloneScreen(),
      const BolaoScreen(),
      MyScratchcardsScreen(onExploreGames: () => onTabTapped(0)),
      WalletStoreScreen(onExploreGames: () => onTabTapped(0)),
    ];

    final List<BottomNavigationBarItem> navItems = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.sports_soccer),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.psychology),
        label: 'Quiz',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events),
        label: 'Bolão',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.style),
        label: 'Cartelas',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard),
        label: 'Prêmios',
      ),
    ];

    String getAppBarTitle() {
      if (isViewingAdminScreen) return 'Painel Admin';
      switch (_currentIndex) {
        case 1:
          return 'Quiz por Diversão';
        case 2:
          return 'Bolão do Gol ⚽';
        case 3:
          return 'Minhas Cartelas';
        case 4:
          return 'Loja de Prêmios';
        default:
          return 'Raspadinha do Gol';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        centerTitle: false,
        titleSpacing: 4,
        leadingWidth: 44,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            'assets/logo_transparent.png',
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
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
          if (isAdmin)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: isViewingAdminScreen
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.accentGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () {
                setState(() {
                  _isAdminPanelActive = !_isAdminPanelActive;
                });
              },
              icon: Icon(
                isViewingAdminScreen
                    ? Icons.visibility
                    : Icons.admin_panel_settings,
                size: 16,
                color: isViewingAdminScreen ? Colors.white : Colors.black,
              ),
              label: Text(
                isViewingAdminScreen ? 'Ver App' : 'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isViewingAdminScreen ? Colors.white : Colors.black,
                ),
              ),
            ),
          const SizedBox(width: 4),
          if (user != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!kIsWeb)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _isRewardedAdLoaded
                          ? AppTheme.accentGold.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRewardedAdLoaded
                            ? AppTheme.accentGold
                            : Colors.white38,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: _isLoadingRewardedAd
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentGold,
                              ),
                            )
                          : Icon(
                              Icons.play_circle_fill,
                              color: _isRewardedAdLoaded
                                  ? AppTheme.accentGold
                                  : Colors.white70,
                              size: 20,
                            ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      tooltip: 'Ganhe Tokens Grátis',
                      onPressed: _onRewardedButtonPressed,
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TokenHistoryScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentGold, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: AppTheme.accentGold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${user.tokens}',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white, size: 22),
              tooltip: 'Como funciona?',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
          if (user != null)
            IconButton(
              icon:
                  const Icon(Icons.account_circle, color: Colors.white, size: 26),
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
      ),
      body: isViewingAdminScreen
          ? const AdminScreen()
          : IndexedStack(
              index: _currentIndex >= playerScreens.length ? 0 : _currentIndex,
              children: playerScreens,
            ),
      bottomNavigationBar: isViewingAdminScreen
          ? null
          : BottomNavigationBar(
              currentIndex:
                  (_currentIndex >= navItems.length) ? 0 : _currentIndex,
              onTap: onTabTapped,
              selectedItemColor: AppTheme.primaryGreen,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: navItems,
            ),
    );
  }
}
