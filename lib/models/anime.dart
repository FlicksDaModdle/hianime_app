class Anime {
  final String id;
  final String title;
  final String image;
  final String? rank;

  Anime({
    required this.id,
    required this.title,
    required this.image,
    this.rank,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown',
      image: json['poster'] ?? '', // Uses 'poster' key from the API response
      rank: json['rank']?.toString(),
    );
  }
}
