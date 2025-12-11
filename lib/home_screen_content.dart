import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'models/anime.dart';
import 'screens/detail_screen.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with AutomaticKeepAliveClientMixin<HomeScreenContent> {
  @override
  bool get wantKeepAlive => true;

  List<Anime> _trendingAnime = [];
  List<Anime> _topAiringAnime = [];
  List<dynamic> _spotlightAnime = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Controller and Timer for Auto-Advancing Spotlight
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

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
    super.dispose();
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

  // --- API Fetch Logic (Unchanged) ---
  Future<void> fetchHomeData() async {
    final url = Uri.parse('http://10.0.2.2:3030/api/v1/home');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          final List trendingList = fullResponse['data']['trending'];
          final List spotlightList = fullResponse['data']['spotlight'];
          final List topAiringList = fullResponse['data']['topAiring'];

          setState(() {
            _trendingAnime = trendingList
                .map((json) => Anime.fromJson(json))
                .toList();
            _spotlightAnime = spotlightList;
            _topAiringAnime = topAiringList
                .map((json) => Anime.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Connection Failed. Make sure the API server is running!\nError: $e";
        _isLoading = false;
      });
    }
  }
  // -------------------------------------------------------------

  // --- Spotlight Carousel Builder (Correctly Defined) ---
  Widget _buildSpotlightCarousel() {
    if (_spotlightAnime.isEmpty) {
      return const SizedBox(height: 10);
    }

    final int infiniteCount = _spotlightAnime.length * 10000;

    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: infiniteCount,
        itemBuilder: (context, index) {
          final actualIndex = index % _spotlightAnime.length;
          final item = _spotlightAnime[actualIndex];
          return _buildSpotlightCard(item);
        },
      ),
    );
  }

  // Helper function for metadata chips (Unchanged)
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

  // --- Spotlight Card (UNCHANGED LAYOUT/VISUALS) ---
  Widget _buildSpotlightCard(dynamic item) {
    final String title = item['title'] ?? 'N/A';
    final String poster = item['poster'] ?? '';
    final String synopsis = item['synopsis'] ?? 'No synopsis available.';
    final String id = item['id'] ?? '';

    // Extract metadata fields
    final String rank = item['rank']?.toString() ?? 'N/A';
    final String type = item['type'] ?? 'N/A';
    final String aired = item['aired'] ?? 'N/A';
    final String quality = item['quality'] ?? 'N/A';
    final String duration = item['duration'] ?? 'N/A';

    final int subEpisodes = item['episodes']?['sub'] ?? 0;
    final int dubEpisodes = item['episodes']?['dub'] ?? 0;

    final String backgroundImage = poster.replaceAll('1366x768', '1366x768');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailScreen(animeId: id, animeTitle: title),
          ),
        );
      },
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
            // 1. GRADIENT OVERLAY LAYER (Soft Transition)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // 2. CONTENT LAYER (Text)
            Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                top: 16.0,
                right: 0.0,
                bottom: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(flex: 1),

                  // Title Dominance (Flex 5, MaxLines 4)
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
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Metadata Chips Row
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      // Rank Badge
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
                      // Other metadata chips
                      _buildMetadataChip(type, Icons.tv, Colors.blueGrey),
                      _buildMetadataChip(
                        duration,
                        Icons.timer,
                        Colors.blueGrey,
                      ),
                      _buildMetadataChip(
                        aired,
                        Icons.calendar_today,
                        Colors.blueGrey,
                      ),
                      _buildMetadataChip(quality, Icons.hd, Colors.blueGrey),
                      if (subEpisodes > 0)
                        _buildMetadataChip(
                          '$subEpisodes Sub',
                          Icons.closed_caption,
                          Colors.green,
                        ),
                      if (dubEpisodes > 0)
                        _buildMetadataChip(
                          '$dubEpisodes Dub',
                          Icons.mic,
                          Colors.purple,
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Synopsis (MaxLines 2)
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

  // --- Main Build Method (ERROR FIX IS HERE) ---
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

    final int topAiringLimit = _topAiringAnime.length > 5
        ? 5
        : _topAiringAnime.length;

    return ListView(
      children: [
        // FIXED CALL: Ensure this is correctly spelled.
        _buildSpotlightCarousel(),

        // 1. Trending Now Section
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

        // 2. Top Airing Section
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 20.0, bottom: 8.0),
          child: Text(
            'Top Airing',
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
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12.0),
            itemCount: topAiringLimit + (_topAiringAnime.length > 5 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == topAiringLimit && _topAiringAnime.length > 5) {
                return _buildViewMoreButton();
              }

              final anime = _topAiringAnime[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(width: 110, child: _buildAnimeCard(anime)),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- View More Button Widget (Unchanged) ---
  Widget _buildViewMoreButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to the full Top Airing list screen
        print('View More Top Airing pressed');
      },
      child: Container(
        width: 40, // Width for the vertical button container
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: RotatedBox(
            quarterTurns:
                3, // Rotate 270 degrees clockwise (or 90 counter-clockwise)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.yellow,
                ),
                const SizedBox(width: 4),
                Text(
                  'View More',
                  style: TextStyle(
                    color: Colors.yellow.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Trending Card Builder Logic (Unchanged) ---
  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                DetailScreen(animeId: anime.id, animeTitle: anime.title),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: anime.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[900]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                if (anime.rank != null)
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
                        "#${anime.rank}",
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
}
