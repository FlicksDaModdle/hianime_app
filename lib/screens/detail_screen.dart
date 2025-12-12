import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../models/anime_details.dart';

class DetailScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  const DetailScreen({
    super.key,
    required this.animeId,
    required this.animeTitle,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  AnimeDetails? _details;
  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _seasonsScrollController = ScrollController();

  final Color _accentColor = Colors.yellow;
  final Color _greenColor = const Color(0xFFB9FBC0);
  final Color _blueColor = const Color(0xFFBDE0FE);

  // Constants for Season Card Layout
  final double _cardWidth = 160.0;
  final double _cardSpacing = 12.0;

  @override
  void initState() {
    super.initState();
    fetchAnimeDetails();
  }

  @override
  void dispose() {
    _seasonsScrollController.dispose();
    super.dispose();
  }

  Future<void> fetchAnimeDetails() async {
    final url = Uri.parse(
      'https://hianime-api-ufh9.onrender.com/api/v1/anime/${widget.animeId}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          if (mounted) {
            setState(() {
              _details = AnimeDetails.fromJson(fullResponse['data']);
              _isLoading = false;
            });

            // Scroll after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToActiveSeason();
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
          _errorMessage = "Failed to fetch details: $e";
          _isLoading = false;
        });
      }
    }
  }

  // --- Logic to Center the Active Season ---
  void _scrollToActiveSeason() {
    if (_details == null || _details!.moreSeasons.isEmpty) return;

    int activeIndex = _details!.moreSeasons.indexWhere((season) {
      return season['id'] == widget.animeId || (season['isActive'] == true);
    });

    if (activeIndex != -1) {
      // With contentPadding set in the ListView, offset 0 centers the first item.
      // So, to center item N, we simply scroll N * (width + gap).
      double targetOffset = activeIndex * (_cardWidth + _cardSpacing);

      if (_seasonsScrollController.hasClients) {
        _seasonsScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          : _details == null
          ? const Center(
              child: Text(
                "Details not found.",
                style: TextStyle(color: Colors.white),
              ),
            )
          : _buildDetailsBody(_details!),
    );
  }

  Widget _buildDetailsBody(AnimeDetails details) {
    final int sub = details.episodes['sub'] ?? 0;
    final int dub = details.episodes['dub'] ?? 0;

    // Calculate Padding to Center Items
    // (ScreenWidth - CardWidth) / 2 ensures the first and last items sit in the middle.
    final double centeringPadding =
        (MediaQuery.of(context).size.width - _cardWidth) / 2;

    return SingleChildScrollView(
      // Main Vertical Scroll
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // --- 1. Top Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: widget.animeId,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: details.poster,
                      width: 130,
                      height: 190,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.genres.take(3).join(" • "),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. Metadata Badges ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBadge(
                  text: details.rating,
                  color: Colors.white,
                  textColor: Colors.black,
                ),
                const SizedBox(width: 6),
                _buildBadge(
                  text: details.quality,
                  color: _accentColor,
                  textColor: Colors.black,
                ),
                const SizedBox(width: 6),
                if (sub > 0) ...[
                  _buildIconBadge(
                    icon: Icons.closed_caption,
                    text: '$sub',
                    color: _greenColor,
                    textColor: Colors.black,
                  ),
                  const SizedBox(width: 6),
                ],
                if (dub > 0) ...[
                  _buildIconBadge(
                    icon: Icons.mic,
                    text: '$dub',
                    color: _blueColor,
                    textColor: Colors.black,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  "•  ${details.type}  •  ${details.duration}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- 3. Watch Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Play Action
                },
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 26,
                ),
                label: const Text(
                  "Watch now",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 4. Synopsis ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Synopsis",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.synopsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 5. Genre Tags ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: details.genres.map((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    genre,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 30),

          // --- 6. More Seasons Section ---
          if (details.moreSeasons.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "More Seasons",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFBADE),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                controller: _seasonsScrollController,
                scrollDirection: Axis.horizontal,
                // Apply dynamic padding here to allow centering
                padding: EdgeInsets.symmetric(horizontal: centeringPadding),
                itemCount: details.moreSeasons.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: _cardSpacing),
                itemBuilder: (context, index) {
                  final season = details.moreSeasons[index];
                  final String seasonId = season['id'];
                  final String seasonTitle = season['title'];
                  final String displayTitle = season['alternativeTitle'] != ''
                      ? season['alternativeTitle']
                      : season['title'];
                  final String seasonPoster = season['poster'];

                  final bool isActive =
                      season['isActive'] == true || seasonId == widget.animeId;

                  return GestureDetector(
                    onTap: () {
                      if (!isActive) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              animeId: seasonId,
                              animeTitle: seasonTitle,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: _cardWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: isActive
                            ? Border.all(color: _accentColor, width: 2)
                            : Border.all(color: Colors.white10),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(seasonPoster),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.6),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            displayTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive ? _accentColor : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildIconBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
