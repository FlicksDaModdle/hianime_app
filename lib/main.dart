import 'package:flutter/material.dart';

// Import all required components for the app structure
import 'screens/anime_search.dart';
import 'home_screen_content.dart'; // Tab 0 (Home)
import 'screens/az_list_screen.dart'; // Tab 1 (A-Z)
import 'screens/schedule_screen.dart'; // Tab 2 (Schedule)
import 'package:media_kit/media_kit.dart';

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
      home: const MainNavigator(),
    );
  }
}

// --- MAIN WIDGET TO HANDLE BOTTOM NAVIGATION (3 TABS) ---
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // Start at Index 0 (Home)
  int _selectedIndex = 0;

  // GlobalKey for Home Screen to trigger Scroll Resets
  final GlobalKey<HomeScreenContentState> _homeScreenKey = GlobalKey();

  // Keys for nested navigators (3 tabs)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // AZ List
    GlobalKey<NavigatorState>(), // Schedule
  ];

  // Lists to hold screens and observers
  List<Widget> _tabScreens = [];
  List<NavigatorObserver> _navigatorObservers = [];

  @override
  void initState() {
    super.initState();

    // 1. Initialize Screens
    _tabScreens = [
      HomeScreenContent(key: _homeScreenKey), // Index 0
      const AZListScreen(), // Index 1
      const ScheduleScreen(), // Index 2
    ];

    // 2. Initialize Observers
    // We use a generator to create a unique observer for each tab
    _navigatorObservers = List.generate(
      3,
      (index) => _TabNavigatorObserver(() {
        // Rebuild the main navigator when a sub-navigator pushes/pops
        // This updates the 'Leading' (Back) button state in the AppBar
        if (mounted) {
          // PostFrameCallback prevents "setState during build" errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      }),
    );
  }

  void _onItemTapped(int index) {
    // Logic: If tapping Home (Index 0) while already on Home, reset scrolls
    if (index == 0 && index == _selectedIndex) {
      _homeScreenKey.currentState?.resetScrollPositions();
    }

    // Logic: If tapping any tab that is already selected, pop to its root
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
      observers: [_navigatorObservers[index]], // Attach the specific observer
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => _tabScreens[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current nested navigator can pop (go back)
    // We use a safe check with ?. because keys might not be attached yet in first frame
    final bool canPop =
        _navigatorKeys[_selectedIndex].currentState?.canPop() ?? false;

    return WillPopScope(
      // Handle Android physical back button
      onWillPop: () async {
        final navigatorState = _navigatorKeys[_selectedIndex].currentState;
        if (navigatorState != null && navigatorState.canPop()) {
          navigatorState.pop();
          return false; // Prevent closing app, pop internal route instead
        }
        return true; // Close app if at root of current tab
      },
      child: Scaffold(
        appBar: AppBar(
          // 3. Conditional Leading Button
          // Only show Back Button if we can pop (not at root of tab)
          leading: canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    _navigatorKeys[_selectedIndex].currentState?.pop();
                  },
                )
              : null, // Hides the button completely at root (Home screen)
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
          children: List.generate(
            _tabScreens.length,
            (index) => _buildTabNavigator(index),
          ),
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            // 3 items total
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.sort_by_alpha),
              label: 'A-Z',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// --- Custom Observer to Detect Push/Pop Events ---
class _TabNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigationChanged;
  _TabNavigatorObserver(this.onNavigationChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onNavigationChanged();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onNavigationChanged();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onNavigationChanged();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onNavigationChanged();
}
