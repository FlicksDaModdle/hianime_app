import 'package:flutter/material.dart';

// Import all required components for the app structure
import 'screens/anime_search.dart';
import 'home_screen_content.dart'; // Tab 1 (Center)
import 'screens/az_list_screen.dart'; // Tab 0
import 'screens/genres_screen.dart'; // Tab 3
import 'screens/top_airing_screen.dart'; // Still imported, but not in the tab list
import 'screens/schedule_screen.dart'; // Tab 2

void main() {
  runApp(const HiAnimeApp());
}

class HiAnimeApp extends StatelessWidget {
  const HiAnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiAnime Native',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          selectedItemColor: Colors.yellow,
          unselectedItemColor: Colors.white54,
        ),
      ),
      // Start on the MainNavigator
      home: const MainNavigator(),
    );
  }
}

// --- MAIN WIDGET TO HANDLE BOTTOM NAVIGATION (4 TABS) ---
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // Start the index at 1 (the center position: Home)
  int _selectedIndex = 1;

  // GlobalKey list to manage each tab's navigation state independently (4 tabs total)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // AZ List
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Schedule
    GlobalKey<NavigatorState>(), // Genres
  ];

  // List of initial screen widgets in their new order: [AZ, HOME, Schedule, Genres]
  final List<Widget> _tabScreens = [
    const AZListScreen(), // Index 0
    const HomeScreenContent(), // Index 1 (HOME - CENTER)
    const ScheduleScreen(), // Index 2
    const GenresScreen(), // Index 3
  ];

  void _onItemTapped(int index) {
    // If the same tab is tapped, pop back to the root of that tab's navigation stack
    if (index == _selectedIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // Map tab index to tab titles for the AppBar
  final List<String> _tabTitles = [
    'A-Z List',
    'HiAnime', // Center Tab Title
    'Schedule',
    'Genres',
  ];

  // Helper widget to build the nested Navigator for each tab
  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          // Ensure the initial route uses the correct screen content
          builder: (context) => _tabScreens[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle the physical back button: pop the nested navigator first
      onWillPop: () async {
        final isFirstRouteInCurrentTab = await _navigatorKeys[_selectedIndex]
            .currentState
            ?.maybePop();

        // If the current tab's navigation is popped to the root, exit the app
        if (isFirstRouteInCurrentTab == false) {
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          // Title changes based on the root page of the current tab
          title: Text(_tabTitles[_selectedIndex]),
          actions: [
            IconButton(
              onPressed: () {
                showSearch(context: context, delegate: AnimeSearchDelegate());
              },
              icon: const Icon(Icons.search, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
        ),

        body: IndexedStack(
          index: _selectedIndex,
          // Build a Navigator for each screen
          children: List.generate(
            _tabScreens.length,
            (index) => _buildTabNavigator(index),
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            // 4 items total: Index 0, 1 (Center), 2, 3
            BottomNavigationBarItem(
              icon: Icon(Icons.sort_by_alpha),
              label: 'A-Z',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ), // CENTER
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'Genres',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
