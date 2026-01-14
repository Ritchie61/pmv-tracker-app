import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pmv_tracker/core/constants.dart';
import 'package:pmv_tracker/presentation/screens/map_screen.dart';

void main() async {
  // Catches errors thrown during the app's startup/initialization
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // This widget catches errors that happen during build and displays them
    ErrorWidgetBuilder(
      child: const MyApp(),
    ),
  );
}

// A widget to gracefully catch and display errors
class ErrorWidgetBuilder extends StatefulWidget {
  final Widget child;
  const ErrorWidgetBuilder({super.key, required this.child});

  @override
  State<ErrorWidgetBuilder> createState() => _ErrorWidgetBuilderState();
}

class _ErrorWidgetBuilderState extends State<ErrorWidgetBuilder> {
  // Object to store any error that occurs
  Object? _error;
  // Stack trace for the error (useful for debugging)
  StackTrace? __stackTrace;
  // Tracks if Supabase initialized successfully
  bool _supabaseInitialized = false;
  String _supabaseStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    // Try to initialize Supabase when the app starts
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _supabaseStatus = 'Connecting to Supabase...');
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      setState(() {
        _supabaseInitialized = true;
        _supabaseStatus = 'Connected to Supabase ✅';
      });
    } catch (e, st) {
      // If Supabase fails, store the error to display it
      setState(() {
        _error = e;
        _stackTrace = st;
        _supabaseStatus = 'Failed to connect to Supabase ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there's an error, show it on a red screen with details
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red[50],
          appBar: AppBar(title: const Text('App Failed to Start'), backgroundColor: Colors.red),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A critical error prevented the app from starting:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black87,
                  child: Text(
                    _error.toString(),
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Supabase Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_supabaseStatus),
                const SizedBox(height: 20),
                const Text('Check these common issues:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('1. Are SUPABASE_URL and SUPABASE_ANON_KEY correct in lib/core/constants.dart?'),
                const Text('2. Is the Supabase project active and the "pmv_reports" table created?'),
                const Text('3. Does your map style URL ("${AppConstants.mapStyleUrl}") load in a browser?'),
              ],
            ),
          ),
        ),
      );
    }

    // If no error yet, show the main app with a debug banner
    return MaterialApp(
      title: 'PMV Tracker - Wei Bai?',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _supabaseInitialized ? const MapScreen() : _buildLoadingScreen(),
      debugShowCheckedModeBanner: true, // Shows "DEBUG" banner
    );
  }

  // Shows a loading screen while Supabase initializes
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading...')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_supabaseStatus),
            const SizedBox(height: 20),
            const Text('If this takes too long, check your internet connection and Supabase credentials.'),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the main app that runs after initialization succeeds
    return MaterialApp(
      title: 'PMV Tracker - Wei Bai?',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
