import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'config_screen.dart';
import 'messaging_screen.dart';
import 'telemetry_screen.dart';
import 'commands_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 3; // Start with telemetry
  DateTime? _lastTapTime;


  final List<Widget> _screens = [
    const ConfigScreen(),
    const MessagingScreen(),
    const TelemetryScreen(),
    const CommandsScreen(),
  ];

  void _onSatDoubleTap() {
    // The messaging screen is hidden inside this
    // Your function to execute on double tap
    
    // Do something here...
    Navigator.pop(context);
    setState(() {
      _selectedIndex = 1;
    });
    // Call loadMessages after setState so UI has updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex == 1) {
        context.read<AppState>().loadMessages();
      }
    });
  }

  void _handleSatTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(milliseconds: 300)) {
      // First tap or too late after last tap, reset
      _lastTapTime = now;
    } else {
      // Double tap detected
      _lastTapTime = null;
      _onSatDoubleTap();
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize app state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                GestureDetector(
                  onTap: _handleSatTap,
                  child: Icon(
                    Icons.satellite_alt,
                    color: Colors.white,
                    size: 48,
                  ),
                 ),
                  SizedBox(height: 8),
                  Text(
                    'Telemetry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'STP Alpha Tests',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Config'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.message),
            //   title: const Text('Messaging'),
            //   selected: _selectedIndex == 1,
            //   onTap: () {
            //     Navigator.pop(context);
            //     setState(() {
            //       _selectedIndex = 1;
            //     });
            //     // Call loadMessages after setState so UI has updated
            //     WidgetsBinding.instance.addPostFrameCallback((_) {
            //       if (_selectedIndex == 1) {
            //         context.read<AppState>().loadMessages();
            //       }
            //     });
            //   },            
            // ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Telemetry'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('Commands'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return _screens[_selectedIndex];
        },
      ),
    );
  }
} 