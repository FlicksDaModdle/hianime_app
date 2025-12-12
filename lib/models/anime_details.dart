class AnimeDetails {
  final String id;
  final String title;
  final String poster;
  final String synopsis;
  final String type;
  final String rating;
  final String duration;
  final String quality;
  final Map<String, int> episodes;
  final List<String> genres;
  final List<Map<String, dynamic>> moreSeasons;

  AnimeDetails({
    required this.id,
    required this.title,
    required this.poster,
    required this.synopsis,
    required this.type,
    required this.rating,
    required this.duration,
    required this.quality,
    required this.episodes,
    required this.genres,
    required this.moreSeasons,
  });

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    final epMap = json['episodes'] as Map<String, dynamic>?;
    final Map<String, int> parsedEpisodes = {
      'sub': epMap?['sub'] ?? 0,
      'dub': epMap?['dub'] ?? 0,
      'eps': epMap?['eps'] ?? 0,
    };

    final List<String> parsedGenres = (json['genres'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    // Parse More Seasons safely
    List<Map<String, dynamic>> parsedSeasons = [];
    if (json['moreSeasons'] != null && json['moreSeasons'] is List) {
      for (var item in json['moreSeasons']) {
        if (item is Map<String, dynamic>) {
          parsedSeasons.add({
            'id': item['id']?.toString() ?? '',
            'title': item['title']?.toString() ?? 'Unknown',
            // Capture alternative title for shorter names like "Season 1"
            'alternativeTitle': item['alternativeTitle']?.toString() ?? '',
            'poster': item['poster']?.toString() ?? '',
            // Capture active state to highlight the current season
            'isActive': item['isActive'] ?? false,
          });
        }
      }
    }

    return AnimeDetails(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      poster: json['poster']?.toString() ?? '',
      synopsis: json['synopsis']?.toString() ?? 'No synopsis available.',
      type: json['type']?.toString() ?? 'TV',
      rating: json['rating']?.toString() ?? 'N/A',
      duration: json['duration']?.toString() ?? 'N/A',
      quality: json['quality']?.toString() ?? 'HD',
      episodes: parsedEpisodes,
      genres: parsedGenres,
      moreSeasons: parsedSeasons,
    );
  }
}
