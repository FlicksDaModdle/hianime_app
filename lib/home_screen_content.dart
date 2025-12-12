import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'models/anime.dart';
import 'screens/detail_screen.dart';
import 'screens/top_airing_screen.dart';
import 'screens/most_popular_screen.dart';
import 'screens/most_favorite_screen.dart';
import 'screens/latest_completed_screen.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  // Changed to public State class so we can access it via GlobalKey
  State<HomeScreenContent> createState() => HomeScreenContentState();
}

// REMOVED UNDERSCORE: This is now public
class HomeScreenContentState extends State<HomeScreenContent>
    with AutomaticKeepAliveClientMixin<HomeScreenContent> {
  // Forces rebuild on tab switch (if not using IndexedStack)
  @override
  bool get wantKeepAlive => false;

  // --- Data Lists ---
  List<Anime> _trendingAnime = [];
  List<Anime> _topAiringAnime = [];
  List<Anime> _mostPopularAnime = [];
  List<Anime> _mostFavoriteAnime = [];
  List<Anime> _latestCompletedAnime = [];
  List<dynamic> _spotlightAnime = [];

  bool _isLoading = true;
  String _errorMessage = '';

  // --- Scroll Controllers ---
  // Vertical Controller (Main Page)
  final ScrollController _mainScrollController = ScrollController();

  // Horizontal Controllers (Rows)
  final ScrollController _trendingController = ScrollController();
  final ScrollController _topAiringController = ScrollController();
  final ScrollController _popularController = ScrollController();
  final ScrollController _favoriteController = ScrollController();
  final ScrollController _completedController = ScrollController();

  // --- Carousel State ---
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final String _baseApiUrl = 'https://hianime-api-ufh9.onrender.com/api/v1';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    fetchHomeData().then((_) {
      if (_spotlightAnime.isNotEmpty) {
        _startAutoAdvance();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();

    // Dispose all controllers
    _mainScrollController.dispose();
    _trendingController.dispose();
    _topAiringController.dispose();
    _popularController.dispose();
    _favoriteController.dispose();
    _completedController.dispose();

    super.dispose();
  }

  // --- PUBLIC METHOD: Call this from your BottomNavigationBar ---
  void resetScrollPositions() {
    // 1. Reset Main Vertical Scroll
    if (_mainScrollController.hasClients) {
      _mainScrollController.jumpTo(0);
    }

    // 2. Reset All Horizontal Rows
    if (_trendingController.hasClients) _trendingController.jumpTo(0);
    if (_topAiringController.hasClients) _topAiringController.jumpTo(0);
    if (_popularController.hasClients) _popularController.jumpTo(0);
    if (_favoriteController.hasClients) _favoriteController.jumpTo(0);
    if (_completedController.hasClients) _completedController.jumpTo(0);
  }

  // --- Universal Navigation Helper ---
  Future<void> _navigateAndReset(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen));
    // Auto-reset when returning from details
    resetScrollPositions();
  }

  void _startAutoAdvance() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (Timer timer) {
      if (!_pageController.hasClients) return;
      int nextPage = (_currentPage + 1);
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
  }

  // --- API Fetch Logic ---
  Future<void> fetchHomeData() async {
    final url = Uri.parse('$_baseApiUrl/home');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          final data = fullResponse['data'];

          if (mounted) {
            setState(() {
              _spotlightAnime = data['spotlight'] ?? [];
              _trendingAnime =
                  (data['trending'] as List?)
                      ?.map((json) => Anime.fromJson(json))
                      .toList() ??
                  [];
              _topAiringAnime =
                  (data['topAiring'] as List?)
                      ?.map((json) => Anime.fromJson(json))
                      .toList() ??
                  [];
              _mostPopularAnime =
                  (data['mostPopular'] as List?)
                      ?.map((json) => Anime.fromJson(json))
                      .toList() ??
                  [];
              _mostFavoriteAnime =
                  (data['mostFavorite'] as List?)
                      ?.map((json) => Anime.fromJson(json))
                      .toList() ??
                  [];
              _latestCompletedAnime =
                  (data['latestCompleted'] as List?)
                      ?.map((json) => Anime.fromJson(json))
                      .toList() ??
                  [];
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Server Error: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Connection Failed: $e";
          _isLoading = false;
        });
      }
    }
  }

  // --- 1. Spotlight Section ---
  Widget _buildSpotlightCarousel() {
    if (_spotlightAnime.isEmpty) return const SizedBox(height: 10);
    final int infiniteCount = _spotlightAnime.length * 10000;

    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: infiniteCount,
        itemBuilder: (context, index) {
          final actualIndex = index % _spotlightAnime.length;
          return _buildSpotlightCard(_spotlightAnime[actualIndex]);
        },
      ),
    );
  }

  Widget _buildSpotlightCard(dynamic item) {
    final String title = item['title'] ?? 'N/A';
    final String poster = item['poster'] ?? '';
    final String synopsis = item['synopsis'] ?? 'No synopsis available.';
    final String id = item['id'] ?? '';
    final String rank = item['rank']?.toString() ?? 'N/A';
    final String type = item['type'] ?? 'N/A';
    final String duration = item['duration'] ?? 'N/A';
    final String backgroundImage = poster.replaceAll('1366x768', '1366x768');

    return GestureDetector(
      onTap: () =>
          _navigateAndReset(DetailScreen(animeId: id, animeTitle: title)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: CachedNetworkImageProvider(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.0),
                  ],
                  stops: const [0.0, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(flex: 1),
                  Flexible(
                    flex: 5,
                    child: Text(
                      title,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$rank Spotlight',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      _buildMetadataChip(type, Icons.tv, Colors.blueGrey),
                      _buildMetadataChip(
                        duration,
                        Icons.timer,
                        Colors.blueGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    flex: 2,
                    child: Text(
                      synopsis,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Shared Widgets for Lists ---

  Widget _buildAnimeCard(Anime anime, {int? forcedRank}) {
    final displayRank = forcedRank ?? anime.rank;
    return GestureDetector(
      onTap: () => _navigateAndReset(
        DetailScreen(animeId: anime.id, animeTitle: anime.title),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 155,
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: anime.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[900]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                if (displayRank != null)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "#$displayRank",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMoreButton(String sectionTitle) {
    return GestureDetector(
      onTap: () {
        Widget? screen;

        if (sectionTitle == 'Top Airing') {
          screen = const TopAiringScreen();
        } else if (sectionTitle == 'Most Popular') {
          screen = const MostPopularScreen();
        } else if (sectionTitle == 'Most Favorite') {
          screen = const MostFavoriteScreen();
        } else if (sectionTitle == 'Recently Completed') {
          screen = const LatestCompletedScreen();
        }

        if (screen != null) {
          _navigateAndReset(screen);
        }
      },
      child: Column(
        children: [
          Container(
            height: 155,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_ios, color: Colors.yellow, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'View More',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text("", style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(
    String title,
    List<Anime> animeList,
    ScrollController controller,
  ) {
    final int animeCount = animeList.length > 5 ? 5 : animeList.length;
    final int itemCount = animeList.isEmpty ? 0 : animeCount + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 20.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12.0),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == animeCount) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 110,
                    child: _buildViewMoreButton(title),
                  ),
                );
              }

              final anime = animeList[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  width: 110,
                  child: _buildAnimeCard(anime, forcedRank: index + 1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // Pass the _mainScrollController to the vertical list
    return ListView(
      controller: _mainScrollController,
      children: [
        _buildSpotlightCarousel(),

        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 10.0, bottom: 8.0),
          child: Text(
            'Trending Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            controller: _trendingController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12.0),
            itemCount: _trendingAnime.length,
            itemBuilder: (context, index) {
              final anime = _trendingAnime[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(width: 110, child: _buildAnimeCard(anime)),
              );
            },
          ),
        ),

        _buildHorizontalSection(
          "Top Airing",
          _topAiringAnime,
          _topAiringController,
        ),
        _buildHorizontalSection(
          "Most Popular",
          _mostPopularAnime,
          _popularController,
        ),
        _buildHorizontalSection(
          "Most Favorite",
          _mostFavoriteAnime,
          _favoriteController,
        ),
        _buildHorizontalSection(
          "Recently Completed",
          _latestCompletedAnime,
          _completedController,
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}
