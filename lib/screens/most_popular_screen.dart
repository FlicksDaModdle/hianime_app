import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../models/anime.dart';
import 'detail_screen.dart';

class MostPopularScreen extends StatefulWidget {
  const MostPopularScreen({super.key});

  @override
  State<MostPopularScreen> createState() => _MostPopularScreenState();
}

class _MostPopularScreenState extends State<MostPopularScreen> {
  // Scroll Controller
  final ScrollController _scrollController = ScrollController();

  // State Variables
  List<Anime> _animeList = [];
  bool _isLoading = true;
  bool _hasNextPage = true;
  int _currentPage = 1;
  String _errorMessage = '';

  // API Base URL
  final String _baseApiUrl = 'https://hianime-api-ufh9.onrender.com/api/v1';

  @override
  void initState() {
    super.initState();
    _fetchTopAiring();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose controller to prevent leaks
    super.dispose();
  }

  // --- API Fetch Logic ---
  Future<void> _fetchTopAiring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse(
        '$_baseApiUrl/animes/most-popular?page=$_currentPage',
      );
      final response = await http.get(url);
      final Map<String, dynamic> fullResponse = json.decode(response.body);

      // 1. Check for "resource not found" (End of list)
      if (fullResponse['success'] == false &&
          fullResponse['message'] == 'resource not found') {
        if (_currentPage > 1) {
          setState(() {
            _currentPage--;
            _hasNextPage = false;
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You have reached the end of the list."),
              ),
            );
          }
        } else {
          setState(() {
            _animeList = [];
            _isLoading = false;
            _hasNextPage = false;
          });
        }
        return;
      }

      // 2. Handle Success
      if (response.statusCode == 200 && fullResponse['success'] == true) {
        final Map<String, dynamic> data = fullResponse['data'];
        final List animeListJson = data['response'] ?? [];

        setState(() {
          _animeList = animeListJson
              .map((json) => Anime.fromJson(json))
              .toList();
          _isLoading = false;
          _hasNextPage = true;
        });
      } else {
        setState(() {
          _errorMessage = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection Failed: $e";
        _isLoading = false;
      });
    }
  }

  // --- Pagination Logic ---
  void _changePage(int change) {
    if (_isLoading) return;

    final newPage = _currentPage + change;

    if (newPage >= 1 && (change < 0 || _hasNextPage)) {
      setState(() {
        _currentPage = newPage;
      });

      // Reset Scroll Position to Top
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      _fetchTopAiring();
    }
  }

  // --- Card Builder ---
  Widget _buildAnimeCard(Anime anime, int index) {
    // Rank calculation: (Current Page - 1) * 20 items per page + index + 1
    final int rank = ((_currentPage - 1) * 20) + index + 1;

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
                    height: double.infinity,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[900]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "#$rank",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Pagination Controls ---
  Widget _buildPaginationControls() {
    final bool isFirstPage = _currentPage == 1;
    final bool isLastPage = !_hasNextPage;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: const Color(0xFF1F1F1F),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: isFirstPage || _isLoading ? null : () => _changePage(-1),
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text('Previous'),
            style: TextButton.styleFrom(
              foregroundColor: isFirstPage || _isLoading
                  ? Colors.grey
                  : Colors.yellow,
            ),
          ),
          Text(
            'Page $_currentPage',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          TextButton.icon(
            onPressed: isLastPage || _isLoading ? null : () => _changePage(1),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: isLastPage || _isLoading
                  ? Colors.grey
                  : Colors.yellow,
            ),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Most Popular',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _isLoading && _animeList.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.yellow,
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController, // Attach controller
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 15,
                              ),
                          itemCount: _animeList.length,
                          itemBuilder: (context, index) {
                            return _buildAnimeCard(_animeList[index], index);
                          },
                        ),
                ),
                _buildPaginationControls(),
              ],
            ),
    );
  }
}
