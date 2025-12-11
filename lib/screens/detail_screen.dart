import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

// Import the new model
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

  @override
  void initState() {
    super.initState();
    fetchAnimeDetails();
  }

  Future<void> fetchAnimeDetails() async {
    // The API Detail Endpoint: /api/v1/anime/{animeId}
    final url = Uri.parse(
      'https://hianime-api-ufh9.onrender.com/api/v1/anime/${widget.animeId}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          setState(() {
            _details = AnimeDetails.fromJson(fullResponse['data']);
            _isLoading = false;
          });
        }
      } else {
        _errorMessage = "Server Error: ${response.statusCode}";
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _errorMessage =
          "Failed to fetch details. Is the API server still running?\nError: $e";
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: Text(widget.animeTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. Poster and Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: details.poster,
                width: 120,
                height: 170,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[900]),
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${details.type}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'Episodes: ${details.episodes['eps'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. Genres
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: details.genres
              .map(
                (genre) => Chip(
                  label: Text(genre, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.yellow.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.yellow),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 20),

        // 3. Synopsis
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
          details.synopsis.trim(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
