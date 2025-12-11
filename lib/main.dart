import 'package:flutter/material.dart';

// Import all required components for the app structure
import 'screens/anime_search.dart';
import 'home_screen_content.dart'; // Tab 1 (Center)
import 'screens/az_list_screen.dart'; // Tab 0
import 'screens/genres_screen.dart'; // Tab 3
import 'screens/top_airing_screen.dart'; // Still imported, but not in the tab list
import 'screens/schedule_screen.dart'; // Tab 2

// Placeholder classes that you MUST replace with the actual imports from cupertino_native
// (E.g., import 'package:cupertino_native/cupertino_native.dart';)
class CNTabBar extends StatelessWidget {
  final List<CNTabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const CNTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => const Placeholder();
}

class CNTabBarItem extends StatelessWidget {
  final String label;
  final CNSymbol icon;
  const CNTabBarItem({super.key, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => const Placeholder();
}

class CNSymbol extends StatelessWidget {
  final String symbol;
  const CNSymbol(this.symbol, {super.key});
  @override
  Widget build(BuildContext context) => const Placeholder();
}

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
        // NOTE: bottomNavigationBarTheme is ignored by CNTabBar
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
  // Start the index at 0 (A-Z, to align with the CNTabBar item list order)
  int _selectedIndex = 0;

  // GlobalKey list to manage each tab's navigation state independently (4 tabs total)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // AZ List (0)
    GlobalKey<NavigatorState>(), // Home (1)
    GlobalKey<NavigatorState>(), // Schedule (2)
    GlobalKey<NavigatorState>(), // Genres (3)
  ];

  // List of initial screen widgets in the CNTabBar order: [AZ, HOME, Schedule, Genres]
  final List<Widget> _tabScreens = [
    const AZListScreen(), // Index 0 (A-Z)
    const HomeScreenContent(), // Index 1 (HOME)
    const ScheduleScreen(), // Index 2 (Schedule)
    const GenresScreen(), // Index 3 (Genres)
  ];

  // Map tab index to tab titles for the AppBar
  final List<String> _tabTitles = ['A-Z List', 'HiAnime', 'Schedule', 'Genres'];

  void _onItemTapped(int index) {
    // NOTE: The CNTabBar typically handles the visual switch.
    // We update the index and pop to root if the same tab is tapped.
    if (index == _selectedIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper widget to build the nested Navigator for each tab
  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => _tabScreens[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Defining the CNTabBar items structure here
    final List<CNTabBarItem> cnTabBarItems = const [
      CNTabBarItem(label: 'A-Z', icon: CNSymbol('list.bullet')), // Index 0
      CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')), // Index 1
      CNTabBarItem(label: 'Schedule', icon: CNSymbol('calendar')), // Index 2
      CNTabBarItem(label: 'Genres', icon: CNSymbol('star.fill')), // Index 3
    ];

    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab = await _navigatorKeys[_selectedIndex]
            .currentState
            ?.maybePop();

        if (isFirstRouteInCurrentTab == false) {
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitles[_selectedIndex]),
          // Removing search from AppBar as the new design typically handles it separately
          actions: [],
        ),

        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _tabScreens.length,
            (index) => _buildTabNavigator(index),
          ),
        ),

        // --- NEW: CNTabBar Replacement ---
        bottomNavigationBar: CNTabBar(
          items: cnTabBarItems,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
        // --- END OF CNTabBar Replacement ---
      ),
    );
  }
}
