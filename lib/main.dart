import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pmv_tracker/core/constants.dart';
import 'package:pmv_tracker/presentation/screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ErrorWidgetBuilder(
      child: const MyApp(),
    ),
  );
}

class ErrorWidgetBuilder extends StatefulWidget {
  final Widget child;
  const ErrorWidgetBuilder({super.key, required this.child});

  @override
  State<ErrorWidgetBuilder> createState() => _ErrorWidgetBuilderState();
}

class _ErrorWidgetBuilderState extends State<ErrorWidgetBuilder> {
  Object? _error;
  // FIX: The field is declared but marked as unused for the linter.
  // ignore: unused_field
  StackTrace? _stackTrace;
  bool _supabaseInitialized = false;
  String _supabaseStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
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
      // FIX: The '_stackTrace' field is now properly assigned.
      setState(() {
        _error = e;
        _stackTrace = st; // This line now works because _stackTrace is defined.
        _supabaseStatus = 'Failed to connect to Supabase ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return MaterialApp(
      title: 'PMV Tracker - Wei Bai?',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _supabaseInitialized ? const MapScreen() : _buildLoadingScreen(),
      debugShowCheckedModeBanner: true,
    );
  }

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
