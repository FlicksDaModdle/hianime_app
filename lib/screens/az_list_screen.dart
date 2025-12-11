import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../models/anime.dart';
import 'detail_screen.dart';

const List<String> categories = [
  'All',
  '#',
  '0-9',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'p',
  'q',
  'r',
  's',
  't',
  'u',
  'v',
  'w',
  'x',
  'y',
  'z',
];

class AZListScreen extends StatefulWidget {
  const AZListScreen({super.key});

  @override
  State<AZListScreen> createState() => _AZListScreenState();
}

class _AZListScreenState extends State<AZListScreen>
    with AutomaticKeepAliveClientMixin<AZListScreen> {
  @override
  bool get wantKeepAlive => true;

  String _selectedCategory = '#';
  int _currentPage = 1;
  List<Anime> _animeList = [];
  bool _isLoading = true;
  bool _hasNextPage = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAnimeList(reset: true);
  }

  // --- API Fetch Logic ---
  Future<void> _fetchAnimeList({bool reset = false}) async {
    if (reset) {
      _errorMessage = '';

      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _animeList = [];
      });
    } else {
      if (_isLoading || !_hasNextPage) return;
      setState(() {
        _isLoading = true;
      });
    }

    // Mapping logic for API
    String apiCategory;
    if (_selectedCategory == 'All') {
      apiCategory = 'all';
    } else if (_selectedCategory == '#') {
      apiCategory = '0-9';
    } else {
      apiCategory = _selectedCategory.toLowerCase();
    }

    // API Endpoint: /api/v1/animes/az-list/{category}?page={page}
    final url = Uri.http(
      'hianime-api-ufh9.onrender.com',
      '/api/v1/animes/az-list/$apiCategory',
      {'page': _currentPage.toString()},
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          final List newList = fullResponse['data']['response'];
          final pageInfo = fullResponse['data']['pageInfo'];

          setState(() {
            _animeList = newList.map((json) => Anime.fromJson(json)).toList();
            _hasNextPage = pageInfo['hasNextPage'] ?? false;
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
        _errorMessage = "Connection Failed. Is the API running?\nError: $e";
        _isLoading = false;
      });
    }
  }

  // --- Pagination Control Methods (Unchanged) ---
  void _changePage(int change) {
    if (_isLoading) return;

    final newPage = _currentPage + change;

    if (newPage >= 1 && (change < 0 || _hasNextPage)) {
      setState(() {
        _currentPage = newPage;
      });
      _fetchAnimeList(reset: false);
    }
  }

  // Builder for the horizontal category tabs
  Widget _buildCategoryTabs() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      color: const Color(0xFF111111),
      child: ListView.builder(
        controller: ScrollController(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          final displayText = (category.length == 1 && category != '#')
              ? category.toUpperCase()
              : category;

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 8.0 : 4.0, right: 4.0),
            child: ActionChip(
              label: Text(displayText),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              backgroundColor: isSelected
                  ? Colors.yellow
                  : const Color(0xFF333333),
              onPressed: () {
                if (!isSelected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  _fetchAnimeList(reset: true);
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Card builder
  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        // FIX: Use Navigator.of(context).push to target the nested Navigator
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: anime.image,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[900]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // UI Structure: Tabs -> Grid -> Pagination Controls
    return Column(
      children: [
        _buildCategoryTabs(),
        Expanded(
          child: _isLoading && _animeList.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.yellow),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _animeList.length,
                  itemBuilder: (context, index) {
                    final anime = _animeList[index];
                    return _buildAnimeCard(anime);
                  },
                ),
        ),
        _buildPaginationControls(), // Bottom Pagination Bar
      ],
    );
  }

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
}
