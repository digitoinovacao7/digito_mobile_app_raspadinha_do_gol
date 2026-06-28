import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme.dart';
import '../models/league_info.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import 'matches_screen.dart';
import 'active_match_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../services/db_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<LeagueInfo> _activeLeagues = [];
  List<dynamic> _featuredMatches = [];
  bool _isLoading = true;
  Map<String, dynamic>? _featuredPrize;

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isNativeAdFailed = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  void _loadAdData() {
    _loadDashboardData();
    if (!kIsWeb) {
      _loadNativeAd();
      _loadRewardedAd();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdData();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-9124633416063149/3728390385',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded.');
          if (mounted) {
            setState(() {
              _nativeAd = ad as NativeAd;
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          if (mounted) {
            setState(() {
              _isNativeAdFailed = true;
            });
          }
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: AppTheme.primaryGreen,
        cornerRadius: 24.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppTheme.textDark,
          backgroundColor: AppTheme.accentGold,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
        ),
      ),
    )..load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-9124633416063149/3978038915',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded.');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd(); // Load another ad for the next time
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show rewarded ad: $error');
              ad.dispose();
              _loadRewardedAd(); // Load another ad for the next time
            },
          );
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isRewardedAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          if (mounted) {
            setState(() {
              _isRewardedAdLoaded = false;
            });
          }
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) return;
    
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        final user = ref.read(currentUserProvider);
        if (user != null) {
          int amount = reward.amount.toInt();
          // Fallback if ad is configured as 1 instead of 100/250.
          if (amount <= 1) amount = 250; 
          
          await DbService().addTokens(user.id, amount);
          await DbService().addTokenTransaction(user.id, amount, 'rewarded_ad', 'Vídeo Premiado');
          
          ref.read(currentUserProvider.notifier).state = user.copyWith(tokens: user.tokens + amount);
          
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
  void dispose() {
    if (!kIsWeb) {
      _nativeAd?.dispose();
      _rewardedAd?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final service = ref.read(footballServiceProvider);
    
    // Load Leagues and Featured Matches in parallel
    final results = await Future.wait([
      service.getActiveLeaguesForToday(),
      service.getFeaturedMatchesForToday(),
    ]);

    List<LeagueInfo> leagues = results[0] as List<LeagueInfo>;
    List<dynamic> featuredMatches = results[1] as List<dynamic>;
    
    try {
      final prizesSnap = await FirebaseFirestore.instance
          .collection('prizes')
          .where('active', isEqualTo: true)
          .get();

      if (prizesSnap.docs.isNotEmpty) {
        _featuredPrize = prizesSnap.docs.first.data();
      } else {
        _featuredPrize = null;
      }
    } catch (e) {
      print('[HomeScreen] Erro ao carregar prêmios: $e');
    }

    if (mounted) {
      setState(() {
        _activeLeagues = leagues;
        _featuredMatches = featuredMatches;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          await _loadDashboardData();
        },
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Hero CTA Banner / Native Ad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isAdLoaded && _nativeAd != null
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 320,
                          maxHeight: 350,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AdWidget(ad: _nativeAd!),
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen, Colors.green.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(12)),
                                    child: Text(
                                      _featuredPrize != null 
                                          ? (_featuredPrize!['type'] == 'pix' ? 'SAQUE PIX 💸' : 'PRÊMIO FÍSICO 🎁')
                                          : 'RASPADINHA GRÁTIS 🎟️',
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _featuredPrize != null 
                                      ? 'Raspe e ganhe\n${_featuredPrize!['name']}'
                                      : 'Assista aos jogos e ganhe raspadinhas!',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Como funciona?'),
                                          content: const Text(
                                            'Acompanhe os Jogos ao Vivo pelo aplicativo. Toda vez que rolar um evento importante na partida (como um Gol ou Fim de Jogo), você ganha uma chance GRATUITA de raspar a cartela e concorrer aos prêmios na hora!'
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))
                                          ],
                                        )
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryGreen,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                                    ),
                                    child: const Text('Como jogar?', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(_featuredPrize?['type'] == 'pix' ? Icons.pix : Icons.sports_soccer, size: 70, color: Colors.white.withOpacity(0.9)),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 16),
              
              // Rewarded Ad CTA
              if (_isRewardedAdLoaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: _showRewardedAd,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accentGold.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_fill, color: Colors.black, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Ganhe Tokens Grátis! 🎬',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Featured Matches Carousel
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
              else if (_featuredMatches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Jogos em Destaque',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _featuredMatches.length,
                    itemBuilder: (context, index) {
                      final match = _featuredMatches[index];
                      return _buildFeaturedMatchCard(context, match);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Active Leagues List
              if (!_isLoading) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Explorar Campeonatos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _activeLeagues.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _activeLeagues.length,
                        itemBuilder: (context, index) {
                          final league = _activeLeagues[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildLeagueCard(
                              context,
                              title: league.name,
                              id: league.id,
                              season: league.season,
                              logoUrl: league.logoUrl,
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 40),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedMatchCard(BuildContext context, dynamic match) {
    final homeTeam = match['teams']['home']['name'];
    final awayTeam = match['teams']['away']['name'];
    final homeLogo = match['teams']['home']['logo'];
    final awayLogo = match['teams']['away']['logo'];
    final homeScore = match['goals']['home'];
    final awayScore = match['goals']['away'];
    final status = match['fixture']['status']['short'];
    final isLive = ['1H', '2H', 'HT', 'ET', 'P'].contains(status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveMatchScreen(
              fixtureId: match['fixture']['id'],
              homeTeam: homeTeam,
              awayTeam: awayTeam,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isLive ? 'AO VIVO' : status,
                        style: TextStyle(
                          color: isLive ? Colors.red : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTeamColumn(homeTeam, homeLogo),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$homeScore - $awayScore',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
                _buildTeamColumn(awayTeam, awayLogo),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(String name, String? logoUrl) {
    return Column(
      children: [
        if (logoUrl != null)
          Image.network(logoUrl, width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.shield, color: Colors.grey, size: 40))
        else
          const Icon(Icons.shield, color: Colors.grey, size: 40),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueCard(BuildContext context, {required String title, required int id, int? season, String? logoUrl}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchesScreen(leagueId: id, leagueName: title, season: season)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (logoUrl != null)
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                padding: const EdgeInsets.all(8),
                child: Image.network(logoUrl, errorBuilder: (c,e,s) => const Icon(Icons.sports_soccer, color: Colors.grey)),
              )
            else
              const Icon(Icons.sports_soccer, color: Colors.grey, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text('Ver todos os jogos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Nenhum jogo disponível hoje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A API de futebol não encontrou partidas para hoje. Isso pode acontecer fora do período de temporada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
