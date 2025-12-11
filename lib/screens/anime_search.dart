import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../models/anime.dart';
import 'detail_screen.dart';

class AnimeSearchDelegate extends SearchDelegate<Anime?> {
  Future<List<Anime>> fetchSearchResults(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // FINAL FIX: Using Uri.http with 'keyword' and 'page=1'.
    final url = Uri.http('10.0.2.2:3030', '/api/v1/search', {
      'keyword': query, // CORRECT parameter name found via testing
      'page': '1', // Required page parameter
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          // CORRECTED PARSING: Searching list responses are nested under 'data' then 'response'.
          final List searchList = fullResponse['data']['response'];

          return searchList.map((json) => Anime.fromJson(json)).toList();
        }
        return [];
      } else {
        print(
          'Search Server Error: ${response.statusCode}. Response Body: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Search Connection Failed: $e');
      return [];
    }
  }

  @override
  String get searchFieldLabel => 'Search Anime (e.g., Attack on Titan)';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF111111),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Anime>>(
      future: fetchSearchResults(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellow),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$query".',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final anime = snapshot.data![index];
            return _buildSearchCard(context, anime);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text(
          'Type at least 3 characters to search...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return buildResults(context);
  }

  Widget _buildSearchCard(BuildContext context, Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
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
}
