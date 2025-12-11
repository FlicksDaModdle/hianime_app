class AnimeDetails {
  final String title;
  final String poster;
  final String synopsis;
  final List<String> genres;
  final String type;
  final Map<String, int> episodes;

  AnimeDetails({
    required this.title,
    required this.poster,
    required this.synopsis,
    required this.genres,
    required this.type,
    required this.episodes,
  });

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    // Safely cast genres from List<dynamic> to List<String>
    final List<String> genreList =
        (json['genres'] as List<dynamic>?)?.map((g) => g.toString()).toList() ??
        [];

    // Safely cast episodes Map
    final Map<String, int> episodeMap =
        (json['episodes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            value is int ? value : int.tryParse(value.toString()) ?? 0,
          ),
        ) ??
        {};

    return AnimeDetails(
      title: json['title'] ?? 'N/A',
      poster: json['poster'] ?? '',
      synopsis: json['synopsis'] ?? 'No synopsis available.',
      genres: genreList,
      type: json['type'] ?? 'Unknown',
      episodes: episodeMap,
    );
  }
}
