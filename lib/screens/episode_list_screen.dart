import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/episode.dart';
// import 'player_screen.dart'; // REMOVED: Player screen is not ready

class EpisodeListScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  const EpisodeListScreen({
    super.key,
    required this.animeId,
    required this.animeTitle,
  });

  @override
  State<EpisodeListScreen> createState() => _EpisodeListScreenState();
}

class _EpisodeListScreenState extends State<EpisodeListScreen>
    with SingleTickerProviderStateMixin {
  List<Episode> _allEpisodes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // TabController for pagination (1-100, 101-200, etc.)
  TabController? _tabController;
  final int _chunkSize = 100; // Episodes per tab

  // Theme Colors
  final Color _accentColor = Colors.yellow;
  final Color _darkBackground = const Color(0xFF111111);
  final Color _cardColor = const Color(0xFF1F1F1F);
  final Color _fillerColor = const Color(0xFFFFA726); // Orange for filler

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // --- Fetch Episode List ---
  Future<void> _fetchEpisodes() async {
    final url = Uri.parse(
      'https://hianime-api-ufh9.onrender.com/api/v1/episodes/${widget.animeId}',
    );

    try {
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> fullResponse = json.decode(response.body);

        if (fullResponse['success'] == true && fullResponse['data'] != null) {
          // Handle dynamic data structure (List vs Map)
          final dynamic data = fullResponse['data'];
          List<dynamic> rawList = [];

          if (data is List) {
            rawList = data;
          } else if (data is Map && data.containsKey('episodes')) {
            rawList = data['episodes'] as List;
          }

          setState(() {
            _allEpisodes = rawList.map((e) => Episode.fromJson(e)).toList();
            _isLoading = false;

            if (_allEpisodes.length > 50) {
              int tabCount = (_allEpisodes.length / _chunkSize).ceil();
              _tabController = TabController(length: tabCount, vsync: this);
            }
          });
        } else {
          setState(() {
            _errorMessage = "No episodes found.";
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
      if (mounted) {
        setState(() {
          _errorMessage = "Connection Failed: $e";
          _isLoading = false;
        });
      }
    }
  }

  // --- OPEN PLAYER PLACEHOLDER ---
  void _openPlayer(BuildContext context, Episode episode) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Video playback is currently disabled."),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 1),
      ),
    );
    // When you resume, insert navigation logic here.
  }

  // --- UI Structure ---
  @override
  Widget build(BuildContext context) {
    bool useTabs = _allEpisodes.length > 50 && _tabController != null;

    return Scaffold(
      backgroundColor: _darkBackground,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.animeTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 10),

                // Pagination Tabs (Only if > 50 eps)
                if (useTabs) _buildTabBar(),

                // List Content
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: _accentColor,
        labelColor: Colors.yellow,
        unselectedLabelColor: Colors.white54,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: List.generate(_tabController!.length, (index) {
          int start = (index * _chunkSize) + 1;
          int end = ((index + 1) * _chunkSize);
          if (end > _allEpisodes.length) end = _allEpisodes.length;
          return Tab(text: "$start-$end");
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_allEpisodes.isEmpty) return const SizedBox();

    if (_allEpisodes.length <= 50) {
      return _buildSimpleListView(_allEpisodes);
    }

    return TabBarView(
      controller: _tabController,
      children: List.generate(_tabController!.length, (index) {
        int start = index * _chunkSize;
        int end = (index + 1) * _chunkSize;
        if (end > _allEpisodes.length) end = _allEpisodes.length;

        final chunk = _allEpisodes.sublist(start, end);
        return _buildGridView(chunk);
      }),
    );
  }

  // --- Layout A: Simple List View ---
  Widget _buildSimpleListView(List<Episode> episodes) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: episodes.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(8),
            border: ep.isFiller
                ? Border.all(color: _fillerColor.withOpacity(0.5))
                : Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Text(
              "${ep.episodeNumber}",
              style: TextStyle(
                color: ep.isFiller ? _fillerColor : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            title: Text(
              ep.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: ep.isFiller
                ? Text(
                    "Filler",
                    style: TextStyle(color: _fillerColor, fontSize: 12),
                  )
                : null,
            trailing: const Icon(
              Icons.play_circle_outline,
              color: Colors.white54,
            ),
            onTap: () => _openPlayer(context, ep), // Call placeholder function
          ),
        );
      },
    );
  }

  // --- Layout B: Grid View ---
  Widget _buildGridView(List<Episode> chunk) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: chunk.length,
      itemBuilder: (context, index) {
        final ep = chunk[index];
        return GestureDetector(
          onTap: () => _openPlayer(context, ep), // Call placeholder function
          child: Container(
            decoration: BoxDecoration(
              color: ep.isFiller
                  ? _fillerColor.withOpacity(0.2)
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: ep.isFiller
                  ? Border.all(color: _fillerColor)
                  : Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${ep.episodeNumber}",
                  style: TextStyle(
                    color: ep.isFiller ? _fillerColor : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (ep.isFiller)
                  Text(
                    "Filler",
                    style: TextStyle(color: _fillerColor, fontSize: 9),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
