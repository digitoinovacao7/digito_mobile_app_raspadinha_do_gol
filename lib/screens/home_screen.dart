import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

import '../core/theme.dart';
import '../models/league_info.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';

import 'wallet_store_screen.dart';
import 'matches_screen.dart';
import 'my_scratchcards_screen.dart';
import 'favorite_team_screen.dart';
import 'active_match_screen.dart';
import '../widgets/smart_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<LeagueInfo> _activeLeagues = [];
  List<dynamic> _featuredMatches = [];
  bool _isLoading = true;

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  // ignore: unused_field
  bool _isNativeAdFailed = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    final service = ref.read(footballServiceProvider);
    _allLeagues = service.getPopularLeagues();
    _loadAdData();
  }

  void _loadAdData() {
    _loadDashboardData();
    if (!kIsWeb) {
      _loadNativeAd();
      _loadRewardedAd();
    }
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
  void dispose() {
    if (!kIsWeb) {
      _nativeAd?.dispose();
      _rewardedAd?.dispose();
    }
    super.dispose();
  }

  List<LeagueInfo> _allLeagues = [];
  Set<int> _activeLeagueIdsToday = {};

  Future<void> _loadDashboardData() async {
    final service = ref.read(footballServiceProvider);

    final popularLeaguesFuture = service.getPopularLeagues();
    final activeLeaguesFuture = service.getActiveLeaguesForToday();
    final featuredMatchesFuture = service.getFeaturedMatchesForToday();

    final popularLeagues = await popularLeaguesFuture;
    final activeLeagues = await activeLeaguesFuture;
    final featuredMatches = await featuredMatchesFuture;

    final activeIds = activeLeagues.map((l) => l.id).toSet();

    if (mounted) {
      setState(() {
        _allLeagues = popularLeagues;
        _activeLeagueIdsToday = activeIds;
        _featuredMatches = featuredMatches;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
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
                  _buildHeroPromoBanner(context),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_featuredMatches.isNotEmpty) ...[
                    _buildSectionTitle('Jogos em Destaque', Icons.sports_soccer),
                    const SizedBox(height: 16),
                    _buildFeaturedMatchesCarousel(),
                    const SizedBox(height: 32),
                  ],
                  if (!_isLoading) ...[
                    _buildSectionTitle('Campeonatos', Icons.emoji_events),
                    const SizedBox(height: 16),
                    _allLeagues.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaguesGrid(),
                    const SizedBox(height: 24),
                  ],
                  if (_isRewardedAdLoaded) ...[
                    _buildRewardedTokensCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_isAdLoaded && _nativeAd != null) ...[
                    _buildNativeAdCard(),
                    const SizedBox(height: 40),
                  ] else ...[
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF004D25),
              Color(0xFF002814),
              Color(0xFF0B1910),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.sports_soccer,
                size: 110,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGold.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            size: 14,
                            color: AppTheme.textDark,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'RASPADINHA DO GOL',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 14,
                            color: AppTheme.accentGold,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Brindes Exclusivos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Acerte o Quiz do Jogo ⚽',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escolha a partida de hoje, responda às perguntas e raspe para ganhar prêmios incríveis, brindes da torcida e cartelas premiadas!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeAdCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 300,
          maxHeight: 330,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AdWidget(ad: _nativeAd!),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteTeamPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FavoriteTeamScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, Color(0xFF0F1F15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escolha seu Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Personalize sua experiência e torça!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardedTokensCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: InkWell(
        onTap: _showRewardedAd,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentGold,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppTheme.accentGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fichas Grátis 🪙',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Assista a um vídeo rápido e ganhe moedas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.accentGold,
                      Color(0xFFFFB700),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle,
                      size: 14,
                      color: AppTheme.textDark,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '+100',
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedMatchesCarousel() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredMatches.length,
        itemBuilder: (context, index) {
          final match = _featuredMatches[index];
          return _buildFeaturedMatchCard(context, match);
        },
      ),
    );
  }

  Widget _buildFeaturedMatchCard(BuildContext context, dynamic match) {
    final homeTeam = match['teams']['home']['name'];
    final awayTeam = match['teams']['away']['name'];
    final homeLogo = match['teams']['home']['logo'];
    final awayLogo = match['teams']['away']['logo'];
    final status = match['fixture']['status']['short'];
    final leagueName = match['league']?['name']?.toString() ?? '';
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
              leagueName: leagueName.isEmpty ? null : leagueName,
              homeLogo: homeLogo?.isNotEmpty == true
                  ? homeLogo!
                  : 'https://media.api-sports.io/football/teams/${match['teams']['home']['id']}.png',
              awayLogo: awayLogo?.isNotEmpty == true
                  ? awayLogo!
                  : 'https://media.api-sports.io/football/teams/${match['teams']['away']['id']}.png',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade100, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 14,
                        color: AppTheme.accentGold,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          leagueName.isEmpty ? 'Campeonato' : leagueName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isLive ? 'AO VIVO' : status,
                        style: TextStyle(
                          color: isLive ? Colors.red : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTeamColumn(
                    homeTeam,
                    homeLogo?.isNotEmpty == true
                        ? homeLogo!
                        : 'https://media.api-sports.io/football/teams/${match['teams']['home']['id']}.png',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isLive
                        ? '${match['goals']['home'] ?? 0} - ${match['goals']['away'] ?? 0}'
                        : status,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isLive ? 24 : 16,
                      color: isLive ? Colors.red : AppTheme.textDark,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTeamColumn(
                    awayTeam,
                    awayLogo?.isNotEmpty == true
                        ? awayLogo!
                        : 'https://media.api-sports.io/football/teams/${match['teams']['away']['id']}.png',
                  ),
                ),
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
        SmartImage(
          logoUrl ?? '',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.shield, color: Colors.grey, size: 48),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaguesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 108,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: _allLeagues.length,
      itemBuilder: (context, index) {
        final league = _allLeagues[index];
        final hasGamesToday = _activeLeagueIdsToday.contains(league.id);
        return _buildLeagueCard(
          context,
          title: league.name,
          id: league.id,
          season: league.season,
          logoUrl: league.logoUrl,
          hasGamesToday: hasGamesToday,
        );
      },
    );
  }

  Widget _buildLeagueCard(
    BuildContext context, {
    required String title,
    required int id,
    int? season,
    String? logoUrl,
    required bool hasGamesToday,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MatchesScreen(leagueId: id, leagueName: title, season: season),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasGamesToday ? AppTheme.primaryGreen : Colors.grey.shade200,
            width: hasGamesToday ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasGamesToday
                  ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  child: SmartImage(
                    (logoUrl != null && logoUrl.isNotEmpty)
                        ? logoUrl
                        : 'https://media.api-sports.io/football/leagues/$id.png',
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports_soccer, color: Colors.grey),
                  ),
                ),
                if (hasGamesToday)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HOJE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 11,
                fontWeight: hasGamesToday ? FontWeight.w900 : FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Nenhum jogo disponível hoje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A API de futebol não encontrou partidas para hoje. Volte mais tarde!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
