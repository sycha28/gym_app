import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'workouts_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qzsopmrtczvrgwtvxtqu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6c29wbXJ0Y3p2cmd3dHZ4dHF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1MDA4NDEsImV4cCI6MjEwODA3Njg0MX0.UWKC6KNwc5dgxoCpwHLhnIJ1gv9JGzfh8ixHoav9urw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'SychaFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFE05297),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE05297),
          secondary: Color(0xFFD63384),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFE05297),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: session != null ? const WorkoutsListScreen() : const AuthScreen(),
    );
  }
}
