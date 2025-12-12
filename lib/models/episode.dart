class Episode {
  final String id;
  final String title;
  final String alternativeTitle;
  final int episodeNumber;
  final bool isFiller;

  Episode({
    required this.id,
    required this.title,
    required this.alternativeTitle,
    required this.episodeNumber,
    required this.isFiller,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Episode ${json['episodeNumber']}',
      alternativeTitle: json['alternativeTitle']?.toString() ?? '',
      // Safe parsing: Handles if API sends 1 (int) or "1" (String)
      episodeNumber: int.tryParse(json['episodeNumber'].toString()) ?? 0,
      isFiller: json['isFiller'] ?? false,
    );
  }
}
