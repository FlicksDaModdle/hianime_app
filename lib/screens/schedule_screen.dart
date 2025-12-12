import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;
import 'package:intl/intl.dart';

import 'detail_screen.dart';

// Model definitions
class ScheduleItem {
  final String title;
  final String animeId;
  final String time;
  final String episode;

  ScheduleItem({
    required this.title,
    required this.animeId,
    required this.time,
    required this.episode,
  });
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with AutomaticKeepAliveClientMixin<ScheduleScreen> {
  @override
  bool get wantKeepAlive => true;

  Map<String, List<ScheduleItem>> _scheduleData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // API base URL for date-specific HTML schedule (tzOffset=360)
  final String _baseUrl =
      'https://hianime.to/ajax/schedule/list?tzOffset=360&date=';

  // Define the correct calendar order for sorting
  final List<String> _dayOrder = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Set initial selected date index to December 13th (Saturday), assuming today is Dec 11th (Thursday)
  // Index 0 (Thu 11th), Index 1 (Fri 12th), Index 2 (Sat 13th)
  int _selectedDateIndex = 2;

  // List of dates for the header carousel
  final List<DateTime> _scheduleDates = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  @override
  void initState() {
    super.initState();
    _fetchScheduleForWeek();
  }

  // --- HTML Extraction Logic ---
  List<ScheduleItem> _extractScheduleItems(String htmlContent) {
    final List<ScheduleItem> items = [];

    try {
      final document = parse(htmlContent);
      final List<html.Element> linkElements = document.querySelectorAll(
        'a.tsl-link',
      );

      for (var el in linkElements) {
        final String? href = el.attributes['href'];
        final String id = href?.replaceAll('/', '') ?? '';
        final String time = el.querySelector('.time')?.text.trim() ?? 'N/A';
        final String title =
            el.querySelector('.film-name')?.text.trim() ?? 'N/A';
        final String episodeText =
            el.querySelector('.btn-play')?.text.trim() ?? '';
        final String episode = episodeText.contains('Episode')
            ? episodeText.split('Episode ').last.trim()
            : 'TBA';

        items.add(
          ScheduleItem(title: title, animeId: id, time: time, episode: episode),
        );
      }
    } catch (e) {
      print('SCHEDULE PARSING ERROR: $e');
      return [];
    }
    return items;
  }

  // --- Logic to fetch schedule for the next 7 days (DYNAMIC) ---
  Future<void> _fetchScheduleForWeek() async {
    try {
      final Map<String, List<ScheduleItem>> groups = {};

      for (int i = 0; i < 7; i++) {
        final date = _scheduleDates[i];
        final String dayName = _dayOrder[date.weekday - 1];

        final formattedDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final url = Uri.parse(_baseUrl + formattedDate);

        // Use Headers and Timeout for robustness
        final response = await http
            .get(
              url,
              headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp/1.0)',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          final String? htmlContent = jsonResponse['html'];

          if (htmlContent != null && htmlContent.trim().isNotEmpty) {
            final List<ScheduleItem> items = _extractScheduleItems(htmlContent);

            if (items.isNotEmpty) {
              groups[dayName] = items;
            }
          }
        } else {
          print('HTTP ERROR for $dayName: ${response.statusCode}');
        }
      }

      // Final success state update
      setState(() {
        _scheduleData = groups;
        _errorMessage = '';
      });
    } on TimeoutException {
      setState(() {
        _errorMessage =
            "Connection Timed Out after 15 seconds. Check API status.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Network or Decoding Error: $e";
      });
    } finally {
      // ENSURE LOADING STATE IS ALWAYS FALSE
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Builders ---

  Widget _buildDateCarousel() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _scheduleDates.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final date = _scheduleDates[index];
          final isSelected = index == _selectedDateIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF962A8)
                    : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date), // Day (Thu, Fri)
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd').format(date), // Date (Dec 11)
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleItemsList() {
    final DateTime selectedDate = _scheduleDates[_selectedDateIndex];
    final String selectedDayName = _dayOrder[selectedDate.weekday - 1];
    final List<ScheduleItem> items = _scheduleData[selectedDayName] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No schedule items found for $selectedDayName.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Sort by time string (e.g., '07:00' before '10:30')
    items.sort((a, b) => a.time.compareTo(b.time));

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF1F1F1F),
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    DetailScreen(animeId: item.animeId, animeTitle: item.title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Time (Left Clumped)
                SizedBox(
                  width: 60,
                  child: Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Title (Expanded)
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),

                // Episode Number (Right Clumped)
                Text(
                  'Episode ${item.episode}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),

                const SizedBox(width: 8),

                // Play Icon
                const Icon(Icons.play_arrow, size: 16, color: Colors.white54),
              ],
            ),
          ),
        );
      },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Bar: Title and Time (GMT)
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF962A8), // Pink color
                ),
              ),
              Text(
                // Display current GMT time based on the fixed offset
                'GMT+06:00 ${DateFormat('MM/dd/yyyy HH:mm:ss a').format(DateTime.now().toLocal())}',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ),

        // 2. Date Carousel Header
        _buildDateCarousel(),

        const SizedBox(height: 12),

        // 3. Schedule Items List (Loading spinner handled by Expanded)
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.yellow),
                )
              : _buildScheduleItemsList(),
        ),
      ],
    );
  }
}
