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

  // API base URL for date-specific HTML schedule (tzOffset=360 for GMT+6 as per your previous code)
  final String _baseUrl =
      'https://hianime.to/ajax/schedule/list?tzOffset=360&date=';

  final List<String> _dayOrder = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Set initial selected date index to today (Index 0)
  int _selectedDateIndex = 0;

  // List of dates for the header carousel (Today + next 6 days)
  final List<DateTime> _scheduleDates = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  @override
  void initState() {
    super.initState();
    _fetchScheduleForWeek();
  }

  // --- HTML Extraction Logic (Unchanged) ---
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
      debugPrint('SCHEDULE PARSING ERROR: $e');
      return [];
    }
    return items;
  }

  // --- Logic to fetch schedule for the next 7 days (Unchanged) ---
  Future<void> _fetchScheduleForWeek() async {
    try {
      final Map<String, List<ScheduleItem>> groups = {};

      for (int i = 0; i < 7; i++) {
        final date = _scheduleDates[i];
        final String dayName = _dayOrder[date.weekday - 1];
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        final url = Uri.parse(_baseUrl + formattedDate);

        final response = await http
            .get(
              url,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
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
        }
      }

      if (mounted) {
        setState(() {
          _scheduleData = groups;
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = "Connection Timed Out. Check API status.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error: $e";
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Builders ---

  // REDESIGNED: Date Carousel to match reference image layout
  Widget _buildDateCarousel() {
    return Container(
      height: 70, // Slightly taller for the new look
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _scheduleDates.length,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
              width: 90, // Fixed width for uniform tabs
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                // Use pink/yellow for selected, dark grey for unselected
                color: isSelected
                    ? const Color.fromARGB(255, 255, 230, 7) // Yellow (Theme)
                    : const Color(0xFF2C2C2C), // Dark Grey
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date), // Day (e.g., Fri)
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd').format(date), // Date (e.g., Dec 12)
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.black87 : Colors.white70,
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

  // REDESIGNED: Schedule List Item to match reference image layout
  Widget _buildScheduleItemsList() {
    final DateTime selectedDate = _scheduleDates[_selectedDateIndex];
    final String selectedDayName = _dayOrder[selectedDate.weekday - 1];
    final List<ScheduleItem> items = _scheduleData[selectedDayName] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No schedule available for ${DateFormat('EEEE, MMM d').format(selectedDate)}.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Sort by time
    items.sort((a, b) => a.time.compareTo(b.time));

    return ListView.separated(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF2C2C2C), // Subtle divider color
        height: 1,
        thickness: 1,
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
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time (Left)
                SizedBox(
                  width: 50,
                  child: Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70, // Slightly muted time
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Title (Middle, Bold)
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold, // Bold title as in image
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Episode (Right)
                Text(
                  'Episode ${item.episode}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Removed the previous "Estimated Schedule" header row

        // 1. Date Carousel Header (Redesigned)
        _buildDateCarousel(),

        // 2. Schedule Items List
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
